# pypackage_generator

[Timothy Helton](https://timothyhelton.github.io/)

[@T1M_Helton](https://twitter.com/T1M_Helton)


## Installation
All you need is the file **new_pyproject.sh**.

1. go to [source file](https://github.com/TimothyHelton/pyproject_generator/blob/master/new_pyproject.sh)
1. Save as...
1. Change permissions to make the file user executable
    ```bash
    chmod u+x new_pyproject.sh
    ```


## Quick Start Guide

### Configure envfile
1. Enter your name in the author argument
    ```bash
    export AUTHOR="Timothy Helton"
    ```
1. Enter your email address in the email argument
    ```bash
    export EMAIL="timothy.j.helton@gmail.com"
    ```

### Execution
The script has a single required argument, which is the name of the package.
```bash
./new_pyproject.sh example_package
```
A new repository will be generated in the current directory and initialized
with Git version control.

## What will the script generate?
- Package Main Directory
    - License File (based off the open source license used by NumPy)
- Manifest File
- Make File
- Readme File
- Data Directory
- Docker Directory
    - Docker Python File
    - Docker Compose File
- Documentation Directory
- Environment Variable File
- Source Directory
    - Source Constructor
    - Tests Directory
        - Tests Constructor
        - Tests Fixture
- Git Attributes File
- Git Configuration File
- Git Ignore File
- Notebook Directory
- Requirements File
- Python Setup File
- Wheel Directory

#### The Package hierarchy
```bash
├── example_package
│   ├── LICENSE.txt
│   ├── MANIFEST.in
│   ├── Makefile
│   ├── README.md
│   ├── data
│   ├── docker
│   │   ├── docker-compose.yml
│   │   └── python-Dockerfile
│   ├── docs
│   ├── envfile
│   ├── example_package
│   │   ├── __init__.py
│   │   └── tests
│   │       ├── __init__.py
│   │       └── conftest.py
│   ├── .gitattributes
│   ├── .gitconfig
│   ├── .gitignore
│   ├── notebooks
│   ├── requirements.txt
│   ├── setup.py
│   └── wheels
```

## Background
I found myself writing various pieces of code and wanted to make them easy to
share with the community.

As long as everything is in the right place creating Python packages and 
hosting them on PIP is a piece of cake. 

The bash script **pypackage_generator.sh** will automate the setup process 
for creating a Python package, which uses
[SPHINX](http://www.sphinx-doc.org/en/stable/#) for documentation,
[PostgreSQL](https://www.postgresql.org/) for persistent data storage,
[PGAdmin](https://www.pgadmin.org/) for database interactions,
[Git](https://git-scm.com/) for version control,
and is contained in [Docker](https://www.docker.com/) containers.

#### Thanks for looking around and enjoy the day!
