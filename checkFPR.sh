# /bin/env/bash
# FPR Challenge
# FPR File Checker
# Code by Ralph
echo ""
echo "================================================================"
echo "Welcome to my FPR File checker!"
echo "This will check for your FPR if it has non-ascii characters and where"
echo "================================================================"
echo ""
file=""
echo -e "Enter the fpr filename from the list which you wish to check: > "
echo ""
ls -1
echo ""
read file
cropped=`echo $file | sed -e 's/^*//g' -e 's/\.fpr$//g'`
echo "MY CROPPED FILE: $cropped"
new_name="$cropped.zip"
cp "$file" "$new_name"
unzip "$new_name"
curr_dir=`pwd`
for files in *; do
	# echo "filename is: $files"
	pwd
	fpr=".fpr"
	zip=".zip"
	if [[ $files =~ $fpr ]]
	then 
		continue
	elif [[ $files =~ $zip ]]
	then
		continue
	elif [[ -d "$files"  ]]
	then 
		cd $files
		pwd
		echo "Digging into $files directory..."
		for entries in *; do
			echo "File chosen $entries is existing in this directory!"
			echo "Detecting non-ascii characters in the file..."
			# using perl code since grep -P fails in mac unless I install PCRegrep for that command
			perl -ne 'print "$. $_" if m/[\x80-\xFF]/' $entries
			echo "Done."
			echo ""
		done
		echo "Going out of FOD directory..."
		cd $curr_dir
	else
		echo "File chosen $files is existing in this directory!"
		echo "Detecting non-ascii characters in the file..."
		# using perl code since grep -P fails in mac unless I install PCRegrep for that command
		perl -ne 'print "$. $_" if m/[\x80-\xFF]/' $files
		echo "Done."
		echo ""
	fi
done
