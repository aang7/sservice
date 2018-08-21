#!/bin/bash
. ./utils.lib

FILE_EXTENSION=".csv"
DIR="newProgram"
FILESOFINTEREST=() #EXP
declare -A ANOMALY_FILES
EPIDEMIC_NAMES_FILE="$(pwd)/epidemic_names.txt"
EPIDEMIC_EXCEPTIONS_FILE="epidemic_exceptions.txt"
ANOMALY_FILES_FILE="anomalies.txt"
MINCHARS_IN_EPIDEMIC_NAME=22

:'
  This function tries to clean the year header of the csv files.
  args: $1 -> Directory
  	$2 -> FileExtension
'
function cleanYearHeader() {
    echo "$# Parameters"
    DIRECTORY=$1
    echo $DIRECTORY
    F_EXTENSION=$2
    echo "FEXTENSION: ${#F_EXTENSION}"
    pattern="/2015/ || /2014/ || /2016/ || /2013/ {print FNR}" # in general each csv has only two different years
     #read the files of directory
     for file in $DIRECTORY/*;
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
		 FILESOFINTEREST=( "${FILESOFINTEREST[@]}" $file ) # EXP
		 #replace line by the splitted with the commas
		 joinedYears=$(printf ",%s" "${splitted[@]}")
		 sed -i "${lineNumber}s/.*/${joinedYears}/" $file
		 #printf "%s \t-> " "$file";
		 #printf "%s " "${splitted[@]}";
		 #echo ""
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

function SaveAnomalyFiles() {
    
    # add ANOMALY_FILES to a file
    for value in "${ANOMALY_FILES[@]}";
    do
	# adding epidemic names to a file
	AddLineToFile "$value" $ANOMALY_FILES_FILE
    done	
}

 
# expects to receive an array with the files of interest
# it uses a two global variables "FILESOFINTEREST" "ANOMALY_FILES"
function GetEpidemicNames() {

    for file in "${FILESOFINTEREST[@]}"; do

	DeleteCommas $file # pre process

	firstLine=$(sed '1q;d' $file) # get first line
	b=','
	
	SplitLineByDelimeter firstLine  b firstLine
	
	#AddLineToFile 
	echo "size: ${#firstLine}  file: $file"
	j=0
	
        # if the number of columns on the data is equal to the number of names_headers, add lineToFile
	dataFirstLine=$(awk "/Aguascalientes/ {print}" $file)
	SplitLineByDelimeter dataFirstLine b dataFirstLine
	
	if [ $((${#dataFirstLine[@]} - 1)) -eq $(((${#firstLine[@]} - 1) * 4)) ]; then
	    printf ""
	else
	    # if the epidemic name header contains one of the exceptions then you won't want to treat them as anomaly
	    isexception=false
	    for ep_pattern in "${firstLine[@]:1}"; do
		if [ ${#ep_pattern} -ge $MINCHARS_IN_EPIDEMIC_NAME ]; then
		    if grep -Fq "$ep_pattern" $EPIDEMIC_EXCEPTIONS_FILE ;
		    then
			# code if found
			mgrep=$(grep -Fon "$ep_pattern" $EPIDEMIC_EXCEPTIONS_FILE)
			echo "MY MGREP RESULT: $mgrep"
			b=':'
			SplitLineByDelimeter mgrep b ml # the idea is to check if the lenght difference of the names is not too high (TODO)
			isexception=true
			echo "--> $ep_pattern is exception "
		    else
			# code if not found
	    		echo ";"
		    fi
		fi
	    done

	    if ! $isexception ; then
		# if it's not an exception file then most probably it's an anomaly file
		echo "TTT"
		ANOMALY_FILES[$((k++))]=$file
	    fi
	fi
	
	for i in "${firstLine[@]:1}"; do # only matters from the 1st index to the end
	    echo "$j : $i : len: ${#i}"
	    ((j++))
	    if [ ${#i} -ge $MINCHARS_IN_EPIDEMIC_NAME ]; then # if the name is greater than22 chars add it to the file

		name_chars=$(echo "$i" | sed 's/\CIE.*//' | sed 's/[^0-9a-zA-Z ]*//g')
		# adding epidemic names to a file
		if ! grep -Fq "$name_chars" $EPIDEMIC_NAMES_FILE ; then
		    AddLineToFile "$i" $EPIDEMIC_NAMES_FILE
		fi
	    fi
	done
	echo ""; echo ""; 
	     	
    done

    if [ ${#ANOMALY_FILES} > 0 ]; 
    then
	echo "Anomaly Files";
	Printaarr ANOMALY_FILES
	SaveAnomalyFiles
    fi
    
}



cleanYearHeader "$DIR" "$FILE_EXTENSION"
echo ""; echo "Files of interest";
GetEpidemicNames

