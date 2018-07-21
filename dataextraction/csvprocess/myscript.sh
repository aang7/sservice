#!/bin/bash
. ./utils.lib

FILE_EXTENSION=".csv"
DIR="newProgram"
FILESOFINTEREST=() #EXP
EPIDEMIC_NAMES_FILE="$DIR/epidemic_names.txt"

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
    pattern="/2015/ || /2014/ {print FNR}" # in general each csv has only two different years
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

# expects to receive an array with the files of interest
# it uses a global variable
function GetEpidemicNames() {

    #SplitLineByDelimeter
    
    for file in "${FILESOFINTEREST[@]}"; do

	DeleteCommas $file # pre process
       	# get first line
	firstLine=$(sed '1q;d' $file)
	b=','
	# delete commas between double quotes
#	firstLine=$( echo "$firstLine" | sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1 /;ta')

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
	    echo "Anomaly in col headers and data numbers $file" 
	fi
	
	for i in "${firstLine[@]:1}"; do # only matters from the 1st index to the end
	    echo "$j : $i"
	    ((j++))
	    AddLineToFile "$i" $EPIDEMIC_NAMES_FILE
	done
	echo ""; echo "";

     	
    done
    
}


cleanYearHeader "$DIR" "$FILE_EXTENSION"
echo ""; echo "Files of interest";
GetEpidemicNames


# echo '"ENTIDAD FEDERATIVA","§Tétanos Neonatal CIE-10a REV. A33","§Tétanos CIE-10a REV. A34, A35", '|
#   sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1 /;ta'
#tengo que checar si realmente hace match con la cantidad de datos, por lo general por cada titulo o nombre de enfermedad hay 4 columnas en los datos s, ac h, ac m, acum(pastYear)
