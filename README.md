# pypackage_generator

[Timothy Helton](https://timothyhelton.github.io/)

[@T1M_Helton](https://twitter.com/T1M_Helton)


## Installation
All you need is the for **pypackage_generator.sh**.

1. go to [source file](https://github.com/TimothyHelton/pyproject_generator/blob/master/pypackage_generator.sh)
1. Save as...
1. Change permissions to make the file user executable
    ```bash
    chmod u+x pypackage_generator.sh
    ```


## Quick Start Guide

### Configuration
1. Enter your name in the author argument
    ```bash
    AUTHOR="Timothy Helton"
    ```
1. Enter your email address in the email argument
    ```bash
    EMAIL="timothy.j.helton@gmail.com"
    ```
1. Enter the current year
    ```bash
    YEAR="2017"
    ```
### Execution
The script has a single required argument, which is the name of the package.
```bash
./pypackage_generator example_package
```
A new repository will be generated and initialized in Git. 

## What will the script generate?
- Package Main Directory
- License File
    - The default license is based off the open source license used by NumPy.
- Manifest File
- Readme File
- Python Setup File
- .gitignore File
- Data Directory
- Documentation Directory
- Source Directory
- Source Constructor
- Tests Directory
- Tests Constructor
- .git Directory

#### The Package hierarchy
```bash
├── example_package
│   ├── LICENSE.txt
│   ├── MANIFEST.in
│   ├── README.md
│   ├── data/
│   ├── docs/
│   │   ├── _build
│   │   ├── _static
│   │   └── _templates
│   ├── example_package/
│   │   ├── __init__.py
│   │   └── tests/
│   │       └── __init__.py
│   ├── notebooks
│   ├── setup.py
│   ├── .git/
│   └── .gitignore
```

## Background
I found myself writing various pieces of code, primarily in Python, for the 
[K2 Data Science Bootcamp](http://www.k2datascience.com/data-science) 
(which I highly recommend), and wanted to make them easy to share with the 
community.

As long as everything is in the right place creating Python packages and 
hosting them on PIP is a piece of cake. 

The bash script **pypackage_generator.sh** will automate the setup process 
for creating a Python package, which uses
[SPHINX](http://www.sphinx-doc.org/en/stable/#)
for documentation and [Git](https://git-scm.com/) for version control.

#### Thanks for looking around and enjoy the day!
