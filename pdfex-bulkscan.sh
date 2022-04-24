#/bin/bash
#-- This script will scan .pdf files in the working directory and create a report of the results.
#-- Files are processed in parallel, with a mazimum of 5 scans running at any time.

#-- If user calls script incorrectly, let them know how to call it and exit
if [ $# -ne 0 ];
then
  echo "[:] This script requires php and phpexaminer to function correctly."
  echo "[:] Run this script while working in the directory containing the .pdfs you would like to scan using pdfexaminer."
  echo ""
  echo "[:] Usage: $0";
  echo ""
  exit -1
fi

#-- Define variable $fcount as 0
icount=0

#-- Start for loop and assign the variable $f as each .pdf file in the current working directory
for i in *.pdf;
do
  #-- Increase the variable $fcount by 1 (this will tell the user how many .pdf files there are in the directory)
  icount=$(( icount+1 ))
done

#-- Let user know how many .pdfs are found
echo "[:] Total *.pdf files detected: $icount"
#-- Ask user if they are ready to begin
echo "[:] Start pdfexaminer scan of *.pdf files? (y/n) "
read -p "" REPLY

#-- Rename all files, replace spaces with - to prevent errors while processing
for i in *\ *;
do
  mv "$i" "${i// /-}"
done

#-- Define the function "max" to limit the number of concurrent conversion jobs to 5
function max {
   while [ `jobs | wc -l` -ge 5 ]
   do
      sleep 2
   done
}

#-- Start for loop and assign the variable $i as each .pdf file (exclusively by extension, and case insensitive)
for i in $(ls . | grep -i ".*\.pdf$");
do
  #-- Assign the variable $iout as the basename of the variable $i (.pdf exclusive)
  iout=$(basename "$i" .pdf)
  #-- Let the user know when a file scan starts, print the file name
  echo "[:] scanning $i"
  #-- start the function "max", and pdfexaminer, output to a text file for each file scanned
  max; php ~/pdfexaminer/pdfex.php $i >> $iout.pdfex.scan.txt &
done

#-- Wait for the remaining file scans to complete before proceeding
wait

#-- Start for loop and assign $f to each .txt file in the working directory 
for f in *.txt;
do
  #-- Assign the variable $fbase as the basename of the variable $f (.pdfex.scan.txt exclusive)
  fbase=$(basename $f .pdfex.scan.txt)
  #-- Echo that was scanned in to a combined .txt file 
  echo "pdfexaminer: File: "$fbase.pdf >> 000-pdfexaminer-scan-results.txt
  #-- Read the contents of the current file using cat and send specific information lines to the combined .txt file
  cat $f | grep -e hits -e exploit -e is_malware -e severity >> 000-pdfexaminer-scan-results.txt
done

#-- complete
echo "[:] All tasks completed."
exit 1