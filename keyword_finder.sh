#!/bin/bash

# option 1: search all the files in given directory 
# (ex: ./keyword_finder.sh 'C:/Users/User/Desktop/data-science/AI and Deep Learning')

# option 2: user can give some file names (will be build later)

# TODO: colorize terminal outputs

supported_file_formats=("docx" "pdf")

files=()
keywords=()

function build_find_command() {
    local len=${#supported_file_formats[@]}
    command="find . -type f \(";
    for i in "${!supported_file_formats[@]}"; do 
        command="${command} -iname \*.${supported_file_formats[$i]}"
        local result=`expr $len - 1`
        if [[ $i -ne result ]];
        then
            command="${command} -o"
        fi
    done

    command="${command} \) -printf '%f\n'";
}

# read given directory path from user, then navigate to the path
directory_path=$1
cd "$directory_path"

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


read -p "Enter your keywords and separate them with comma: " str_keywords
echo "Keywords [$str_keywords]"
echo $'\n' 

IFS=',' read -r -a keywords_arr <<< "$str_keywords"

for i in "${!keywords_arr[@]}"; do 
    keyword="${keywords_arr[$i]}"
    trimmed_keyword="${keyword//' '/''}"
    keywords+=($trimmed_keyword)
    # echo "$trimmed_keyword - ${#trimmed_keyword}"
done

# echo "Keywords"

# echo "${keywords[3]} - ${#keywords[3]}"

for key in "${keywords[@]}"; do 
    echo "Keyword '$key' found in the following files:"
    for file in "${files[@]}"; do
        echo "=> $file"
    done
    echo $'\n'
done