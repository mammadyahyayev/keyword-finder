#!/bin/bash

# COLORS
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
PURPLE=$(tput setaf 5)
NORMAL=$(tput sgr0)

# Version, KF stands for KeywordFinder
KF_VERSION='v1.1.3'

# Docs
DOC_URL='https://github.com/mammadyahyayev/keyword-finder'

# constant variables
SUPPORTED_FILE_FORMATS=("docx" "pdf")
AUTHOR="Mammad Yahyayev"
AUTHOR_DESC="I am a passionate developer and I love open source projects."
AUTHOR_GITHUB_URL="https://github.com/mammadyahyayev"
AUTHOR_LINKEDIN_URL="https://www.linkedin.com/in/mammad-yahyayev/"

files=()
keywords=()
txt_files=()
temp_arr=()
declare -A file_map

# file variables
filename=""
file_extension=""
file_dir_path=""

# flag variables
skip_conversion=false
override_all=false
skip_search=false
has_file_formats_given=false
show_filename_only=false

# log functions
function error() {
    echo $RED"Error: $1"$NORMAL
}

function success() {
    echo $GREEN"$1"$NORMAL
}

function info() {
    echo $CYAN"$1"$NORMAL
}

function info_override() {
    echo -ne "$CYAN[INFO] $1\033[0K\r"$NORMAL
}

function warning() {
    echo $YELLOW"$1"$NORMAL
}

function debug() {
    echo $PURPLE"==> $1"$NORMAL
}

# str functions
function is_str_empty() {
    if [[ -z "${1// /}" ]]; then
        true
    else
        false
    fi
}

# array functions
function is_arr_empty() {
    local arr=("$@")
    local arr_len="${#arr[@]}"

    if [[ $arr_len -eq 0 ]]; then
        true
    else
        false
    fi
}


# directory functions
function is_dir_exist() {
    if [[ -d "$1" ]];
    then
        true
    else
        false
    fi
}

# file related functions
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

# print functions
function print_newline() {
    count=$1
    i=0
    while [[ i -lt $count ]]; do
        echo $'\n'
        i=$(( $i + 1 ))
    done
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
    local file_formats=("$@")

    if [[ ${#file_formats[@]} == 0 ]]; then
        file_formats=("${SUPPORTED_FILE_FORMATS[@]}")
    fi

    collect_directory_files "${file_formats[@]}"
    for file in "${temp_arr[@]}"; do
        local file_path="$directory_path/$file" 
        files+=("$file_path")
    done
    temp_arr=()
}

function collect_exported_files() {
    if ! is_dir_exist "__txt_exports__"; then
        error "Exports folder doesn't exist"
        exit 1
    fi

    local formats=("txt")
    collect_directory_files "${formats[@]}"

    for txt_file in "${temp_arr[@]}"; do
        local txt_file_path="$directory_path/__txt_exports__/$txt_file"
        local original_file_path="$directory_path/$txt_file"
        txt_files+=("$txt_file_path")
        file_map[$txt_file_path]=$original_file_path
    done

    temp_arr=()
}

function collect_matched_file() {
    local original_file=$1
    local original_file_dir_path="${original_file%/*}"

    directory_path="$original_file_dir_path"
    cd $original_file_dir_path
    collect_exported_files

    for txt_file in "${txt_files[@]}"; do
        local txt_file_name=$(basename "${txt_file%.*}")        
        local file_name=$(basename "${original_file%.*}")

        if [[ "$txt_file_name" = "$file_name" ]]; then
            # debug "$txt_file => $txt_file_name <==> $file_name => $file"
            file_map[$txt_file]="$original_file"
            break
        fi
    done
}

function show_collected_files() {
    local collected_file_count="${#files[@]}"
    success "${collected_file_count} file(s) collected"
    for file in "${files[@]}"; do
        if $show_filename_only; then
            local filename=$(basename "$file")
            success "==> $filename"
        else
            success "==> $file"
        fi
    done
    print_newline 1
}

function search_keywords() {
    read -p "Enter your keywords and separate them with comma: $YELLOW" str_keywords
    IFS=',' read -r -a keywords_arr <<<"$str_keywords"

    for i in "${!keywords_arr[@]}"; do
        keyword="${keywords_arr[$i]}"
        trimmed_keyword="$(echo -e "${keyword}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        keywords+=("$trimmed_keyword")
    done

    for key in "${keywords[@]}"; do
        echo $NORMAL"Keyword $YELLOW'$key'$NORMAL found in the following files:"
        for file in "${!file_map[@]}"; do
            if grep -w -q -i "$key" "${file}"; then
                if $show_filename_only; then
                    local filename=$(basename "${file_map[${file}]}")
                    echo "  $CYAN==>$NORMAL $filename"
                else
                    echo "  $CYAN==>$NORMAL ${file_map[${file}]}"
                fi
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
}

function export_original_files() {
    info "Files are preparing to convert..."
    local files_count="${#files[@]}"
    local converted_files_count=0
    for file in "${files[@]}"; do
        export_file "$file"
        converted_files_count=$(expr $converted_files_count + 1)
        info_override "${converted_files_count}/${files_count} converting..."
    done
    print_newline 1
    info "$files_count files are converted..."
}

function is_supported_file() {
    local file=$1
    local is_supported=false
    get_file_extension "$file" # it get file_extension from the path and assign it to 'file_extension' variable
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

function is_all_formats_supported() {
    local file_formats=("$@")
    for file_format in "${file_formats[@]}"; do
        local is_supported=false
        for formats in "${SUPPORTED_FILE_FORMATS[@]}"; do
            if [[ "$file_format" == "$formats" ]]; then
                is_supported=true    
            fi
        done

        if ! $is_supported; then
            error "Given file format '$file_format' is not supported!"
            print_supported_file_formats
            exit 1
        fi
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
    --author)
        echo $GREEN"Developer:$NORMAL   $CYAN==>$NORMAL $AUTHOR"
        echo $GREEN"Bio:$NORMAL         $CYAN==>$NORMAL $AUTHOR_DESC"
        echo $GREEN"Github:$NORMAL      $CYAN==>$NORMAL $AUTHOR_GITHUB_URL"
        echo $GREEN"Linkedin:$NORMAL    $CYAN==>$NORMAL $AUTHOR_LINKEDIN_URL"
        exit 0
        ;;
    -f|--file) 
        fvalue="$2"
        if is_str_empty $fvalue; then
            error "Please specify file path where you want to search your keywords!"
            exit 1
        fi
        if ! is_supported_file "$fvalue"; then
            error "Unsupported file format"
            print_supported_file_formats
            exit 1
        fi

        for i in "$@"; do
            case "$i" in
                -sc|--skip-conversion)
                    info "Conversion process skipped, file won't be converted"
                    skip_conversion=true
                    shift
                    ;;
                -ss|--skip-search)
                    info "Searching process skipped."
                    skip_search=true
                    shift
                    ;;
            esac
        done

        if $skip_conversion; then
            collect_matched_file $fvalue
        else
            info "File is converting..."
            export_file "$fvalue"
            success "Conversion is done."
        fi

        if ! $skip_search; then
            search_keywords_on_file
        fi
        exit 0
        ;;
    -d|--dir)
        dvalue="$2"
        if is_str_empty $dvalue; then
            error "Please specify directory path where you want to search your keyword!"
            exit 1
        else
            directory_path=$dvalue
        fi

        directory_path="${directory_path//'\'/'/'}"

        if [ ! -d "$directory_path" ];
        then 
            error "Directory [ $directory_path ] not exist or incorrect"
            exit 1
        fi

        for i in "$@"; do
            case "$i" in
                -sc|--skip-conversion)
                    info "Conversion process skipped, no files will be converted"
                    skip_conversion=true
                    shift
                    ;;
                -oa|--override-all)
                    info "Files are overrided."
                    override_all=true
                    shift
                    ;;
                -ss|--skip-search)
                    info "Searching process skipped."
                    skip_search=true
                    shift
                    ;;
                --file-format)
                    read -p "$CYAN Enter file formats and separate them with comma:$NORMAL $YELLOW" str_file_formats
                    IFS=',' read -r -a file_formats_arr <<< "$str_file_formats"
                    file_formats=()
                    has_file_formats_given=true

                    for i in "${!file_formats_arr[@]}"; do
                        file_format="${file_formats_arr[$i]}"
                        trimmed_file_formats="${file_format//' '/''}"
                        file_formats+=($trimmed_file_formats)
                    done

                    is_all_formats_supported ${file_formats[@]} # check and exit if format not supported.

                    shift
                    ;;
                -sfo|--show-filename-only)
                    show_filename_only=true
            esac
        done

        if $has_file_formats_given; then
            collect_original_files ${file_formats[@]}
        else
            collect_original_files
        fi

        if $skip_conversion; then
            collect_exported_files
        else
            export_original_files
        fi

        show_collected_files

        if ! $skip_search; then
            search_keywords
        fi
        exit 0
        ;;
    ?)
        error "Unknown flag, plese type $YELLOW sh keyword-finder.sh -h$NORMAL for more info" >&2
        exit 1
        ;;
    esac

    shift
done
