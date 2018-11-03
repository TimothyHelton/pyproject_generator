#! /bin/bash

: "${AUTHOR:=EnterAuthorName}"
: "${EMAIL:=EnterAuthorEmail}"
: "${PYTHON_VERSION:=3.6}"
: "${PKG_VERSION:=0.1.0}"

###############################################################################

MAIN_DIR=${1:?"Specify a package name"}
SOURCE_DIR="${2:-$1}"
: "${DATA_DIR:=data}"
: "${DOCKER_DIR:=docker}"
: "${DOCS_DIR:=docs}"
: "${FILE_SEP:=/}"
: "${NOTEBOOK_DIR:=notebooks}"
: "${TEST_DIR:=tests}"
: "${WHEEL_DIR:=wheels}"

if [[ ${SOURCE_DIR} == *-* ]]; then
    msg="\n\nBy Python convention the source directory name may not contain "
    msg+="hyphens.\n"
    msg+="This script uses the package name (mandatory first argument) for "
    msg+="the source directory name if a second argument is not provided.\n"
    msg+="\npypackage_generator.sh <package_name> <source_directory>\n"
    msg+="\n\nPlease supply a source directory name without hyphens."
    printf %b "${msg}"
    exit 0
fi

YEAR=`date +%Y`

SUB_DIRECTORIES=(${DATA_DIR} \
                 ${DOCKER_DIR} \
                 ${DOCS_DIR} \
                 ${NOTEBOOK_DIR} \
                 ${SOURCE_DIR} \
                 ${WHEEL_DIR})

PY_HEADER+="#! /usr/bin/env python3\n"
PY_HEADER+="# -*- coding: utf-8 -*-\n"

PY_SHEBANG="#! /usr/bin/env python3"
PY_ENCODING="# -*- coding: utf-8 -*-"

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


conftest() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Test Configuration File' \
        '"""' \
        "import pytest" \
        "" \
        > "${SRC_PATH}${FILE_SEP}${TEST_DIR}${FILE_SEP}conftest.py"
}


constructor_pkg() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        "from pkg_resources import get_distribution, DistributionNotFound" \
        "import os.path as osp" \
        "" \
        "# from . import cli" \
        "# from . import EnterModuleNameHere" \
        "" \
        "__version__ = '0.1.0'" \
        "" \
        "try:" \
        "    _dist = get_distribution('${MAIN_DIR}')" \
        "    dist_loc = osp.normcase(_dist.location)" \
        "    here = osp.normcase(__file__)" \
        "    if not here.startswith(osp.join(dist_loc, '${MAIN_DIR}')):" \
        "        raise DistributionNotFound" \
        "except DistributionNotFound:" \
        "    __version__ = 'Please install this project with setup.py'" \
        "else:" \
        "    __version__ = _dist.version" \
        > "${SRC_PATH}__init__.py"
}


constructor_test() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        > "${SRC_PATH}${FILE_SEP}${TEST_DIR}${FILE_SEP}__init__.py"
}


docker_compose() {
    printf "%s\n" \
        "version: '3'" \
        "" \
        "services:" \
        "" \
        "  nginx:" \
        "    container_name: ${MAIN_DIR}_nginx" \
        "    image: nginx:alpine" \
        "    ports:" \
        "      - 8080:80" \
        "    restart: always" \
        "    volumes:" \
        "      - ../docs/_build/html:/usr/share/nginx/html:ro" \
        "" \
        "  postgres:" \
        "    container_name: ${MAIN_DIR}_postgres" \
        "    image: postgres:alpine" \
        "    environment:" \
        "      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}" \
        "      POSTGRES_DB: \${POSTGRES_DB}" \
        "      POSTGRES_USER: \${POSTGRES_USER}" \
        "    ports:" \
        "      - 5432:5432" \
        "    restart: always" \
        "    volumes:" \
        "      - ${MAIN_DIR}-db:/var/lib/postgresql/data" \
        "" \
        "  pgadmin:" \
        "    container_name: ${MAIN_DIR}_pgadmin" \
        "    image: dpage/pgadmin4" \
        "    environment:" \
        "      PGADMIN_DEFAULT_EMAIL: \${PGADMIN_DEFAULT_EMAIL}" \
        "      PGADMIN_DEFAULT_PASSWORD: \${PGADMIN_DEFAULT_PASSWORD}" \
        "    external_links:" \
        "      - ${MAIN_DIR}_postgres:${MAIN_DIR}_postgres" \
        "    ports:" \
        "      - 5000:80" \
        "" \
        "  python:" \
        "    container_name: ${MAIN_DIR}_python" \
        "    build:" \
        "      context: .." \
        "      dockerfile: docker/python-Dockerfile" \
        "    image: ${MAIN_DIR}_python" \
        "    restart: always" \
        "    tty: true" \
        "    volumes:" \
        "      - ..:/usr/src/${MAIN_DIR}" \
        "" \
        "volumes:" \
        "  ${MAIN_DIR}-db:" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}docker-compose.yml"
}


docker_python() {
    txt="FROM python:3.6-alpine\n"
    txt+="\nWORKDIR /usr/src/${MAIN_DIR}\n"
    txt+="\nCOPY . .\n"
    txt+="\nRUN apk add --update \\\\\n"
    txt+="\t\talpine-sdk \\\\\n"
    txt+="\t\tbash \\\\\n"
    txt+="\t&& pip3 install --upgrade pip \\\\\n"
    txt+="\t&& pip3 install --no-cache-dir -r requirements.txt \\\\\n"
    txt+="\t&& pip3 install -e .[docs,notebook,test]\n"
    txt+="\nCMD [ \"/bin/bash\" ]\n"
    txt+="\n"

    printf %b "${txt}" > "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}python-Dockerfile"
}


docker_tensorflow() {
    txt="FROM python:3.6\n"

    txt+="\nWORKDIR /usr/src/${MAIN_DIR}\n"

    txt+="\nCOPY . .\n"

    txt+="\nRUN cd /opt \\\\\n"
    txt+="\t&& apt-get update \\\\\n"
    txt+="\t&& apt-get install -y \\\\\n"
    txt+="\t\tprotobuf-compiler \\\\\n"
    txt+="\t&& rm -rf /var/lib/apt/lists/* \\\\\n"
    txt+="\t&& git clone \\\\\n"
    txt+="\t\t--branch master \\\\\n"
    txt+="\t\t--single-branch \\\\\\n"
    txt+="\t\t--depth 1 \\\\\\n"
    txt+="\t\thttps://github.com/tensorflow/models.git \\\\\n"
    txt+="\t&& cd /opt/models/research \\\\\n"
    txt+="\t&& protoc object_detection/protos/*.proto --python_out=. \\\\\n"
    txt+="\t&& cd /usr/src/${MAIN_DIR} \\\\\n"
    txt+="\t&& pip install --upgrade pip \\\\\n"
    txt+="\t&& pip install --no-cache-dir -r requirements.txt \\\\\n"
    txt+="\t&& pip install -e .[docs,notebook,tf-cpu,test]\n"

    txt+="\nENV PYTHONPATH \$PYTHONPATH:/opt/models/research:/opt/models/research/slim:/opt/models/research/object_detection\n"

    txt+="\nCMD [ \"/bin/bash\" ]\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}tensorflow-Dockerfile"
}


envfile(){
    printf "%s\n" \
        "# PGAdmin" \
        "export PGADMIN_DEFAULT_EMAIL=enter_user@${MAIN_DIR}.com" \
        "export PGADMIN_DEFAULT_PASSWORD=enter_password" \
        "" \
        "# Postgres" \
        "export POSTGRES_PASSWORD=enter_password" \
        "export POSTGRES_DB=${MAIN_DIR}" \
        "export POSTGRES_USER=enter_user" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}envfile"
}


git_attributes() {
    printf "%s\n" \
        "*.ipynb    filter=jupyter_clear_output" \
        > "${MAIN_DIR}${FILE_SEP}.gitattributes"
}


git_config() {
    # Setup Git to ignore Jupyter Notebook Outputs
    printf "%s\n" \
        "[filter \"jupyter_clear_output\"]" \
        "    clean = \"jupyter nbconvert --stdin --stdout \ " \
        "             --log-level=ERROR --to notebook \ " \
        "             --ClearOutputPreprocessor.enabled=True\"" \
        "    smudge = cat" \
        "    required = true" \
        > "${MAIN_DIR}${FILE_SEP}.gitconfig"
}


git_ignore() {
    printf "%s\n" \
        "# Compiled source" \
        "build${FILE_SEP}*" \
        "*.com" \
        "dist${FILE_SEP}*" \
        "*.egg-info${FILE_SEP}*" \
        "*.class" \
        "*.dll" \
        "*.exe" \
        "*.o" \
        "*.pdf" \
        "*.pyc" \
        "*.so" \
        "" \
        "# Ipython Files" \
        "${NOTEBOOK_DIR}${FILE_SEP}.ipynb_checkpoints${FILE_SEP}*" \
        "" \
        "# Logs and databases" \
        "*.log" \
        "*make.bat" \
        "*.sql" \
        "*.sqlite" \
        "" \
        "# OS generated files" \
        "envfile" \
        ".DS_Store" \
        ".DS_store?" \
        "._*" \
        ".Spotlight-V100" \
        ".Trashes" \
        "ehthumbs.db" \
        "Thumbs.db" \
        "" \
        "# Packages" \
        "*.7z" \
        "*.dmg" \
        "*.gz" \
        "*.iso" \
        "*.jar" \
        "*.rar" \
        "*.tar" \
        "*.zip" \
        "" \
        "# Profile files" \
        "*.coverage" \
        "*.profile" \
        "" \
        "# Project files" \
        "source_venv.sh" \
        "*wheels" \
        "" \
        "# PyCharm files" \
        ".idea${FILE_SEP}*" \
        "${MAIN_DIR}${FILE_SEP}.idea${FILE_SEP}*" \
        "" \
        "# pytest files" \
        ".cache${FILE_SEP}*" \
        "" \
        "# Raw Data" \
        "${DATA_DIR}${FILE_SEP}*" \
        "" \
        "# Sphinx files" \
        "docs/_build/*" \
        "docs/_static/*" \
        "docs/_templates/*" \
        "docs/Makefile" \
        > "${MAIN_DIR}${FILE_SEP}.gitignore"
}


git_init() {
    cd ${MAIN_DIR}
    git init
    git add --all
    git commit -m "Initial Commit"
}


license() {
    printf "%s\n" \
        "Copyright (c) ${YEAR}, ${AUTHOR}." \
        "All rights reserved." \
        "" \
        "Redistribution and use in source and binary forms, with or without" \
        "modification, are permitted provided that the following conditions are met:" \
        "" \
        "* Redistributions of source code must retain the above copyright notice, this" \
        "  list of conditions and the following disclaimer." \
        "" \
        "* Redistributions in binary form must reproduce the above copyright notice," \
        "  this list of conditions and the following disclaimer in the documentation" \
        "  and/or other materials provided with the distribution." \
        "" \
        "* Neither the name of the ${MAIN_DIR} Developers nor the names of any" \
        "  contributors may be used to endorse or promote products derived from this" \
        "  software without specific prior written permission." \
        "" \
        "THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"" \
        "AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE" \
        "IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE" \
        "DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR" \
        "ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES" \
        "(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;" \
        "LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON" \
        "ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT" \
        "(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS" \
        "SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE." \
        > "${MAIN_DIR}${FILE_SEP}LICENSE.txt"
}


makefile() {
    txt="PROJECT=${MAIN_DIR}\n"
    txt+="ifeq (\"\$(shell uname -s)\", \"Linux*\")\n"
    txt+="\tBROWSER=/usr/bin/firefox\n"
    txt+="else\n"
    txt+="\tBROWSER=open\n"
    txt+="endif\n"
    txt+="MOUNT_DIR=\$(shell pwd)\n"
    txt+="MODELS=/opt/models\n"
    txt+="PORT:=\$(shell awk -v min=16384 -v max=32768 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')\n"
    txt+="SRC_DIR=/usr/src/${SOURCE_DIR}\n"
    txt+="USER=\$(shell echo \$\${USER%%@*})\n"
    txt+="VERSION=\$(shell echo \$(shell cat ${SOURCE_DIR}/__init__.py | \\\\\n"
    txt+="\t\t\tgrep \"^__version__\" | \\\\\n"
    txt+="\t\t\tcut -d = -f 2))\n"

    txt+="\ninclude envfile\n"
    txt+=".PHONY: docs upgrade-packages\n"

    txt+="\ndeploy: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\tpip3 wheel --wheel-dir=wheels .\n"
    txt+="\tgit tag -a v\$(VERSION) -m \"Version \$(VERSION)\"\n"
    txt+="\t@echo\n"
    txt+="\t@echo\n"
    txt+="\t@echo Enter the following to push this tag to the repository:\n"
    txt+="\t@echo git push origin v\$(VERSION)\n"

    txt+="\ndocker-down:\n"
    txt+="\tdocker-compose -f docker/docker-compose.yml down\n"

    txt+="\ndocker-rebuild: setup.py\n"
    txt+="\tdocker-compose -f docker/docker-compose.yml up -d --build\n"

    txt+="\ndocker-up:\n"
    txt+="\tdocker-compose -f docker/docker-compose.yml up -d\n"

    txt+="\ndocs: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \"pip install -e . && cd docs && make html\"\n"
    txt+="\t\${BROWSER} http://localhost:8080\n\n"

    txt+="\ndocs-init: docker-up\n"
    txt+="\trm -rf docs/*\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \\\\\n"
    txt+="\t\t\t\"cd docs \\\\\n"
    txt+="\t\t\t && sphinx-quickstart -q \\\\\n"
    txt+="\t\t\t\t-p \$(PROJECT) \\\\\n"
    txt+="\t\t\t\t-a \"${AUTHOR}\" \\\\\n"
    txt+="\t\t\t\t-v \$(VERSION) \\\\\n"
    txt+="\t\t\t\t--ext-autodoc \\\\\n"
    txt+="\t\t\t\t--ext-viewcode \\\\\n"
    txt+="\t\t\t\t--makefile \\\\\\n"
    txt+="\t\t\t\t--no-batchfile\"\n"
    txt+="\tdocker-compose -f docker/docker-compose.yml restart nginx\n"
    txt+="ifeq (\"\$(shell git remote)\", \"origin\")\n"
    txt+="\tgit fetch\n"
    txt+="\tgit checkout origin/master -- docs/\n"
    txt+="else\n"
    txt+="\tdocker container run --rm \\\\\n"
    txt+="\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\\n"
    txt+="\t\t-w /usr/src/\$(PROJECT)/docs \\\\\n"
    txt+="\t\tubuntu \\\\\n"
    txt+="\t\t/bin/bash -c \\\\\n"
    txt+="\t\t\t\"sed -i -e 's/# import os/import os/g' conf.py \\\\\n"
    txt+="\t\t\t && sed -i -e 's/# import sys/import sys/g' conf.py \\\\\n"
    txt+="\t\t\t && sed -i \\\\\"/# sys.path.insert(0, os.path.abspath('.'))/d\\\\\" \\\\\n"
    txt+="\t\t\t\tconf.py \\\\\n"
    txt+="\t\t\t && sed -i -e \\\\\"/import sys/a \\\\\n"
    txt+="\t\t\t\tsys.path.insert(0, os.path.abspath('../${SOURCE_DIR}')) \\\\\n"
    txt+="\t\t\t\t\\\\n\\\\nfrom ${SOURCE_DIR} import __version__\\\\\" \\\\\n"
    txt+="\t\t\t\tconf.py \\\\\n"
    txt+="\t\t\t && sed -i -e \\\\\"s/version = '0.1.0'/version = __version__/g\\\\\" \\\\\n"
    txt+="\t\t\t\tconf.py \\\\\n"
    txt+="\t\t\t && sed -i -e \\\\\"s/release = '0.1.0'/release = __version__/g\\\\\" \\\\\n"
    txt+="\t\t\t\tconf.py \\\\\n"
    txt+="\t\t\t && sed -i -e \\\\\"s/alabaster/sphinx_rtd_theme/g\\\\\" \\\\\n"
    txt+="\t\t\t\tconf.py \\\\\n"
    txt+="\t\t\t && sed -i \\\\\"/   :caption: Contents:/a \\\\\n"
    txt+="\t\t\t\t\\\\\\\\\\\\\\\\\\\\n   package\\\\\" \\\\\n"
    txt+="\t\t\t\tindex.rst\"\n"

    txt+="\tprintf \"%s\\\\n\" \\\\\n"
    txt+="\t\t\"Package Modules\" \\\\\n"
    txt+="\t\t\"===============\" \\\\\n"
    txt+="\t\t\"\" \\\\\n"
    txt+="\t\t\".. toctree::\" \\\\\n"
    txt+="\t\t\"    :maxdepth: 2\" \\\\\n"
    txt+="\t\t\"\" \\\\\n"
    txt+="\t\t\"cli\" \\\\\n"
    txt+="\t\t\"---\" \\\\\n"
    txt+="\t\t\".. automodule:: cli\" \\\\\n"
    txt+="\t\t\"    :members:\" \\\\\n"
    txt+="\t\t\"    :show-inheritance:\" \\\\\n"
    txt+="\t\t\"    :synopsis: Package commandline interface calls.\" \\\\\n"
    txt+="\t\t\"\" \\\\\n"
    txt+="\t> \"docs/package.rst\"\n"

    txt+="endif\n"

    txt+="\ndocs-view: docker-up\n"
    txt+="\t\${BROWSER} http://localhost:8080\n"

    txt+="\nipython: docker-up\n"
    txt+="\tdocker container exec -it \$(PROJECT)_python ipython\n"

    txt+="\nnotebook: notebook-server\n"
    txt+="\tsleep 0.5\n"
    txt+="\t\${BROWSER} \$\$(docker container exec \\\\\n"
    txt+="\t\t\$(USER)_notebook_\$(PORT) \\\\\n"
    txt+="\t\tjupyter notebook list | grep -o '^http\S*')\n"

    txt+="\nnotebook-remove:\n"
    txt+="\tdocker container rm -f \$\$(docker container ls -f name=\$(USER)_notebook -q)\n"

    txt+="\nnotebook-server:\n"
    txt+="\tdocker container run -d --rm \\\\\n"
    txt+="\t\t--name \$(USER)_notebook_\$(PORT) \\\\\n"
    txt+="\t\t-p \$(PORT):\$(PORT) \\\\\n"
    txt+="\t\t\$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \"jupyter notebook \\\\\n"
    txt+="\t\t\t\t--allow-root \\\\\n"
    txt+="\t\t\t\t--ip=0.0.0.0 \\\\\n"
    txt+="\t\t\t\t--port=\$(PORT)\"\n"

    txt+="\npgadmin: docker-up\n"
    txt+="\t\${BROWSER} http://localhost:5000\n"

    txt+="\npsql: docker-up\n"
    txt+="\tdocker container exec -it \$(PROJECT)_postgres \\\\\n"
    txt+="\t\tpsql -U \${POSTGRES_USER} \$(PROJECT)\n"

    txt+="\ntensorflow:\n"
    txt+="\tdocker container run --rm \\\\\n"
    txt+="\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\\n"
    txt+="\t\t-w /usr/src/\$(PROJECT) \\\\\n"
    txt+="\t\tubuntu \\\\\n"
    txt+="\t\t/bin/bash -c \\\\\n"
    txt+="\t\t\t\"sed -i -e 's/python-Dockerfile/tensorflow-Dockerfile/g' \\\\\n"
    txt+="\t\t\t\tdocker/docker-compose.yml \\\\\n"
    txt+="\t\t\t && sed -i -e \\\\\"/'notebook': \['jupyter'\],/a \\\\\n"
    txt+="\t\t\t\t\\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ 'tf-cpu': ['tensorflow'],\\\\\n"
    txt+="\t\t\t\t\\\\n\\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ 'tf-gpu': ['tensorflow-gpu'],\\\\\" \\\\\n"
    txt+="\t\t\t\tsetup.py\"\n"

    txt+="\ntensorflow-models: tensorflow docker-rebuild\n"
    txt+="ifneq (\$(wildcard \${MODELS}), )\n"
    txt+="\techo \"Updating TensorFlow Models Repository\"\n"
    txt+="\tcd \${MODELS} \\\\\n"
    txt+="\t&& git checkout master \\\\\n"
    txt+="\t&& git pull\n"
    txt+="\tcd \${MOUNT_DIR}\n"
    txt+="else\n"
    txt+="\techo \"Cloning TensorFlow Models Repository to \${MODELS}\"\n"
    txt+="\tmkdir -p \${MODELS}\n"
    txt+="\tgit clone https://github.com/tensorflow/models.git \${MODELS}\n"
    txt+="endif\n"

    txt+="\ntest: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \"py.test\\\\\n"
    txt+="\t\t\t\t--basetemp=pytest \\\\\n"
    txt+="\t\t\t\t--doctest-modules \\\\\n"
    txt+="\t\t\t\t--ff \\\\\n"
    txt+="\t\t\t\t--pep8 \\\\\n"
    txt+="\t\t\t\t-r all \\\\\n"
    txt+="\t\t\t\t-vvv\"\n"

    txt+="\nupgrade-packages: docker-up\n"
    txt+="\tdocker container exec \$(PROJECT)_python \\\\\n"
    txt+="\t\t/bin/bash -c \\\\\n"
    txt+="\t\t\t\"pip3 install -U pip \\\\\n"
    txt+="\t\t\t && pip3 freeze | \\\\\n"
    txt+="\t\t\t\tgrep -v \$(PROJECT) | \\\\\n"
    txt+="\t\t\t\tcut -d = -f 1 > requirements.txt \\\\\n"
    txt+="\t\t\t && pip3 install -U -r requirements.txt \\\\\n"
    txt+="\t\t\t && pip3 freeze > requirements.txt \\\\\n"
    txt+="\t\t\t && sed -i -e '/^-e/d' requirements.txt\"\n"

    printf %b "${txt}" >> "${MAIN_DIR}${FILE_SEP}Makefile"
}


manifest() {
    printf "%s\n" \
        "include LICENSE.txt" \
        > "${MAIN_DIR}${FILE_SEP}MANIFEST.in"
}


readme() {
    printf "%s\n" \
        "# PGAdmin Setup" \
        "1. From the main directory call \`make pgadmin\`" \
        "    - The default browser will open to \`localhost:5000\`" \
        "1. Enter the **PGAdmin** default user and password." \
        "    - These variable are set in the \`envfile\`." \
        "1. Click \`Add New Server\`." \
        "    - General Name: Enter the <project_name>" \
        "    - Connection Host: Enter <project_name>_postgres" \
        "    - Connection Username and Password: Enter **Postgres** username and password" \
        "      from the \`envfile\`." \
        "" \
        > "${MAIN_DIR}${FILE_SEP}README.md"
}


requirements() {
    touch "${MAIN_DIR}${FILE_SEP}requirements.txt"
}


setup() {
    printf "%s\n" \
        "#!/usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        "" \
        "from codecs import open" \
        "import os.path as osp" \
        "import re" \
        "" \
        "from setuptools import setup, find_packages" \
        "" \
        "" \
        "with open('${SOURCE_DIR}${FILE_SEP}__init__.py', 'r') as fd:" \
        "    version = re.search(r'^__version__\s*=\s*[\'\"]([^\'\"]*)[\'\"]'," \
        "                        fd.read(), re.MULTILINE).group(1)" \
        "" \
        "here = osp.abspath(osp.dirname(__file__))" \
        "with open(osp.join(here, 'README.md'), encoding='utf-8') as f:" \
        "    long_description = f.read()" \
        "" \
        "setup(" \
        "    name='${MAIN_DIR}'," \
        "    version=version," \
        "    description='Modules related to EnterDescriptionHere'," \
        "    author='${AUTHOR}'," \
        "    author_email='${EMAIL}'," \
        "    license='BSD'," \
        "    classifiers=[" \
        "        'Development Status :: 1 - Planning'," \
        "        'Environment :: Console'," \
        "        'Intended Audience :: Developers'," \
        "        'License :: OSI Approved'," \
        "        'Natural Language :: English'," \
        "        'Operating System :: OS Independent'," \
        "        'Programming Language :: Python :: ${PYTHON_VERSION%%.*}'," \
        "        'Programming Language :: Python :: ${PYTHON_VERSION}'," \
        "        'Topic :: Software Development :: Build Tools'," \
        "        ]," \
        "    keywords='EnterKeywordsHere'," \
        "    packages=find_packages(exclude=[" \
        "        'data'," \
        "        'docker'," \
        "        'docs'," \
        "        'notebooks'," \
        "        'wheels'," \
        "        '*tests'," \
        "        ]" \
        "    )," \
        "    install_requires=[" \
        "        ]," \
        "    extras_require={" \
        "        'docs': ['sphinx', 'sphinx_rtd_theme']," \
        "        'notebook': ['jupyter']," \
        "        'test': ['pytest', 'pytest-pep8']," \
        "    }," \
        "    package_dir={'${MAIN_DIR}': '${SOURCE_DIR}'}," \
        "    include_package_data=True," \
        "    entry_points={" \
        "        'console_scripts': [" \
        "            # '<EnterCommandName>=${SOURCE_DIR}.cli:<EnterFunction>'," \
        "        ]" \
        "    }" \
        ")" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${MAIN_DIR}${FILE_SEP}setup.py"
}


directories
conftest
constructor_pkg
constructor_test
docker_compose
docker_python
docker_tensorflow
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
