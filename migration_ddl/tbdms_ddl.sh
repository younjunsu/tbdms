################################
# tbexport generator tool
################################
# tbexport script=y file
file_path_export_script=""

# output file directory
file_path_generator=""
mkdir -p "$file_path_generator"

# exporting type file array
cat "\--" $file_path_export_script |grep "exporting"|grep "\--   e" |sed 's/--//g' |sed 's/"//g' |sed 's/  //g' |awk '{print "export_type["NR"]=\""$0"\""}' > tbdms_type.env
cat  $file_path_export_script |grep -n "\--   exporting" |sed 's/:/ /g' |awk '{print "export_type_gap["NR"]=\""$1"\""}' > tbdms_type_gap.env

# apply env
. tbdms_type.env
. tbdms_type_gap.env

# env file remove
rm -f tbdms_type.env
rm -f tbdms_type_gap.env

# generator loop
export_type_count=`grep "\--" $file_path_export_script  |grep "exporting" |grep "\--   e" |wc -l`
for((i=1;i<=$export_type_count;i++))
do

	ii=`echo $i + 1 |bc`

	# try: generator result file init
	file_name_generator=`echo "${export_type[$i]}" |sed 's/ /_/g' |sed 's/_e/e/g'`
	echo "-- tbdms generator: ${export_type[$i]}" > $file_path_generator/$file_name_generator
	
	# try: generator array	
	export_type_after_name=`echo ${export_type[$i]}`
	export_type_before_name=`echo ${export_type[$ii]}`
	line_gap=`echo ${export_type_gap[ii]} - ${export_type_gap[i]} |bc`
	
	# try: schema:"%s"
	file_check_generator_after=`echo "$export_type_after_name" |grep "schema"`
	file_check_generator_before=`echo "$export_type_before_name" |grep "schema"`

	if [ "$i" == "$export_type_count" ]
	then
		line_end=`cat "$file_path_export_script" |grep -n "\-- Export" |sed 's/:/ /' |awk '{print $1}' |tail -n 1  `
		line_end_num=`echo $line_end - ${export_type_gap[i]} |bc`
		cat "$file_path_export_script" |grep -A$line_end_num "$export_type_after_name"  >> $file_path_generator/$file_name_generator
	elif [ -z "$file_check_generator_after" ]
	then
		export_type_before_name=`echo ${export_type[$ii]}`

                if [ -n "$file_check_generator_before" ]
                then
                        export_type_before_name=`echo ${export_type[$ii]} |sed 's/:/:\"/g' |awk '{print $0"\""}'`
                fi

		cat "$file_path_export_script" |grep -A$line_gap "$export_type_after_name" |grep -B$line_gap "$export_type_before_name" >> $file_path_generator/$file_name_generator
	elif [ -n "$file_check_generator_after" ]
	then
		export_type_after_name=`echo ${export_type[$i]} |sed 's/:/:\"/g' |awk '{print $0"\""}'`

                if [ -n "$file_check_generator_before" ]
                then
			export_type_before_name=`echo ${export_type[$ii]} |sed 's/:/:\"/g' |awk '{print $0"\""}'`
                fi

		cat "$file_path_export_script" |grep -A$line_gap "$export_type_after_name" |grep -B$line_gap "$export_type_before_name" >> $file_path_generator/$file_name_generator

	else
		exit 1 
	fi

	# line remove
	sed '/--   exporting/d' -i $file_path_generator/$file_name_generator
	sed '/-- Packing the file.../d' -i $file_path_generator/$file_name_generator
	sed '/-- Export/d' -i $file_path_generator/$file_name_generator

done
