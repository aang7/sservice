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
EXTRACTION_FOLDER="Extracted"

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

	#TODO: check if the epidemics names are on the 1st line, because some files does not have it in the first line.... WARNING!
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
	    # WARNING! TODO: we have to delete the ENTIDAD FEDERATIVA IF IT exists because some csv files
	    # do not have it. So the next Expression ${firstLine[@]:1} IS WRONG.
	    # TIP: A solution to this problem could be erase all the blank lines in all the files
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

	#WARNING: See the warning above in line 102!!
	for i in "${firstLine[@]:1}"; do # only matters from the 1st index to the end 
	    echo "$j : $i : len: ${#i}"
	    ((j++))
	    if [ ${#i} -ge $MINCHARS_IN_EPIDEMIC_NAME ]; then # if the name is greater than22 chars add it to the file

		name_chars=$(echo "$i" | sed 's/\CIE.*//' | sed 's/[^0-9a-zA-Z ]*//g') # get the name only
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

# function extractData() {

    

# }

# this function has to fill all the names
function getDataOfEpidemic() {
    ep_name="Varicela"
    target_files=($(grep -Hnr $ep_name --include \*$FILE_EXTENSION))

    (grep -Hnr $ep_name --include \*$FILE_EXTENSION) | while read -r line ; do
	# process files
	echo "Original: $line"

	# line[0]->file | line[1]->epnames_header line number | line[2]->epnames line
	b=':'
	SplitLineByDelimeter line b line 
	echo "Modified: " #${line[@]}
	printf '% s\n' "${line[@]}"
	mfile=${line[0]}; mep_names_line=${line[1]}; mep_names_header=${line[2]};
	echo "mfile: $mfile ++ nh: $mep_names_header ++ nl: $mep_names_line"
	ep_names="${line[2]}"; 	b=',';
	SplitLineByDelimeter ep_names b ep_names

	# TODO: match insensitive word (ENTIDAD)
	if [[ "$ep_names[0]" == *"ENTIDAD"* ]]; then
	    # it contains "entidad federativa" so delete it from the array
	    unset ep_names[0]
	fi

	# check the index.
	# The index that we will work on will start from zero
	# and will not consider items that are not epidemic names
	# so the algorithm is the next:
	# get index
	# get the beginning of data rows (starting from Aguascaliantes)
	# get the data
	
	#WARNING: we have to check also if the other ep_names are not part of epidemic_exceptions [TODO]

	# In the next loop I check if we have some epidemic exceptions
	# This is because we need to count the cols of data to correctly retrieve it.
	j=0
	precedent_ep_execeptions=0 # CLAVE
	for i in "${ep_names[@]}"; do
	    # create variable to count the precedent ep_exceptions if there was

	    name_chars=$(echo "$i" | sed 's/\CIE.*//' | sed 's/[^0-9a-zA-Z ]*//g')
	    echo "Ep Name: $name_chars"
	    if grep -Fq "$name_chars" $EPIDEMIC_EXCEPTIONS_FILE ; then
		((precedent_ep_execeptions++))
	    fi

	    if [[ $i = *$ep_name* ]]; then
	    	echo "It's there! in index: $j -> PRECEDENT COUNT: $precedent_ep_execeptions"
		break;
	    fi
	    ((j++))
	done

	#now i have to extract the data
	data_beginning_line=$(awk "/Aguascalientes/ {print NR}" $mfile)
	data_end_line=$(($data_beginning_line + 31))
	echo "asdfasdfa: $data_end_line"
	ep_index=$j
	h=2
	g=5
	#Loop trough the file data and retrieve it.
	for k in $(seq $data_beginning_line 1 $data_end_line); do # I dont know why does not works with {1..20}
	    line=$(sed -ne "${k}p" $mfile)
	    # now i will create a file called test_$ep_name and i will put there the data
	    # i need to consider how i will handle this... yet i'm not sure...
	    delimeter=','
	    SplitLineByDelimeter line delimeter line
	    range1=$(((ep_index*4) + 1)) # [TODO]
	    # if is exception then only 3 [TODO]
	    range2=$((range1+3))
	    echo "From: $range1 To: $range2"
	    echo "${line[@]:$range1:$range2}"
	done
	
    done
    # for file in "$target_files[]"
    mkdir -p $EXTRACTION_FOLDER # create folder if does not exists
    
}




# cleanYearHeader "$DIR" "$FILE_EXTENSION"
# echo ""; echo "Files of interest";
# GetEpidemicNames
getDataOfEpidemic
