<!-- docs/usage.md -->

# Usages

**SIDENOTE:** Try this script on **Git Bash**, maybe there will be some problems on other terminals</br>

In order to use this script first clone the repo by doing following commands

```cmd
git clone git@github.com:MamedYahyayev/keyword-finder.git
cd keyword-finder
```

## Flags

- **-d** or **--dir**</br>
You can give directory that you want to search your files with this flag

```cmd
sh keyword-finder.sh -d "C:/Users/User/Desktop/test"
```

Keep in your mind that, path must be absolute. If given directory path, not exist you will get and **error message**.

- **-v** or **--version**</br>

As the name suggests the flag will print the version

```cmd
sh keyword-finder.sh -v
```

Result

```cmd
keyword finder 1.0.1
```

- **-h** or **--help**</br>
You can get help with this flag, it will refer to the documentation. If you don't find any solution based on your concern
create an [issue](https://github.com/MamedYahyayev/keyword-finder/issues) on Github. I will try to provide solution related to your problem.