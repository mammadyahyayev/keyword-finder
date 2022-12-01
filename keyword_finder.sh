#!/bin/bash

# COLORS
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
PURPLE=$(tput setaf 5)
NORMAL=$(tput sgr0)

# Version, KF stands for KeywordFinder
KF_VERSION='v1.1.0'

# Docs
DOC_URL='https://github.com/MamedYahyayev/keyword-finder'

SUPPORTED_FILE_FORMATS=("docx" "pdf")

files=()
keywords=()
txt_files=()
temp_arr=()
declare -A file_map

filename=""
file_extension=""
file_dir_path=""

# Variables
skip_conversion=false
override_all=false

# Helper Log Functions
function error() {
    echo $RED"Error: $1"$NORMAL
}

function success() {
    echo $GREEN"$1"$NORMAL
}

function info() {
    echo $CYAN"$1"$NORMAL
}

function warning() {
    echo $YELLOW"$1"$NORMAL
}

function debug() {
    echo $PURPLE"==> $1"$NORMAL
}

# Helper str functions
function is_str_empty() {
    if [[ -z "${1// /}" ]]; then
        true
    else
        false
    fi
}

function is_arr_empty() {
    local arr=("$@")
    local arr_len="${#arr[@]}"
    # debug "Length: $arr_len"
    # debug "Arr: $arr"
    if [[ $arr_len -eq 0 ]]; then
        true
    else
        false
    fi
}

function print_newline() {
    count=$1
    i=0
    while [[ i -lt $count ]]; do
        echo $'\n'
        i=$(( $i + 1 ))
    done
}

function is_dir_exist() {
    if [[ -d "$1" ]];
    then
        true
    else
        false
    fi
}

function get_filename() {
    local file=$1
    filename=${file##*/}
}

function get_file_extension() {
    local file=$1
    get_filename "$file"
    file_extension="${filename##*.}"
}

function get_file_path() {
    local file=$1
    file_dir_path="${file%/*}"
}

function print_arr() {
    for item in "$@"; do
        debug "$item"
    done
}

function print_dictionary() {
    for file in "${!file_map[@]}"; do
        if grep -w -q -i $key "${file}"; then
            echo "  $CYAN==>$NORMAL ${file_map[${file}]}"
        fi
    done
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOCX_TO_TXT_CONVERTER_PATH="$SCRIPT_DIR/docx2txt-1.4/docx2txt.sh" # TODO: rename folder

function build_find_command() {
    cd "$directory_path"
    local formats=("$@")
    local len=${#formats[@]}
    command="find . -type f \("
    for i in "${!formats[@]}"; do
        command="${command} -iname \*.${formats[$i]}"
        local result=$(expr $len - 1)
        if [[ $i -ne result ]]; then
            command="${command} -o"
        fi
    done

    command="${command} \) -printf '%f\n'"
}

function collect_directory_files() {
    temp_arr=()
    local formats=("$@")
    build_find_command "${formats[@]}"

    OIFS="$IFS"
    IFS=$'\n'
    for file in $(eval $command); do
        temp_arr+=("$file")
    done
    IFS="$OIFS"
}

function collect_original_files() {
    collect_directory_files "${SUPPORTED_FILE_FORMATS[@]}"
    for file in "${temp_arr[@]}"; do
        local file_path="$directory_path/$file" 
        # debug "Original file: $file"
        # debug "Original file path: $file_path"
        files+=("$file_path")
    done
    temp_arr=()
}

function collect_exported_files() {
    if ! is_dir_exist "__txt_exports__"; then
        error "exports folder doesn't exist"
    fi

    local formats=("txt")
    collect_directory_files "${formats[@]}"

    for txt_file in "${temp_arr[@]}"; do
        local txt_file_path="$directory_path/__txt_exports__/$txt_file"
        # debug "Txt file: $txt_file"
        # debug "Txt file path: $txt_file_path"
        txt_files+=("$txt_file_path")
    done

    temp_arr=()
}

function collect_matched_files() {
    # debug "TXT FILES"
    # print_arr "${txt_files[@]}"

    # debug "FILES"
    # print_arr "${files[@]}"

    for txt_file in "${txt_files[@]}"; do
        local txt_file_name=$(basename "${txt_file%.*}")

        for file in "${files[@]}"; do
            local file_name=$(basename "${file%.*}")

            if [[ "$txt_file_name" = "$file_name" ]]; then
                # debug "$txt_file_name <===> $file_name"
                file_map[$txt_file]=$file
            fi
        done
    done 

    # for file in "${!file_map[@]}"; do
    #     echo "  $CYAN==>$NORMAL Key=$file, Value=${file_map[${file}]}"
    # done
}

function show_collected_files() {
    success "Collected files"
    for file in "${files[@]}"; do
        success "==> $file"
    done
    print_newline 1
}

function search_keywords() {
    read -p "Enter your keywords and separate them with comma: $YELLOW" str_keywords
    IFS=',' read -r -a keywords_arr <<<"$str_keywords"

    for i in "${!keywords_arr[@]}"; do
        keyword="${keywords_arr[$i]}"
        trimmed_keyword="${keyword//' '/''}"
        keywords+=($trimmed_keyword)
    done

    for key in "${keywords[@]}"; do
        echo $NORMAL"Keyword $YELLOW'$key'$NORMAL found in the following files:"
        for file in "${!file_map[@]}"; do
            debug "$file"
            if grep -w -q -i $key "${file}"; then
                echo "  $CYAN==>$NORMAL ${file_map[${file}]}"
            fi
        done
        print_newline 1
    done
}

function export_file() {
    local file="$1"
    local docx_regex='\.docx$'
    local pdf_regex='\.pdf$'
    local txt_file="$file"

    get_file_path "$file" # assign path to => file_dir_path variable
    local txt_files_export_path="$file_dir_path/__txt_exports__"

    if ! is_dir_exist "$txt_files_export_path"; then
        mkdir "$txt_files_export_path"
    fi

    if [[ $file =~ $docx_regex ]]; then
        sh "$DOCX_TO_TXT_CONVERTER_PATH" "$file" >/dev/null
        txt_file=${file//'.docx'/'.txt'}
    elif [[ $file =~ $pdf_regex ]]; then
        cd "$SCRIPT_DIR/pdf2text"
        txt_file=${file//'.pdf'/'.txt'}
        ./pdf2text "$file" > "$txt_file"
    fi

    mv "$txt_file" "$txt_files_export_path"

    local filename=${txt_file##*/}
    file_map+=(["$txt_files_export_path/$filename"]=$file)
    # debug "$txt_files_export_path/$filename <==> $file"
}

function export_original_files() {
    info "Files are preparing to convert..."
    for file in "${files[@]}"; do
        export_file "$file"    
    done
}

function is_supported_file() {
    local file=$1
    local is_supported=false
    get_file_extension $file # it get file_extension from the path and assign it to 'file_extension' variable
    for formats in "${SUPPORTED_FILE_FORMATS[@]}"; do
        if [[ "$file_extension" == "$formats" ]]; then
            is_supported=true
            break
        fi
    done

    if $is_supported; then
        true
    else
        false
    fi
}

function print_supported_file_formats() {
    local message=$GREEN"${SUPPORTED_FILE_FORMATS[@]}"$NORMAL
    info "Please use one of these file formats: $message"
}

function search_keywords_on_file() {
    read -p "Enter your keywords and separate them with comma: $YELLOW" str_keywords
    IFS=',' read -r -a keywords_arr <<<"$str_keywords"

    for i in "${!keywords_arr[@]}"; do
        keyword="${keywords_arr[$i]}"
        trimmed_keyword="${keyword//' '/''}"
        keywords+=($trimmed_keyword)
    done

    for file in "${!file_map[@]}"; do
        echo $NORMAL"File:$YELLOW'${file_map[${file}]}'$NORMAL has following keywords:"
        for key in "${keywords[@]}"; do
            if grep -w -q -i $key "${file}"; then
                echo "  $CYAN==>$NORMAL $YELLOW $key $NORMAL"
            fi
        done
    done
}

while :;  do
    case $1 in
    -v|--version)
        echo "keyword finder $KF_VERSION"
        exit 0
        ;;
    -h|--help)
        echo "For documentation refer to: $DOC_URL"
        exit 0
        ;;
    -f|--file) 
        fvalue="$2"
        if is_str_empty $fvalue; then
            error "Please specify file path where you want to search your keywords!"
            exit 1
        fi

        if ! is_supported_file $fvalue; then
            error "Unsupported file format"
            print_supported_file_formats
            exit 1
        fi


        export_file $fvalue
        search_keywords_on_file
        exit 0
        ;;
    -d|--dir)
        dvalue="$2"
        if is_str_empty $dvalue; then
            error "Please specify directory path where you want to search your files!"
            exit 1
        else
            directory_path=$dvalue
        fi

        if [ ! -d "$directory_path" ];
        then 
            error "Given directory [ $directory_path ] not exist or incorrect"
            exit 1
        fi

        # debug $#
        # debug "$1 $2 $3 $4"
        for i in "$@"; do
            # debug "$i"
            case "$i" in
                -sc|--skip-conversion)
                    info "Conversion skipped, no files will be converted"
                    skip_conversion=true
                    shift
                    ;;
                -oa|--override-all)
                    info "All files overrided"
                    override_all=true
                    shift
                    ;;
            esac
        done

        collect_original_files
        
        if $skip_conversion; then
            collect_exported_files
            collect_matched_files
        else
            export_original_files
        fi

        show_collected_files
        search_keywords
        exit 0
        ;;
    ?)
        echo "Unknown flag, plese type $YELLOW sh keyword-finder.sh -h$NORMAL for more info" >&2
        exit 1
        ;;
    esac

    shift
done
