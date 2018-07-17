#!/bin/bash
cd newProgram/
awk 'FNR==1 {print FILENAME, $0}' *.csv  > names.txt
emacsclient names.txt

# this may help i just need to process every file
sed -i 's/,[[:blank:]]*$//g' *.csv > tmp.tmp # https://unix.stackexchange.com/questions/220576/how-to-remove-last-comma-of-each-line-on-csv-using-linux

IN1=2015,2014,2015,2014,2015,2014,Sem.,Acum.,Acum.,Sem.,Acum.,Acum.,Sem.,Acum.,Acum.

IFS=',' read -ra ADDR <<< "$IN1"

years=()
for i in "${ADDR[@]}"; do
    if [[ $i =~ ^-?[0-9]+$ ]]; then # if it's a numeric value
	years=(${years[@]} $i) # save it
    fi
done

echo ${years[@]} #comprobando

joinedYears=$(printf ",%s" "${years[@]}")
echo $joinedYears

#awk '/2015/ || /2014/{print}'

command="/${years[0]},/ || /${years[1]}/"
l="{print FNR}"
final="$command$l"
echo $final

function gettingYearsLine() {
    #reading files
    for file in newProgram/*;
    do

	if [ ${file: -4} == ".csv" ]; then
	    
	    lineNumber=$(echo $(awk "$final" $file) | cut -d ' ' -f1)
	    if [ -z $lineNumber ]; then
		echo "empty" #file which doesn't have the years
	    else
		echo "$file = $(echo $lineNumber | cut -d' ' -f1)"
	    fi
	fi

	#echo awk 'FNR==$line {print FILENAME, $0}' *.csv  > names.txt
	#echo $file
    done

}

gettingYearsLine

