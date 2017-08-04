#! /bin/bash

# Exit if name argument is not given
if [ -z "$*" ]; then
    echo "A package name argument must be provided."
    exit 0
fi

AUTHOR="EnterAuthorName"
EMAIL="EnterAuthorEmail"
YEAR="2017"
FILE_SEP="/"

MAIN_DIR=$1
DATA_DIR="data"
DOCS_DIR="docs"
NOTEBOOK_DIR="notebooks"
SOURCE_DIR=$1
TEST_DIR="tests"

DOC_SUB_DIRECTORIES=("_build" "_static" "_templates")
SUB_DIRECTORIES=(${DATA_DIR} ${DOCS_DIR} ${NOTEBOOK_DIR} ${SOURCE_DIR})


###############################################################################


# Directory Structure
### Main Directory
mkdir "${MAIN_DIR}"
### Subdirectories
for dir in "${SUB_DIRECTORIES[@]}"; do
    mkdir "${MAIN_DIR}${FILE_SEP}${dir}"
done
### Documentation Subdirectories
for dir in "${DOC_SUB_DIRECTORIES[@]}"; do
    mkdir "${MAIN_DIR}${FILE_SEP}${DOCS_DIR}${FILE_SEP}${dir}"
done
### Test Directory
mkdir "${MAIN_DIR}${FILE_SEP}${SOURCE_DIR}${FILE_SEP}${TEST_DIR}"


# Constructors
INIT_HEADER="#! /usr/bin/env python3\n"
INIT_HEADER+="# -*- coding: utf-8 -*-\n\n"

PK_INIT=${INIT_HEADER}
PK_INIT+="from pkg_resources import get_distribution, DistributionNotFound\n"
PK_INIT+="import os.path as osp\n"
PK_INIT+="#from . import EnterModuleNameHere\n\n"
PK_INIT+="__version__ = '0.1.0'\n\n"
PK_INIT+="try:\n"
PK_INIT+="    _dist = get_distribution('${MAIN_DIR}')\n"
PK_INIT+="    dist_loc = osp.normcase(_dist.location)\n"
PK_INIT+="    here = osp.normcase(__file__)\n"
PK_INIT+="    if not here.startswith(osp.join(dist_loc, '${MAIN_DIR}')):\n"
PK_INIT+="        raise DistributionNotFound\n"
PK_INIT+="except DistributionNotFound:\n"
PK_INIT+="    __version__ = 'Please install this project with setup.py'\n"
PK_INIT+="else:\n"
PK_INIT+="    __version__ = _dist.version\n\n"

BASE_PATH="${MAIN_DIR}${FILE_SEP}${SOURCE_DIR}${FILE_SEP}"
### Package Constructor
printf %b "${PK_INIT}" >> "${BASE_PATH}__init__.py"
### Test Constructor
printf %b "${INIT_HEADER}" >> "${BASE_PATH}${FILE_SEP}${TEST_DIR}${FILE_SEP}__init__.py"


# LICENSE
LICENSE+="Copyright (c) ${YEAR}, ${AUTHOR}.\n"
LICENSE+="All rights reserved.\n"
LICENSE+="\n"
LICENSE+="Redistribution and use in source and binary forms, with or without\n"
LICENSE+="modification, are permitted provided that the following conditions are met:\n"
LICENSE+="\n"
LICENSE+="* Redistributions of source code must retain the above copyright notice, this\n"
LICENSE+="  list of conditions and the following disclaimer.\n"
LICENSE+="\n"
LICENSE+="* Redistributions in binary form must reproduce the above copyright notice,\n"
LICENSE+="  this list of conditions and the following disclaimer in the documentation\n"
LICENSE+="  and/or other materials provided with the distribution.\n"
LICENSE+="\n"
LICENSE+="* Neither the name of the ${MAIN_DIR} Developers nor the names of any\n"
LICENSE+="  contributors may be used to endorse or promote products derived from this\n"
LICENSE+="  software without specific prior written permission.\n"
LICENSE+="\n"
LICENSE+="THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"\n"
LICENSE+="AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n"
LICENSE+="IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n"
LICENSE+="DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR\n"
LICENSE+="ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES\n"
LICENSE+="(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;\n"
LICENSE+="LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON\n"
LICENSE+="ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT\n"
LICENSE+="(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS\n"
LICENSE+="SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n"

printf %b "${LICENSE}" >> "${MAIN_DIR}${FILE_SEP}LICENSE.txt"


# MANIFEST
printf %b "include LICENSE.txt" >> "${MAIN_DIR}${FILE_SEP}MANIFEST.in"


# README
touch "${MAIN_DIR}${FILE_SEP}README.md"


# setup.py
SETUP+="#!/usr/bin/env python3\n"
SETUP+="# -*- coding: utf-8 -*-\n"
SETUP+="\n"
SETUP+="from codecs import open\n"
SETUP+="import os.path as osp\n"
SETUP+="import re\n"
SETUP+="\n"
SETUP+="from setuptools import setup, find_packages\n"
SETUP+="\n"
SETUP+="\n"
SETUP+="with open('${MAIN_DIR}${FILE_SEP}__init__.py', 'r') as fd:\n"
SETUP+="    version = re.search(r'^__version__\s*=\s*[\'\"]([^\'\"]*)[\'\"]',\n"
SETUP+="                        fd.read(), re.MULTILINE).group(1)\n"
SETUP+="\n"
SETUP+="here = osp.abspath(osp.dirname(__file__))\n"
SETUP+="with open(osp.join(here, 'README.md'), encoding='utf-8') as f:\n"
SETUP+="    long_description = f.read()\n"
SETUP+="\n"
SETUP+="setup(\n"
SETUP+="    name='${MAIN_DIR}',\n"
SETUP+="    version=version,\n"
SETUP+="    description='Modules related to EnterDescriptionHere',\n"
SETUP+="    author='${AUTHOR}',\n"
SETUP+="    author_email='${EMAIL}',\n"
SETUP+="    license='BSD',\n"
SETUP+="    classifiers=[\n"
SETUP+="        'Development Status :: 1 - Planning',\n"
SETUP+="        'Environment :: Console',\n"
SETUP+="        'Intended Audience :: Developers',\n"
SETUP+="        'License :: OSI Approved',\n"
SETUP+="        'Natural Language :: English',\n"
SETUP+="        'Operating System :: OS Independent',\n"
SETUP+="        'Programming Language :: Python :: 3',\n"
SETUP+="        'Programming Language :: Python :: 3.6',\n"
SETUP+="        'Topic :: Software Development :: Build Tools',\n"
SETUP+="        ],\n"
SETUP+="    keywords='EnterKeywordsHere',\n"
SETUP+="    packages=find_packages(exclude=['docs', 'tests*']),\n"
SETUP+="    install_requires=[\n"
SETUP+="        ],\n"
SETUP+="    package_dir={'${MAIN_DIR}': '${SOURCE_DIR}'},\n"
SETUP+="    include_package_data=True,\n"
SETUP+="    )\n"
SETUP+="\n"
SETUP+="\n"
SETUP+="if __name__ == '__main__':\n"
SETUP+="    pass\n"

printf %b "${SETUP}" >> "${MAIN_DIR}${FILE_SEP}setup.py"


# Version Control
### Git Ignore File
GITIGNORE="# Compiled source #\n"
GITIGNORE+="build${FILE_SEP}*\n"
GITIGNORE+="*.com\n"
GITIGNORE+="dist${FILE_SEP}*\n"
GITIGNORE+="*.egg-info${FILE_SEP}*\n"
GITIGNORE+="*.class\n"
GITIGNORE+="*.dll\n"
GITIGNORE+="*.exe\n"
GITIGNORE+="*.o\n"
GITIGNORE+="*.pdf\n"
GITIGNORE+="*.pyc\n"
GITIGNORE+="*.so\n"
GITIGNORE+="\n"
GITIGNORE+="# Ipython Files #\n"
GITIGNORE+="${NOTEBOOK_DIR}${FILE_SEP}.ipynb_checkpoints${FILE_SEP}*\n"
GITIGNORE+="\n"
GITIGNORE+="# Logs and databases #\n"
GITIGNORE+="*.log\n"
GITIGNORE+="*.sql\n"
GITIGNORE+="*.sqlite\n"
GITIGNORE+="\n"
GITIGNORE+="# OS generatee files #\n"
GITIGNORE+=".DS_Store\n"
GITIGNORE+=".DS_store?\n"
GITIGNORE+="._*\n"
GITIGNORE+=".Spotlight-V100\n"
GITIGNORE+=".Trashes\n"
GITIGNORE+="ehthumbs.db\n"
GITIGNORE+="Thumbs.db\n"
GITIGNORE+="\n"
GITIGNORE+="# Packages #\n"
GITIGNORE+="*.7z\n"
GITIGNORE+="*.dmg\n"
GITIGNORE+="*.gz\n"
GITIGNORE+="*.iso\n"
GITIGNORE+="*.jar\n"
GITIGNORE+="*.rar\n"
GITIGNORE+="*.tar\n"
GITIGNORE+="*.zip\n"
GITIGNORE+="# Profile files #\n"
GITIGNORE+="*.coverage\n"
GITIGNORE+="*.profile\n"
GITIGNORE+="\n"
GITIGNORE+="# PyCharm files #\n"
GITIGNORE+=".idea${FILE_SEP}*\n"
GITIGNORE+="${MAIN_DIR}${FILE_SEP}.idea${FILE_SEP}*\n"
GITIGNORE+="\n"
GITIGNORE+="# pytest files #\n"
GITIGNORE+=".cache${FILE_SEP}*\n"
GITIGNORE+="\n"
GITIGNORE+="# Raw Data #\n"
GITIGNORE+="${DATA_DIR}${FILE_SEP}*\n"
GITIGNORE+="\n"
GITIGNORE+="# Sphinx files #\n"
GITIGNORE+="docs/_build/*\n"
GITIGNORE+="docs/_static/*\n"
GITIGNORE+="docs/_templates/*\n"
GITIGNORE+="docs/Makefile\n"

printf %b "${GITIGNORE}" >> "${MAIN_DIR}${FILE_SEP}.gitignore"
cd ${MAIN_DIR}
git init
