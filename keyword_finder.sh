#!/bin/bash

# COLORS
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)


SUPPORTED_FILE_FORMATS=("docx" "pdf")

files=()
keywords=()
txt_files=()

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCX_TO_TXT_CONVERTER_PATH="$SCRIPT_DIR/docx2txt-1.4/docx2txt.sh"

function build_find_command() {
    local len=${#SUPPORTED_FILE_FORMATS[@]}
    command="find . -type f \(";
    for i in "${!SUPPORTED_FILE_FORMATS[@]}"; do 
        command="${command} -iname \*.${SUPPORTED_FILE_FORMATS[$i]}"
        local result=`expr $len - 1`
        if [[ $i -ne result ]];
        then
            command="${command} -o"
        fi
    done

    command="${command} \) -printf '%f\n'";
}

directory_path=$1
cd "$directory_path"

txt_exports_dir_path="$directory_path/__txt_exports__"
if [[ ! -d $txt_exports_dir_path ]]; then
    eval $(mkdir '__txt_exports__')        
fi

build_find_command

function collect_given_directory_files() {    
    OIFS="$IFS"
    IFS=$'\n'
    for file in `eval $command`
    do
        files+=($file)
    done
    IFS="$OIFS"
}

collect_given_directory_files

function convert_docx_to_txt() {
    OIFS="$IFS"
    IFS=$'\n'
    docx_regex='\.docx$'
    pdf_regex='\.pdf$'
    for file in "${files[@]}"; do
        file_path="$directory_path/$file"
        if [[ $file =~ $docx_regex ]]; then
            sh "$DOCX_TO_TXT_CONVERTER_PATH" "$file_path"
            txt_file="${file//'.docx'/'.txt'}"
            txt_file_path="$directory_path/$txt_file"
            export_path="$txt_exports_dir_path/$txt_file"
            
            if [[ -d $txt_exports_dir_path ]]; then
                eval $(mv "$txt_file_path" "$export_path")
            fi
            txt_files+=($export_path)
        elif [[ $file =~ $pdf_regex ]]; then
            txt_file="${file//'.pdf'/'.txt'}"
            txt_file_path="$directory_path/$txt_file"
            export_path="$txt_exports_dir_path/$txt_file"
            
            cd "$SCRIPT_DIR/pdf2text"
            ./pdf2text $file_path > $txt_file_path

            if [[ -d $txt_exports_dir_path ]]; then
                eval $(mv "$txt_file_path" "$export_path")
            fi
            txt_files+=($export_path)
        fi

    done
    IFS="$OIFS"
}

convert_docx_to_txt


echo "$GREEN***Exported Files***$NORMAL"
for txt in "${txt_files[@]}"; do
    echo "  $CYAN==>$NORMAL $txt"
done

echo $'\n***************************************************************\n'

read -p "Enter your keywords and separate them with comma: $YELLOW" str_keywords

IFS=',' read -r -a keywords_arr <<< "$str_keywords"

for i in "${!keywords_arr[@]}"; do 
    keyword="${keywords_arr[$i]}"
    trimmed_keyword="${keyword//' '/''}"
    keywords+=($trimmed_keyword)
done

for key in "${keywords[@]}"; do 
    echo $NORMAL"Keyword $YELLOW'$key'$NORMAL found in the following files:"
    for file in "${txt_files[@]}"; do
        if grep -w -q $key "$file"; then
            echo "  $CYAN==>$NORMAL $file"
        fi
    done
    echo $'\n\n'
done

# TODO List
# 1. Search For the pdf files, if there are already has pdf file with the same name, then don't generate simply 
#    use it (same situation will be applied for docx files)

# 2. Don't show the output of the pdf, just generate text file and store it __txt_exports__ folder
# 3. Add progress, to show the user, there are 30 files, currently converting 7/30, and increase it after every conversion, show outputs with color 