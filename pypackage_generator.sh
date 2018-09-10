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
NGINX_DIR="nginx"
NOTEBOOK_DIR="notebooks"
SOURCE_DIR=$1
TEST_DIR="tests"
WHEEL_DIR="wheels"
YEAR=`date +%Y`


###############################################################################


SUB_DIRECTORIES=(${DATA_DIR} \
                 ${DOCKER_DIR} \
                 ${DOCS_DIR} \
                 ${NGINX_DIR} \
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


docker_nginx() {
    txt="FROM nginx:alpine\n\n"
    txt+="RUN rm -v /etc/nginx/nginx.conf\n\n"
    txt+="COPY nginx/nginx.conf /etc/nginx/nginx.conf\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}nginx-Dockerfile"
}


docker_python() {
    txt="FROM python:3.6-alpine\n\n"
    txt+="RUN apk add --update alpine-sdk\n\n"
    txt+="WORKDIR /usr/src/${MAIN_DIR}\n\n"
    txt+="COPY . .\n\n"
    txt+="RUN pip install --upgrade pip\n\n"
    txt+="RUN pip install --no-cache-dir -r requirements.txt\n\n"
    txt+="RUN pip install -e .\n\n"
    txt+="CMD [ \"/bin/bash\" ]\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}python-Dockerfile"
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
    txt+="*.so\n"
    txt+="\n"
    txt+="# Ipython Files #\n"
    txt+="${NOTEBOOK_DIR}${FILE_SEP}.ipynb_checkpoints${FILE_SEP}*\n"
    txt+="\n"
    txt+="# Logs and databases #\n"
    txt+="*.log\n"
    txt+="*.sql\n"
    txt+="*.sqlite\n"
    txt+="\n"
    txt+="# OS generatee files #\n"
    txt+=".DS_Store\n"
    txt+=".DS_store?\n"
    txt+="._*\n"
    txt+=".Spotlight-V100\n"
    txt+=".Trashes\n"
    txt+="ehthumbs.db\n"
    txt+="Thumbs.db\n"
    txt+="\n"
    txt+="# Packages #\n"
    txt+="*.7z\n"
    txt+="*.dmg\n"
    txt+="*.gz\n"
    txt+="*.iso\n"
    txt+="*.jar\n"
    txt+="*.rar\n"
    txt+="*.tar\n"
    txt+="*.zip\n"
    txt+="\n"
    txt+="# Profile files #\n"
    txt+="*.coverage\n"
    txt+="*.profile\n"
    txt+="\n"
    txt+="# Project files #\n"
    txt+="source_venv.sh\n"
    txt+="\n"
    txt+="# PyCharm files #\n"
    txt+=".idea${FILE_SEP}*\n"
    txt+="${MAIN_DIR}${FILE_SEP}.idea${FILE_SEP}*\n"
    txt+="\n"
    txt+="# pytest files #\n"
    txt+=".cache${FILE_SEP}*\n"
    txt+="\n"
    txt+="# Raw Data #\n"
    txt+="${DATA_DIR}${FILE_SEP}*\n"
    txt+="\n"
    txt+="# Sphinx files #\n"
    txt+="docs/_build/*\n"
    txt+="docs/_static/*\n"
    txt+="docs/_templates/*\n"
    txt+="docs/Makefile\n"

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
    txt+="SRC_DIR=/usr/src/${MAIN_DIR}\n\n\n"
    txt+=".PHONY: docker docs update_requirements\n\n"
    txt+="docker:\n"
    txt+="\t# Python Container\n"
    txt+="\tdocker image build \\\\\n"
    txt+="\t\t--tag python_\$(PROJECT) \\\\\n"
    txt+="\t\t-f docker/python-Dockerfile \\\\\n"
    txt+="\t\t--squash .\n"
    txt+="\t# NGINX Container\n"
    txt+="\tdocker image build \\\\\n"
    txt+="\t\t--tag nginx_\$(PROJECT) \\\\\n"
    txt+="\t\t-f docker/nginx-Dockerfile \\\\\n"
    txt+="\t\t--squash .\n"
    txt+="\t# Postgres Container\n"
    txt+="\t# TODO create postgres-Dockerfile\n"
    txt+="\t#docker image build \\\\\n"
    txt+="\t\t#--tag postgres_\$(PROJECT) \\\\\n"
    txt+="\t\t#-f docker/postgres-Dockerfile \\\\\n"
    txt+="\t\t#--squash .\n"
    txt+="\tdocker system prune -f\n\n"
    txt+="sphinx_quickstart:\n"
    txt+="\tdocker container run \\\\\n"
    txt+="\t\t-it --rm \\\\\n"
    txt+="\t\t-v \$(MOUNT_DIR):/usr/src/\$(PROJECT) \\\\\n"
    txt+="\t\t-w /usr/src/\$(PROJECT)/docs \\\\\n"
    txt+="\t\tpython_\$(PROJECT) \\\\\n"
    txt+="\t\tsphinx-quickstart -q \\\\\n"
    txt+="\t\t\t-p \$(PROJECT) \\\\\n"
    txt+="\t\t\t-a ${AUTHOR} \\\\\n"
    txt+="\t\t\t-v ${PKG_VERSION} \\\\\n"
    txt+="\t\t\t--ext-autodoc \\\\\n"
    txt+="\t\t\t--ext-viewcode \\\\\n"
    txt+="\t\t\t--makefile \\\\\\n"
    txt+="\t\t\t--no-batchfile\n\n"
    txt+="docs:\n"
    txt+="\tdocker container run \\\\\n"
    txt+="\t\t-it --rm \\\\\n"
    txt+="\t\t-v \$(MOUNT_DIR):/usr/src/\$(PROJECT) \\\\\n"
    txt+="\t\t-w /usr/src/\$(PROJECT)/docs \\\\\n"
    txt+="\t\tpython_\$(PROJECT) make html\n"
    txt+="\tdocker container rm -f nginx_\$(PROJECT) || true\n"
    txt+="\tdocker container run \\\\\n"
    txt+="\t\t-d \\\\\n"
    txt+="\t\t-p 80:80 \\\\\n"
    txt+="\t\t-v \$(MOUNT_DIR)/docs/_build/html:/usr/share/nginx/html:ro \\\\\n"
    txt+="\t\t--name nginx_\$(PROJECT) \\\\\n"
    txt+="\t\tnginx_\$(PROJECT)\n\n"
    # TODO update packages
    txt+="update_requirements:\n"
    txt+="\tdocker container run \\\\\n"
    txt+="\t\t--rm \\\\\n"
    txt+="\t\t-v \$(MOUNT_DIR):/usr/src/\$(PROJECT) \\\\\n"
    txt+="\t\tpython_\$(PROJECT) pip freeze > requirements.txt\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}Makefile"
}


manifest() {
    printf %b "include LICENSE.txt" >> "${MAIN_DIR}${FILE_SEP}MANIFEST.in"
}


nginx_conf() {
    txt="user  nginx;\n"
    txt+="worker_processes  1;\n\n"
    txt+="error_log  /var/log/nginx/error.log warn;\n"
    txt+="pid        /var/run/nginx.pid;\n\n\n"
    txt+="events {\n"
    txt+="    worker_connections  1024;\n"
    txt+="}\n\n\n"
    txt+="http {\n"
    txt+="    include       /etc/nginx/mime.types;\n"
    txt+="    default_type  application/octet-stream;\n\n"
    txt+="    log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '\n"
    txt+="                      '\$status \$body_bytes_sent \"\$http_referer\" '\n"
    txt+="                      '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';\n\n"
    txt+="    access_log  /var/log/nginx/access.log  main;\n\n"
    txt+="    sendfile        on;\n"
    txt+="    #tcp_nopush     on;\n\n"
    txt+="    keepalive_timeout  65;\n\n"
    txt+="    #gzip  on;\n\n"
    txt+="    include /etc/nginx/conf.d/*.conf;\n\n"
    txt+="    server {\n"
    txt+="        listen 80 default_server;\n"
    txt+="        listen [::]:80 default_server;\n"
    txt+="        root /usr/share/nginx/html;\n"
    txt+="        index index.html;\n"
    txt+="    }\n\n"
    txt+="}\n\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}${NGINX_DIR}${FILE_SEP}nginx.conf"
}


readme() {
    touch "${MAIN_DIR}${FILE_SEP}README.md"
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
docker_nginx
docker_python
git_attributes
git_config
git_ignore
license
makefile
manifest
nginx_conf
readme
requirements
setup
git_init
