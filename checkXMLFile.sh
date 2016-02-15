# /bin/env/bash
# FPR Challenge
# XML File Checker
echo ""
echo "Welcome to my XML File checker!"
echo "This will check for your XML if it has non-ascii characters and where"
echo ""
file=""
echo -e "Enter filename from the list which you wish to check: > "
echo `ls -a`
read file
echo "File chosen: $file"
if [[ -e "$file" ]]
then 
	echo "File chosen is existing in this directory!"
	echo "Detecting non-ascii characters in the file..."
	# using perl code since grep -P fails in mac unless I install PCRegrep for that command
	perl -ne 'print "$. $_" if m/[\x80-\xFF]/' $file
	echo "Done."
else
	echo "ERROR: File NOT FOUND!"
fi

# echo "$file"
