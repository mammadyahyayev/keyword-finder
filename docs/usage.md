<!-- docs/usage.md -->

# Usages

**SIDENOTE:** Try this script on **Git Bash**, maybe there will be some problems on other terminals</br>

In order to use this script first clone the repo by doing following commands

```cmd
git clone git@github.com:MamedYahyayev/keyword-finder.git
cd keyword-finder
```

## Flags

- **-f** or **--file**</br>
This flag allow you to search multiple keywords in one file.

```cmd
sh keyword-finder.sh -f "C:/Users/User/Desktop/test/book.pdf"
# or
sh keyword-finder.sh --file "C:/Users/User/Desktop/test/book.pdf"
```

If the give file format not supported, it will throw an error.
Please use **docx** or **pdf**

- **-d** or **--dir**</br>
You can give directory that you want to search your files with this flag

```cmd
sh keyword-finder.sh -d "C:/Users/User/Desktop/test"
# or
sh keyword-finder.sh --dir "C:/Users/User/Desktop/test"
```

Keep in your mind that, path must be absolute. If given directory path, not exist you will get and **error message**.

- **-sc** or **--skip-conversion**</br>
This is a boolean flag, you don't need to give any value for this flag, just mention it on the script execution, it will
skip conversion process. Conversion is a process that convert supported file formats into txt format to search keywords on
the file. If you have already convert your files, you don't need to convert them again. This flag will save your time.

```cmd
sh keyword-finder.sh -d "C:/Users/User/Desktop/test" -sc
# or
sh keyword-finder.sh -d "C:/Users/User/Desktop/test" --skip-conversion
```

- **-ss** or **--skip-search**</br>
This is a boolean flag, you don't need to give any value for this flag, just mention it on the script execution, it will
skip search process. It is useful if you don't need to search right now.

```cmd
sh keyword-finder.sh -d "C:/Users/User/Desktop/test" -ss
# or
sh keyword-finder.sh -d "C:/Users/User/Desktop/test" --skip-search
```

- **--file-format**</br>
This flag will ask you to enter the file format that you want to convert, for example,
When you execute the following command, terminal will ask you to enter file formats.
**Caution:** Only add supported file formats (*pdf*, *docx*).</br>
If you type *docx*, then app will omit *pdf* files' conversion. That also allow you to deal
only desired file formats.

```cmd
sh keyword-finder.sh -d "C:/Users/User/Desktop/test" --file-format
```

- **-v** or **--version**</br>

As the name suggests the flag will print the version

```cmd
sh keyword-finder.sh -v
```

Result

```cmd
keyword finder 1.1.2
```

- **-h** or **--help**</br>
You can get help with this flag, it will refer to the documentation. If you don't find any solution based on your concern
create an [issue](https://github.com/MamedYahyayev/keyword-finder/issues) on Github. I will try to provide solution related to your problem.
