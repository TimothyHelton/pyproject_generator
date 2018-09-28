#! /bin/bash

# Exit if name argument is not given
if [ -z "$*" ]; then
    echo "A package name argument must be provided."
    exit 0
fi

AUTHOR="EnterAuthorName"
EMAIL="EnterAuthorEmail"
PYTHON_VERSION="3.6"
PKG_VERSION="0.1.0"

MAIN_DIR=$1
DATA_DIR="data"
DOCKER_DIR="docker"
DOCS_DIR="docs"
FILE_SEP="/"
NOTEBOOK_DIR="notebooks"
SOURCE_DIR=$1
TEST_DIR="tests"
WHEEL_DIR="wheels"
YEAR=`date +%Y`


###############################################################################


SUB_DIRECTORIES=(${DATA_DIR} \
                 ${DOCKER_DIR} \
                 ${DOCS_DIR} \
                 ${NOTEBOOK_DIR} \
                 ${SOURCE_DIR} \
                 ${WHEEL_DIR})

PY_HEADER+="#! /usr/bin/env python3\n"
PY_HEADER+="# -*- coding: utf-8 -*-\n\n"

SRC_PATH="${MAIN_DIR}${FILE_SEP}${SOURCE_DIR}${FILE_SEP}"


directories() {
    # Main directory
    mkdir "${MAIN_DIR}"
    # Subdirectories
    for dir in "${SUB_DIRECTORIES[@]}"; do
        mkdir "${MAIN_DIR}${FILE_SEP}${dir}"
    done
    # Test directory
    mkdir "${MAIN_DIR}${FILE_SEP}${SOURCE_DIR}${FILE_SEP}${TEST_DIR}"
}


constructor_pkg() {
    txt=${PY_HEADER}
    txt+="from pkg_resources import get_distribution, DistributionNotFound\n"
    txt+="import os.path as osp\n\n"
    txt+="#from . import cli\n"
    txt+="#from . import EnterModuleNameHere\n\n"
    txt+="__version__ = '0.1.0'\n\n"
    txt+="try:\n"
    txt+="    _dist = get_distribution('${MAIN_DIR}')\n"
    txt+="    dist_loc = osp.normcase(_dist.location)\n"
    txt+="    here = osp.normcase(__file__)\n"
    txt+="    if not here.startswith(osp.join(dist_loc, '${MAIN_DIR}')):\n"
    txt+="        raise DistributionNotFound\n"
    txt+="except DistributionNotFound:\n"
    txt+="    __version__ = 'Please install this project with setup.py'\n"
    txt+="else:\n"
    txt+="    __version__ = _dist.version\n\n"

    printf %b "${txt}" >> "${SRC_PATH}__init__.py"
}


constructor_test() {
    printf %b "${PY_HEADER}" >> "${SRC_PATH}${FILE_SEP}${TEST_DIR}${FILE_SEP}__init__.py"
}


docker_compose() {
    txt="version: '3'\n\n"
    txt+="services:\n\n"

    txt+="  nginx:\n"
    txt+="    container_name: ${MAIN_DIR}_nginx\n"
    txt+="    image: nginx:alpine\n"
    txt+="    ports:\n"
    txt+="      - 8080:80\n"
    txt+="    restart: always\n"
    txt+="    volumes:\n"
    txt+="      - ../docs/_build/html:/usr/share/nginx/html:ro\n\n"

    txt+="  postgres:\n"
    txt+="    container_name: ${MAIN_DIR}_postgres\n"
    txt+="    image: postgres:alpine\n"
    txt+="    environment:\n"
    txt+="      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}\n"
    txt+="      POSTGRES_DB: \${POSTGRES_DB}\n"
    txt+="      POSTGRES_USER: \${POSTGRES_USER}\n"
    txt+="    ports:\n"
    txt+="      - 5432:5432\n"
    txt+="    restart: always\n"
    txt+="    volumes:\n"
    txt+="      - ${MAIN_DIR}-db:/var/lib/postgresql/data\n\n"

    txt+="  pgadmin:\n"
    txt+="    container_name: chrysalis_pgadmin\n"
    txt+="    image: dpage/pgadmin4\n"
    txt+="    environment:\n"
    txt+="      PGADMIN_DEFAULT_EMAIL: \${PGADMIN_DEFAULT_EMAIL}\n"
    txt+="      PGADMIN_DEFAULT_PASSWORD: \${PGADMIN_DEFAULT_PASSWORD}\n"
    txt+="    external_links:\n"
    txt+="      - chrysalis_postgres:chrysalis_postgres\n"
    txt+="    ports:\n"
    txt+="      - 5000:80\n\n"

    txt+="  python:\n"
    txt+="    container_name: ${MAIN_DIR}_python\n"
    txt+="    build:\n"
    txt+="      context: ..\n"
    txt+="      dockerfile: docker/python-Dockerfile\n"
    txt+="    image: ${MAIN_DIR}_python\n"
    txt+="    restart: always\n"
    txt+="    tty: true\n"
    txt+="    volumes:\n"
    txt+="      - ..:/usr/src/${MAIN_DIR}\n"

    txt+="volumes:\n"
    txt+="  ${MAIN_DIR}-db:\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}docker-compose.yml"
}


docker_python() {
    txt="FROM python:3.6-alpine\n\n"
    txt+="RUN apk add --update \\\\\n"
    txt+="\talpine-sdk \\\\\n"
    txt+="\tbash\n\n"
    txt+="WORKDIR /usr/src/${MAIN_DIR}\n\n"
    txt+="COPY . .\n\n"
    txt+="RUN pip3 install --upgrade pip\n\n"
    txt+="RUN pip3 install --no-cache-dir -r requirements.txt\n\n"
    txt+="RUN pip3 install -e .\n\n"
    txt+="CMD [ \"/bin/bash\" ]\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}python-Dockerfile"
}


envfile(){
    txt="# PGAdmin\n"
    txt+="export PGADMIN_DEFAULT_EMAIL=<enter_user>@${MAIN_DIR}.com\n"
    txt+="export PGADMIN_DEFAULT_PASSWORD=<enter_password>\n\n"

    txt+="# Postgres\n"
    txt+="export POSTGRES_PASSWORD=<enter_password>\n"
    txt+="export POSTGRES_DB=${MAIN_DIR}\n"
    txt+="export POSTGRES_USER=<enter_user>\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}envfile"
}


git_attributes() {
    txt="*.ipynb    filter=jupyter_clear_output"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}.gitattributes"
}


git_config() {
    # Setup Git to ignore Jupyter Notebook Outputs
    txt="[filter \"jupyter_clear_output\"]\n"
    txt+="    clean = \"jupyter nbconvert --stdin --stdout \ \n"
    txt+="             --log-level=ERROR --to notebook \ \n"
    txt+="             --ClearOutputPreprocessor.enabled=True\"\n"
    txt+="    smudge = cat\n"
    txt+="    required = true"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}.gitconfig"
}


git_ignore() {
    txt="# Compiled source #\n"
    txt+="build${FILE_SEP}*\n"
    txt+="*.com\n"
    txt+="dist${FILE_SEP}*\n"
    txt+="*.egg-info${FILE_SEP}*\n"
    txt+="*.class\n"
    txt+="*.dll\n"
    txt+="*.exe\n"
    txt+="*.o\n"
    txt+="*.pdf\n"
    txt+="*.pyc\n"
    txt+="*.so\n\n"

    txt+="# Ipython Files #\n"
    txt+="${NOTEBOOK_DIR}${FILE_SEP}.ipynb_checkpoints${FILE_SEP}*\n\n"

    txt+="# Logs and databases #\n"
    txt+="*.log\n"
    txt+="*.sql\n"
    txt+="*.sqlite\n\n"

    txt+="# OS generated files #\n"
    txt+="envfile\n"
    txt+=".DS_Store\n"
    txt+=".DS_store?\n"
    txt+="._*\n"
    txt+=".Spotlight-V100\n"
    txt+=".Trashes\n"
    txt+="ehthumbs.db\n"
    txt+="Thumbs.db\n\n"

    txt+="# Packages #\n"
    txt+="*.7z\n"
    txt+="*.dmg\n"
    txt+="*.gz\n"
    txt+="*.iso\n"
    txt+="*.jar\n"
    txt+="*.rar\n"
    txt+="*.tar\n"
    txt+="*.zip\n\n"

    txt+="# Profile files #\n"
    txt+="*.coverage\n"
    txt+="*.profile\n\n"

    txt+="# Project files #\n"
    txt+="source_venv.sh\n\n"

    txt+="# PyCharm files #\n"
    txt+=".idea${FILE_SEP}*\n"
    txt+="${MAIN_DIR}${FILE_SEP}.idea${FILE_SEP}*\n\n"

    txt+="# pytest files #\n"
    txt+=".cache${FILE_SEP}*\n"
    txt+="\n"
    txt+="# Raw Data #\n"
    txt+="${DATA_DIR}${FILE_SEP}*\n\n"

    txt+="# Sphinx files #\n"
    txt+="docs/_build/*\n"
    txt+="docs/_static/*\n"
    txt+="docs/_templates/*\n"
    txt+="docs/Makefile\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}.gitignore"
}


git_init() {
    cd ${MAIN_DIR}
    git init
}


license() {
    txt="Copyright (c) ${YEAR}, ${AUTHOR}.\n"
    txt+="All rights reserved.\n"
    txt+="\n"
    txt+="Redistribution and use in source and binary forms, with or without\n"
    txt+="modification, are permitted provided that the following conditions are met:\n"
    txt+="\n"
    txt+="* Redistributions of source code must retain the above copyright notice, this\n"
    txt+="  list of conditions and the following disclaimer.\n"
    txt+="\n"
    txt+="* Redistributions in binary form must reproduce the above copyright notice,\n"
    txt+="  this list of conditions and the following disclaimer in the documentation\n"
    txt+="  and/or other materials provided with the distribution.\n"
    txt+="\n"
    txt+="* Neither the name of the ${MAIN_DIR} Developers nor the names of any\n"
    txt+="  contributors may be used to endorse or promote products derived from this\n"
    txt+="  software without specific prior written permission.\n"
    txt+="\n"
    txt+="THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"\n"
    txt+="AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n"
    txt+="IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n"
    txt+="DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR\n"
    txt+="ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES\n"
    txt+="(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;\n"
    txt+="LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON\n"
    txt+="ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT\n"
    txt+="(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS\n"
    txt+="SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}LICENSE.txt"
}


makefile() {
    txt="PROJECT=${MAIN_DIR}\n"
    txt+="MOUNT_DIR=\$(shell pwd)\n"
    txt+="SRC_DIR=/usr/src/${MAIN_DIR}\n"
    txt+="VERSION=\$(shell echo \$(shell cat \$(PROJECT)/__init__.py | \\\\\n"
    txt+="\t\t\tgrep \"^__version__\" | \\\\\n"
    txt+="\t\t\tcut -d = -f 2))\n\n"

    txt+="include envfile\n"
    txt+=".PHONY: docs upgrade-packages\n\n"

    txt+="docker-down:\n"
    txt+="\tdocker-compose -f docker/docker-compose.yml down\n"

    txt+="\ndocker-up:\n"
    txt+="\tdocker-compose -f docker/docker-compose.yml up -d\n"

    txt+="\ndocs: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \"cd docs && make html\"\n"
    txt+="\topen http://localhost:8080\n\n"

    txt+="docs-init: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \\\\\n"
    txt+="\t\t\t\"cd docs \\\\\n"
    txt+="\t\t\t && sphinx-quickstart -q \\\\\n"
    txt+="\t\t\t\t-p \$(PROJECT) \\\\\n"
    txt+="\t\t\t\t-a ${AUTHOR} \\\\\n"
    txt+="\t\t\t\t-v \$(VERSION) \\\\\n"
    txt+="\t\t\t\t--ext-autodoc \\\\\n"
    txt+="\t\t\t\t--ext-viewcode \\\\\n"
    txt+="\t\t\t\t--makefile \\\\\\n"
    txt+="\t\t\t\t--no-batchfile\"\n\n"

    txt+="pgadmin: docker-up\n"
    txt+="\topen http://localhost:5000\n\n"

    txt+="psql: docker-up\n"
    txt+="\tdocker container exec -it \$(PROJECT)_postgres \\\\\n"
    txt+="\t\tpsql -U \${POSTGRES_USER} \$(PROJECT)\n\n"

    txt+="view-docs: docker-up\n"
    txt+="\topen http://localhost:8080\n\n"

    txt+="upgrade-packages: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \\\\\n"
    txt+="\t\t\t\"pip3 install -U pip \\\\\n"
    txt+="\t\t\t && pip3 install -U \$(shell pip3 freeze | \\\\\n"
    txt+="\t\t\t\t\t\tgrep -v '\$(PROJECT)' | \\\\\n"
    txt+="\t\t\t\t\t\tcut -d = -f 1) \\\\\n"
    txt+="\t\t\t && pip3 freeze > requirements.txt\"\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}Makefile"
}


manifest() {
    printf %b "include LICENSE.txt" >> "${MAIN_DIR}${FILE_SEP}MANIFEST.in"
}


readme() {
    txt="# PGAdmin Setup\n"
    txt+="1. From the main directory call \`make pgadmin\`\n"
    txt+="    - The default browser will open to \`localhost:5000\`\n"
    txt+="1. Enter the **PGAdmin** default user and password.\n"
    txt+="    - These variable are set in the \`envfile\`.\n"
    txt+="1. Click \`Add New Server\`.\n"
    txt+="    - General Name: Enter the <project_name>\n"
    txt+="    - Connection Host: Enter <project_name>_postgres\n"
    txt+="    - Connection Username and Password: Enter **Postgres** username and password from the \`envfile\`.\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}README.md"
}


requirements() {
    touch "${MAIN_DIR}${FILE_SEP}requirements.txt"
}


setup() {
    txt="#!/usr/bin/env python3\n"
    txt+="# -*- coding: utf-8 -*-\n"
    txt+="\n"
    txt+="from codecs import open\n"
    txt+="import os.path as osp\n"
    txt+="import re\n"
    txt+="\n"
    txt+="from setuptools import setup, find_packages\n"
    txt+="\n"
    txt+="\n"
    txt+="with open('${MAIN_DIR}${FILE_SEP}__init__.py', 'r') as fd:\n"
    txt+="    version = re.search(r'^__version__\s*=\s*[\'\"]([^\'\"]*)[\'\"]',\n"
    txt+="                        fd.read(), re.MULTILINE).group(1)\n"
    txt+="\n"
    txt+="here = osp.abspath(osp.dirname(__file__))\n"
    txt+="with open(osp.join(here, 'README.md'), encoding='utf-8') as f:\n"
    txt+="    long_description = f.read()\n"
    txt+="\n"
    txt+="setup(\n"
    txt+="    name='${MAIN_DIR}',\n"
    txt+="    version=version,\n"
    txt+="    description='Modules related to EnterDescriptionHere',\n"
    txt+="    author='${AUTHOR}',\n"
    txt+="    author_email='${EMAIL}',\n"
    txt+="    license='BSD',\n"
    txt+="    classifiers=[\n"
    txt+="        'Development Status :: 1 - Planning',\n"
    txt+="        'Environment :: Console',\n"
    txt+="        'Intended Audience :: Developers',\n"
    txt+="        'License :: OSI Approved',\n"
    txt+="        'Natural Language :: English',\n"
    txt+="        'Operating System :: OS Independent',\n"
    txt+="        'Programming Language :: Python :: 3',\n"
    txt+="        'Programming Language :: Python :: 3.6',\n"
    txt+="        'Topic :: Software Development :: Build Tools',\n"
    txt+="        ],\n"
    txt+="    keywords='EnterKeywordsHere',\n"
    txt+="    packages=find_packages(exclude=['docs', 'tests*']),\n"
    txt+="    install_requires=[\n"
    txt+="        'sphinx',\n"
    txt+="        ],\n"
    txt+="    package_dir={'${MAIN_DIR}': '${SOURCE_DIR}'},\n"
    txt+="    include_package_data=True,\n"
    txt+="    entry_points={\n"
    txt+="        'console_scripts': [\n"
    txt+="            #'<EnterCommandName>=${MAIN_DIR}.cli:<EnterFunction>',\n"
    txt+="        ]\n"
    txt+="    }\n"
    txt+=")\n"
    txt+="\n"
    txt+="\n"
    txt+="if __name__ == '__main__':\n"
    txt+="    pass\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}setup.py"
}


directories
constructor_pkg
constructor_test
docker_compose
docker_python
envfile
git_attributes
git_config
git_ignore
license
makefile
manifest
readme
requirements
setup
git_init
