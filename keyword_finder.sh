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
    file_path="$directory_path/$file"
    sh "$DOCX_TO_TXT_CONVERTER_PATH" "$file_path"
    txt_file="${file//'.docx'/'.txt'}"
}

function convert_pdf_to_txt() {
    file_path="$directory_path/$1"

    txt_file="${1//'.pdf'/'.txt'}"
    txt_file_path="$directory_path/$txt_file"
    export_path="$txt_exports_dir_path/$txt_file"

    cd "$SCRIPT_DIR/pdf2text"
    ./pdf2text $file_path > $txt_file_path
}

function convert_to_txt() {
    OIFS="$IFS"
    IFS=$'\n'
    docx_regex='\.docx$'
    pdf_regex='\.pdf$'

    local file=$1
    if [[ $file =~ $docx_regex ]]; then
        convert_docx_to_txt $file
    elif [[ $file =~ $pdf_regex ]]; then
        convert_pdf_to_txt $file
    fi
        
    txt_file_path="$directory_path/$txt_file"
    export_path="$txt_exports_dir_path/$txt_file"
    
    if [[ -d $txt_exports_dir_path ]]; then
        eval $(mv "$txt_file_path" "$export_path")
    fi

    IFS="$OIFS"
}

function convert() {
    OIFS="$IFS"
    IFS=$'\n'

    echo "Conversion started..."
    local converted_files=0
    local skipped_files=0

    for i in "${!files[@]}"; do
        file="${files[$i]}"
        file_path="$directory_path/$file"

        txt_file=${file//'.docx'/'.txt'}
        exported_file_path="$txt_exports_dir_path/$txt_file"
        
        if [[ -e $exported_file_path ]]; then
            read -p $YELLOW"$file already converted, do you want to override: Type y if you want to override, otherwise press enter:$NORMAL $GREEN" need_override

            if [[ $need_override == 'y' ]]; then
                convert_to_txt $file
                converted_files=`expr $converted_files + 1`
            else
                skipped_files=`expr $skipped_files + 1`
            fi
        else
            convert_to_txt $file
        fi

        if [[ `expr $converted_files % 5` -eq 0 && $converted_files -ne 0 ]]; then
            echo $YELLOW"$converted_files files already converted...$NORMAL";     
        fi

        txt_files+=($exported_file_path)
    done
    
    echo $NORMAL $YELLOW"Total: $skipped_files files skipped$NORMAL"
    echo $GREEN"Total: $converted_files files converted$NORMAL"
    IFS="$OIFS"
}

convert

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

# 2. Add progress, to show the user, there are 30 files, currently converting 7/30, and increase it after every conversion, show outputs with color
# 3. Remove output of the doc2txt.sh
# 4, add resource of pdf2text converter to README file
