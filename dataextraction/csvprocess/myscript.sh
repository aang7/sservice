#!/bin/bash
. ./utils.lib

FILE_EXTENSION=".csv"
DIR="newProgram/*"


:'
  This function tries to clean the year header of the csv files.
  args: $1 -> Directory
  	$2 -> FileExtension
'
function cleanYearHeader() {
    echo "$# Parameters"
    DIRECTORY=$1
    F_EXTENSION=$2
    echo "FEXTENSION: ${#F_EXTENSION}"
    pattern="/2015/ || /2014/ {print FNR}" # in general each csv has only two different years
     #read the files of directory
     for file in $DIRECTORY;
     do
	 
	 if [[ ${file: -${#F_EXTENSION}} == $F_EXTENSION && $(wc -l < $file) -ge 32 ]];
	 then
	     lineNumber=$(echo $(awk "$pattern" $file) | cut -d ' ' -f1)
	     if [ -z $lineNumber ]; then
	         filesWithoutYearHeader=( ${filesWithoutYearHeader[@]} $file) # file which doesn't have the years
	     else
		 yearline=$(sed "${lineNumber}q;d" $file); delimiter=',';
		 SplitLineByDelimeter yearline delimiter splitted
		 GetNumericalValues splitted
		 #replace line by the splitted with the commas
		 joinedYears=$(printf ",%s" "${splitted[@]}")
		 sed -i "${lineNumber}s/.*/${joinedYears}/" $file
		 printf "%s \t-> " "$file";
		 printf "%s " "${splitted[@]}";
		 echo ""
	     fi
	 else
	     if [ ${file: -4} == ".csv" ]; then
		 filesWithoutYearHeader=( ${filesWithoutYearHeader[@]} $file) # file which doesn't have the years
	     fi
	 fi
     done
     

     #check the length of the filesWithoutYearHeader
     if [ ${#filesWithoutYearHeader} > 0 ]; then
	 printf "\nFile(s) that doesn't meet the requirements: ${#filesWithoutYearHeader[@]}"
	 printf '\n%s' "${filesWithoutYearHeader[@]}"

     fi

 }


cleanYearHeader "$DIR" "$FILE_EXTENSION"

