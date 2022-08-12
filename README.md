# pypackage_generator

[Timothy Helton](https://timothyhelton.github.io/)

[@T1M_Helton](https://twitter.com/T1M_Helton)

---

## Installation
All you need are the files **new_pyproject.sh** and **envfile_template**.

1. go to the [source file](https://github.com/TimothyHelton/pyproject_generator/blob/master/new_pyproject.sh)
1. Save as...
1. Change permissions to make the file user executable
    ```bash
    chmod u+x new_pyproject.sh
    ```
1. go to the [environment variable file ](https://github.com/TimothyHelton/pyproject_generator/blob/master/envfile_template)
1. Save as...
    1. save the file in the same location as **new_project.sh**
1. Rename file to **envfile**
    ```bash
    mv envfile_template envfile
    ```

---

## Quick Start Guide

### Configure envfile
1. Open the envfile
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

### Update the Docker Configuration
The base script make creates the minimum number of objects to define a Python
and NGINX container.
This is done to allow the automation of initializing the Sphinx documentation.
Once the script has been executed, modify the `if __name__ = 'main':` section
of `scripts/docker_config.py` to add additional services.
The following example would add a MongoDB container and configure the Python
container to utilize a GPU.

```bash
if __name__ == '__main__':
    config = ComposeConfiguration()
    services = (
        ComposeService.MONGO,
    )
    for s in services:
        config.add_service(s)
    config.add_gpu()
    config.write()
```

### Rebuild the Docker Environment
Once the `scrips/docker_config.py` file has been modified to the user's liking
call the following make target to update the Docker environment.
This will:
- update the `docker/docker-compose.yaml` file
- rebuild the Docker environment

```bash
make docker-update-config
```

---

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

## Makefile Targets
After the package is created there are a number of helpful shortcuts in the
**Makefile**.
The generated package `README.md` file has details for a number of the make
targets.

## Background
I found myself writing various pieces of code and wanted to make them easy to
share with the community.

As long as everything is in the right place creating Python packages and 
hosting them on PIP is a piece of cake. 

The bash script **pypackage_generator.sh** will automate the setup process 
for creating a Python package utilizing [Docker](https://www.docker.com/) 
and a number of great open source tools.
- [Git](https://git-scm.com/) for version control,
- [MongoDB](https://www.mongodb.com/) persistent data storage (optional),
- [pytest](https://docs.pytest.org/) for unit testing,
- [PGAdmin](https://www.pgadmin.org/) for database interactions (optional),
- [PostgreSQL](https://www.postgresql.org/) for persistent data storage(optional),
- [SPHINX](http://www.sphinx-doc.org/en/stable/#) for documentation,

#### Thanks for looking around and enjoy the day!
