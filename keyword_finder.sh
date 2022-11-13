#!/bin/bash

# option 1: search all the files in given directory
# option 2: user can give some file names

supported_file_formats=("docx" "pdf")

files=()

function build_find_command() {
    local len=${#supported_file_formats[@]}
    command="find ./ -type f \(";
    for i in "${!supported_file_formats[@]}"; do 
        local result=`expr $len - 1`
        if [[ $i -ne result ]];
        then
            command="${command} -iname \*.${supported_file_formats[$i]} -o"
        else
            command="${command} -iname \*.${supported_file_formats[$i]}"
        fi
    done

    command="${command} \) -printf '%f\n'";
}

build_find_command

function collect_current_directory_files() {    
    OIFS="$IFS"
    IFS=$'\n'
    for file in `eval $command`
    do
        files+=($file)
    done
    IFS="$OIFS"
}

collect_current_directory_files

for i in "${files[@]}"
do
	echo $i
done