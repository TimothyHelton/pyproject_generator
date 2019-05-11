#! /bin/bash

: "${AUTHOR:=EnterAuthorName}"
: "${EMAIL:=EnterAuthorEmail}"
: "${PYTHON_VERSION:=3.7}"
: "${PKG_VERSION:=0.1.0}"

###############################################################################

MAIN_DIR=${1:?"Specify a package name"}
SOURCE_DIR="${2:-$1}"
: "${DATA_DIR:=data}"
: "${DOCKER_DIR:=docker}"
: "${DOCS_DIR:=docs}"
: "${FILE_SEP:=/}"
: "${NODEJS_VERSION:=11}"
: "${NOTEBOOK_DIR:=notebooks}"
: "${PROFILE_DIR:=profiles}"
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
                 ${PROFILE_DIR} \
                 ${SOURCE_DIR} \
                 ${WHEEL_DIR})

PY_SHEBANG="#! /usr/bin/env python3"
PY_ENCODING="# -*- coding: utf-8 -*-"

SRC_PATH="${MAIN_DIR}${FILE_SEP}${SOURCE_DIR}${FILE_SEP}"


cli() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        '""" Commandline Interface Module' \
        "" \
        '"""' \
        "import logging" \
        "import time" \
        "" \
        "import click" \
        "" \
        "" \
        "@click.command()" \
        "@click.argument('number')" \
        "@click.option('-q', '--quiet', is_flag=True, multiple=True," \
        "              help='Decrease output level one (-q) or multiple times (-qqq).')" \
        "@click.option('-v', '--verbose', is_flag=True, multiple=True," \
        "              help='Increase output level one (-v) or multiple times (-vvv).')" \
        "def count(number: int, quiet, verbose):" \
        '    """' \
        "    Display progressbar while counting to the user provided integer NUMBER." \
        '    """' \
        "    click.clear()" \
        "    logging_level = logging.INFO + 10 * len(quiet) - 10 * len(verbose)" \
        "    logging.basicConfig(level=logging_level)" \
        "    with click.progressbar(range(int(number)), label='Counting') as bar:" \
        "        for n in bar:" \
        "            click.secho(f'\n\nProcessing: {n}', fg='green')" \
        "            time.sleep(0.5)" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        "" \
        > "${SRC_PATH}${FILE_SEP}cli.py"
}


common_image() {
    printf "%s\n" \
        "\t&& curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \\\\" \
        "\t&& apt-get update -y \\\\" \
        "\t&& apt-get upgrade -y \\\\" \
        "\t&& apt-get install -y apt-utils \\\\" \
        "\t&& apt-get install -y nodejs \\\\" \
        "\t&& jupyter labextension install jupyterlab-drawio \\\\" \
        "\t&& jupyter labextension install @mflevine/jupyterlab_html \\\\" \
        "\t&& jupyter labextension install @jupyterlab/plotly-extension \\\\" \
        "\t&& jupyter labextension install @jupyterlab/toc \\\\" \
        "\t&& apt-get clean"
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
        "from os import path" \
        "" \
        "from . import globals" \
        "# from . import cli" \
        "# from . import db" \
        "from . import exceptions" \
        "# from . import utils" \
        "" \
        "__version__ = '0.1.0'" \
        "" \
        "try:" \
        "    _dist = get_distribution('${MAIN_DIR}')" \
        "    dist_loc = path.normcase(_dist.location)" \
        "    here = path.normcase(__file__)" \
        "    if not here.startswith(path.join(dist_loc, '${MAIN_DIR}')):" \
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


db() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        '""" Database Module' \
        "" \
        '"""' \
        "import os" \
        "" \
        "import pandas as pd" \
        "import sqlalchemy as sa" \
        "from sqlalchemy.sql import select" \
        "" \
        "from ${MAIN_DIR}.utils import logger_setup, project_vars" \
        "" \
        "" \
        "logger = logger_setup()" \
        "" \
        "" \
        "class Connect:" \
        '    """' \
        "    Database Connection Class" \
        "" \
        "    :Attributes:" \
        "" \
        "    - **conn**: *Connection* SQLAlchemy connection object" \
        "    - **db_name**: *str* database name" \
        "    - **dialect**: *str* SQLAlchemy dialect" \
        "    - **driver**: *str* SQLAlchemy driver \\" \
        "        (if None the default value will be used)" \
        "    - **engine**: *Engine* SQLAlchemy engine object" \
        "    - **host**: *str* database host" \
        "    - **meta**: *MetaData* A collection of *Table* objects and their \\" \
        "        associated child objects" \
        "    - **password**: *str* database password" \
        "    - **port**: *int* database port" \
        "    - **tables**: *list* tables in database" \
        "    - **user**: *str* username" \
        '    """' \
        "    def __init__(self):" \
        "        project_vars()" \
        "        self.dialect = 'postgresql'" \
        "        self.driver = None" \
        "        self.db_name = os.environ['POSTGRES_DB']" \
        "        self.host = '${MAIN_DIR}_postgres'" \
        "        self.meta = sa.MetaData()" \
        "        self.password = os.environ['POSTGRES_PASSWORD']" \
        "        self.port = 5432" \
        "        self.user = os.environ['POSTGRES_USER']" \
        "" \
        "        self.dialect = (f'{self.dialect}+{self.driver}' if self.driver" \
        "                        else self.dialect)" \
        "        self.engine = sa.create_engine(" \
        "            f'{self.dialect}://{self.user}:{self.password}'" \
        "            f'@{self.host}:{self.port}/{self.db_name}'" \
        "        )" \
        "        self.conn = self.engine.connect()" \
        "        self.tables = self.engine.table_names()" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return (f'<{type(self).__name__}('" \
        "                f'user={os.environ[\"POSTGRES_USER\"]}, '" \
        "                f'database={os.environ[\"POSTGRES_DB\"]}'" \
        "                f')')" \
        "" \
        "" \
        "class User(Connect):" \
        '    """' \
        "    User Tables" \
        "" \
        "    :Attributes:" \
        "" \
        "    - **df**: *DataFrame* table with all user data" \
        "    - **user_df**: *DataFrame* table with base user information" \
        "    - **pref_df**: *DataFrame* table with user preferences" \
        '    """' \
        "    def __init__(self):" \
        "        super(User, self).__init__()" \
        "        self._user = sa.Table(" \
        "            'user', self.meta," \
        "            sa.Column('user_id', sa.Integer, primary_key=True)," \
        "            sa.Column('User_name', sa.String(16), nullable=False)," \
        "            sa.Column('email_address', sa.String(60), key='email')," \
        "            sa.Column('password', sa.String(20), nullable=False)" \
        "        )" \
        "        self._pref = sa.Table(" \
        "            'user_pref', self.meta," \
        "            sa.Column('pref_id', sa.Integer, primary_key=True)," \
        "            sa.Column('user_id', sa.Integer, sa.ForeignKey(\"user.user_id\")," \
        "                      nullable=False)," \
        "            sa.Column('pref_name', sa.String(40), nullable=False)," \
        "            sa.Column('pref_value', sa.String(100))" \
        "        )" \
        "        self.meta.create_all(self.engine)" \
        "        " \
        "        self._user_df = pd.read_sql(select([self._user]), self.engine)" \
        "        self._pref_df = pd.read_sql(select([self._pref]), self.engine)" \
        "" \
        "    @property" \
        "    def df(self):" \
        "        return pd.merge(self._user_df, self._pref_df, on='user_id')" \
        "" \
        "    @property" \
        "    def pref_df(self):" \
        "        return self._pref_df" \
        "" \
        "    @property" \
        "    def user_df(self):" \
        "        return self._user_df" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${SRC_PATH}${FILE_SEP}db.py"
}


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


docker_compose() {
    printf "%s\n" \
        "version: '3.7'" \
        "" \
        "services:" \
        "" \
        "  nginx:" \
        "    container_name: ${MAIN_DIR}_nginx" \
        "    image: nginx:alpine" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
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
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 5432:5432" \
        "    restart: always" \
        "    volumes:" \
        "      - ${MAIN_DIR}-db:/var/lib/postgresql/data" \
        "" \
        "  pgadmin:" \
        "    container_name: ${MAIN_DIR}_pgadmin" \
        "    image: dpage/pgadmin4" \
        "    depends_on:" \
        "      - postgres" \
        "    environment:" \
        "      PGADMIN_DEFAULT_EMAIL: \${PGADMIN_DEFAULT_EMAIL}" \
        "      PGADMIN_DEFAULT_PASSWORD: \${PGADMIN_DEFAULT_PASSWORD}" \
        "    external_links:" \
        "      - ${MAIN_DIR}_postgres:${MAIN_DIR}_postgres" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 5000:80" \
        "" \
        "  python:" \
        "    container_name: ${MAIN_DIR}_python" \
        "    build:" \
        "      context: .." \
        "      dockerfile: docker/python-Dockerfile" \
        "    depends_on:" \
        "      - postgres" \
        "    image: ${MAIN_DIR}_python" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 8888:8080" \
        "    restart: always" \
        "    tty: true" \
        "    volumes:" \
        "      - ..:/usr/src/${MAIN_DIR}" \
        "" \
        "networks:" \
        "  ${MAIN_DIR}-network:" \
        "    name: ${MAIN_DIR}" \
        "" \
        "volumes:" \
        "  ${MAIN_DIR}-db:" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}docker-compose.yml"
}


docker_python() {
    printf "%b\n" \
        "FROM python:latest" \
        "" \
        "WORKDIR /usr/src/${MAIN_DIR}" \
        "" \
        "COPY . ." \
        "" \
        "RUN pip3 install --upgrade pip \\\\" \
        "\t&& pip3 install --no-cache-dir -r requirements.txt \\\\" \
        "\t&& pip3 install -e .[build,data,database,docs,notebook,profile,test] \\\\" \
        "$(common_image)" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}python-Dockerfile"
}


docker_pytorch() {
    printf "%b\n" \
        "FROM continuumio/anaconda3" \
        "" \
        "WORKDIR /usr/src/${MAIN_DIR}" \
        "" \
        "COPY . ." \
        "" \
        "RUN conda update -y conda \\\\" \
        "\t&& conda update -y --all \\\\" \
        "\t&& while read requirement; do conda install --yes \${requirement}; done < requirements.txt \\\\" \
        "\t&& conda install -y pytorch torchvision -c pytorch \\\\" \
        "\t&& pip install -e .[build,data,database,docs,notebook,profile,test] \\\\" \
        "$(common_image)" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}pytorch-Dockerfile"
}


docker_tensorflow() {
    printf "%b\n" \
        "FROM python:3.6" \
        "" \
        "WORKDIR /usr/src/${MAIN_DIR}" \
        "" \
        "COPY . ." \
        "" \
        "RUN cd /opt \\\\" \
        "\t&& apt-get update \\\\" \
        "\t&& apt-get install -y \\\\" \
        "\t\tprotobuf-compiler \\\\" \
        "\t&& rm -rf /var/lib/apt/lists/* \\\\" \
        "\t&& git clone \\\\" \
        "\t\t--branch master \\\\" \
        "\t\t--single-branch \\\\" \
        "\t\t--depth 1 \\\\" \
        "\t\thttps://github.com/tensorflow/models.git \\\\" \
        "\t&& cd /opt/models/research \\\\" \
        "\t&& protoc object_detection/protos/*.proto --python_out=. \\\\" \
        "\t&& cd /usr/src/${MAIN_DIR} \\\\" \
        "\t&& pip install --upgrade pip \\\\" \
        "\t&& pip install --no-cache-dir -r requirements.txt \\\\" \
        "\t&& pip install -e .[build,data,database,docs,notebook,profile,test,tf-cpu]\\\\" \
        "$(common_image)" \
        "" \
        "ENV PYTHONPATH \$PYTHONPATH:/opt/models/research:/opt/models/research/slim:/opt/models/research/object_detection" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        > "${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}tensorflow-Dockerfile"
}


envfile() {
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
    cp "${MAIN_DIR}${FILE_SEP}envfile" "${MAIN_DIR}${FILE_SEP}envfile_template"
}


exceptions() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        '""" Exception Module' \
        "" \
        '"""' \
        "" \
        "" \
        "class Error(Exception):" \
        '    """Base class for package exceptions.' \
        "" \
        "    :Attributes:"\
        "" \
        "    - **expression**: *str* input expression in which the error occurred" \
        "    - **message**: *str* explanation of the error" \
        '    """' \
        "" \
        "    def __init__(self, expression: str, message: str):" \
        "        self.expression = expression" \
        "        self.message = message" \
        "" \
        "" \
        "class InputError(Error):" \
        '    """Exception raised for errors in the input."""' \
        "" \
        > "${SRC_PATH}${FILE_SEP}exceptions.py"
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
        ".ipynb_checkpoints" \
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


globals() {
    printf "%s\n" \
            "${PY_SHEBANG}" \
            "${PY_ENCODING}" \
            "" \
            '""" Global Variable Module' \
            "" \
            '"""' \
            "from pathlib import Path" \
            "" \
            "" \
            "PACKAGE_ROOT = Path(__file__).parents[1]" \
            "LOGGER_CONFIG = (PACKAGE_ROOT / 'logger_config.yaml').resolve()" \
            "" \
            "" \
            "if __name__ == '__main__':" \
            "    pass" \
            "" \
            > "${SRC_PATH}${FILE_SEP}globals.py"
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


logger_config() {
    printf "%s\n" \
        "version: 1" \
        "disable_existing_loggers: False" \
        "formatters:" \
        "   console:" \
        "       format: '%(levelname)s - %(name)s -> Line: %(lineno)d <- %(message)s'" \
        "   file:" \
        "       format: '%(asctime)s - %(levelname)s - %(module)s.py -> Line: %(lineno)d <- %(message)s'" \
        "handlers:" \
        "   console:" \
        "       class: logging.StreamHandler" \
        "       level: WARNING" \
        "       formatter: console" \
        "       stream: ext://sys.stdout" \
        "   file:" \
        "       class: logging.handlers.RotatingFileHandler" \
        "       encoding: utf8" \
        "       level: DEBUG" \
        "       filename: info.log" \
        "       formatter: file" \
        "       mode: w" \
        "loggers:" \
        "   package:" \
        "       level: INFO" \
        "       handlers: [console, file]" \
        "       propagate: False" \
        "root:" \
        "   level: DEBUG" \
        "   handlers: [console]" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}logger_config.yaml"
}


makefile() {
    printf "%b\n" \
        "PROJECT=${MAIN_DIR}" \
        "ifeq (\"\$(shell uname -s)\", \"Linux*\")" \
        "\tBROWSER=/usr/bin/firefox" \
        "else" \
        "\tBROWSER=open" \
        "endif" \
        "MOUNT_DIR=\$(shell pwd)" \
        "MODELS=/opt/models" \
        "PKG_MANAGER=pip" \
        "PORT:=\$(shell awk -v min=16384 -v max=32768 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')" \
        "NOTEBOOK_NAME=\$(USER)_notebook_\$(PORT)" \
        "SRC_DIR=/usr/src/${SOURCE_DIR}" \
        "USER=\$(shell echo \$\${USER%%@*})" \
        "VERSION=\$(shell echo \$(shell cat ${SOURCE_DIR}/__init__.py | \\\\" \
        "\t\t\tgrep \"^__version__\" | \\\\" \
        "\t\t\tcut -d = -f 2))" \
        "" \
        "include envfile" \
        ".PHONY: docs upgrade-packages" \
        "" \
        "deploy: docker-up" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\tpip3 wheel --wheel-dir=wheels ." \
        "\tgit tag -a v\$(VERSION) -m \"Version \$(VERSION)\"" \
        "\t@echo" \
        "\t@echo" \
        "\t@echo Enter the following to push this tag to the repository:" \
        "\t@echo git push origin v\$(VERSION)" \
        "" \
        "docker-down:" \
        "\tdocker-compose -f docker/docker-compose.yml down" \
        "" \
        "docker-images-update:" \
        "\tdocker image ls | grep -v REPOSITORY | cut -d ' ' -f 1 | xargs -L1 docker pull" \
        ""\
        "docker-rebuild: setup.py" \
        "\tdocker-compose -f docker/docker-compose.yml up -d --build" \
        "" \
        "docker-up:" \
        "\tdocker-compose -f docker/docker-compose.yml up -d" \
        "" \
        "docs: docker-up" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \"pip install -e .[docs] && cd docs && make html\"" \
        "\t\${BROWSER} http://localhost:8080\n" \
        "" \
        "docs-init: docker-up" \
        "\trm -rf docs/*" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"cd docs \\\\" \
        "\t\t\t && sphinx-quickstart -q \\\\" \
        "\t\t\t\t-p \$(PROJECT) \\\\" \
        "\t\t\t\t-a \"${AUTHOR}\" \\\\" \
        "\t\t\t\t-v \$(VERSION) \\\\" \
        "\t\t\t\t--ext-autodoc \\\\" \
        "\t\t\t\t--ext-viewcode \\\\" \
        "\t\t\t\t--makefile \\\\" \
        "\t\t\t\t--no-batchfile\"" \
        "\tdocker-compose -f docker/docker-compose.yml restart nginx" \
        "ifeq (\"\$(shell git remote)\", \"origin\")" \
        "\tgit fetch" \
        "\tgit checkout origin/master -- docs/" \
        "else" \
        "\tdocker container run --rm \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT)/docs \\\\" \
        "\t\tubuntu \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"sed -i -e 's/# import os/import os/g' conf.py \\\\" \
        "\t\t\t && sed -i -e 's/# import sys/import sys/g' conf.py \\\\" \
        "\t\t\t && sed -i \\\\\"/# sys.path.insert(0, os.path.abspath('.'))/d\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"/import sys/a \\\\" \
        "\t\t\t\tsys.path.insert(0, os.path.abspath('../${SOURCE_DIR}')) \\\\" \
        "\t\t\t\t\\\\n\\\\nfrom ${SOURCE_DIR} import __version__\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"s/version = '0.1.0'/version = __version__/g\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"s/release = '0.1.0'/release = __version__/g\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"s/alabaster/sphinx_rtd_theme/g\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i \\\\\"/   :caption: Contents:/a \\\\" \
        "\t\t\t\t\\\\\\\\\\\\\\\\\\\\n   package\\\\\" \\\\" \
        "\t\t\t\tindex.rst\"" \
        "\tprintf \"%s\\\\n\" \\\\" \
        "\t\t\"Package Modules\" \\\\" \
        "\t\t\"===============\" \\\\" \
        "\t\t\"\" \\\\" \
        "\t\t\".. toctree::\" \\\\" \
        "\t\t\"    :maxdepth: 2\" \\\\" \
        "\t\t\"\" \\\\" \
        "\t\t\"cli\" \\\\" \
        "\t\t\"---\" \\\\" \
        "\t\t\".. automodule:: cli\" \\\\" \
        "\t\t\"    :members:\" \\\\" \
        "\t\t\"    :show-inheritance:\" \\\\" \
        "\t\t\"    :synopsis: Package commandline interface calls.\" \\\\" \
        "\t\t\"\" \\\\" \
        "\t\t\"db\" \\\\" \
        "\t\t\"--\" \\\\" \
        "\t\t\".. automodule:: db\" \\\\" \
        "\t\t\"    :members:\" \\\\" \
        "\t\t\"    :show-inheritance:\" \\\\" \
        "\t\t\"    :synopsis: Package database module.\" \\\\" \
        "\t\t\"\" \\\\" \
        "\t\t\"utils\" \\\\" \
        "\t\t\"-----\" \\\\" \
        "\t\t\".. automodule:: utils\" \\\\" \
        "\t\t\"    :members:\" \\\\" \
        "\t\t\"    :show-inheritance:\" \\\\" \
        "\t\t\"    :synopsis: Package utilities module.\" \\\\" \
        "\t\t\"\" \\\\" \
        "\t> \"docs/package.rst\"" \
        "endif" \
        "" \
        "docs-view: docker-up" \
        "\t\${BROWSER} http://localhost:8080" \
        "" \
        "ipython: docker-up" \
        "\tdocker container exec -it \$(PROJECT)_python ipython" \
        "" \
        "notebook: docker-up notebook-server" \
        "\tsleep 1.5" \
        "\t\${BROWSER} \$\$(docker container exec \\\\" \
        "\t\t\$(USER)_notebook_\$(PORT) \\\\" \
        "\t\tjupyter notebook list | grep -o '^http\S*')" \
        "" \
        "notebook-remove:" \
        "\tdocker container rm -f \$\$(docker container ls -f name=\$(USER)_notebook -q)" \
        "" \
        "notebook-server:" \
        "\tdocker container run -d --rm \\\\" \
        "\t\t--name \$(NOTEBOOK_NAME) \\\\" \
        "\t\t-p \$(PORT):\$(PORT) \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t\$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \"jupyter lab \\\\" \
        "\t\t\t\t--allow-root \\\\" \
        "\t\t\t\t--ip=0.0.0.0 \\\\" \
        "\t\t\t\t--no-browser \\\\" \
        "\t\t\t\t--port=\$(PORT)\"" \
        "\tdocker network connect \$(PROJECT) \$(NOTEBOOK_NAME)" \
        "" \
        "pgadmin: docker-up" \
        "\t\${BROWSER} http://localhost:5000" \
        "" \
        "psql: docker-up" \
        "\tdocker container exec -it \$(PROJECT)_postgres \\\\" \
        "\t\tpsql -U \${POSTGRES_USER} \$(PROJECT)" \
        "" \
        "pytorch: pytorch-docker docker-rebuild" \
        "" \
        "pytorch-docker:" \
        "\tdocker container run --rm \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT) \\\\" \
        "\t\tubuntu \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"sed -i -e 's/python-Dockerfile/pytorch-Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yml \\\\" \
        "\t\t\t && sed -i -e 's/tensorflow-Dockerfile/pytorch-Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yml \\\\" \
        "\t\t\t && sed -i -e 's/PKG_MANAGER=pip/PKG_MANAGER=conda/g' \\\\" \
        "\t\t\t\tMakefile\"" \
        "" \
        "snakeviz: docker-up snakeviz-server" \
        "\tsleep 0.5" \
        "\t\${BROWSER} http://0.0.0.0:\$(PORT)/snakeviz/" \
        "" \
        "snakeviz-remove:" \
        "\tdocker container rm -f \$\$(docker container ls -f name=snakeviz -q)" \
        "" \
        "snakeviz-server: docker-up" \
        "\tdocker container run -d --rm \\\\" \
        "\t\t--name snakeviz_\$(PORT) \\\\" \
        "\t\t-p \$(PORT):\$(PORT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT)/profiles \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t\$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"snakeviz profile.prof \\\\" \
        "\t\t\t\t--hostname 0.0.0.0 \\\\" \
        "\t\t\t\t--port \$(PORT) \\\\" \
        "\t\t\t\t--server\"" \
        "\tdocker network connect \$(PROJECT) snakeviz_\$(PORT)" \
        "" \
        "tensorflow: tensorflow-docker docker-rebuild" \
        "" \
        "tensorflow-docker:" \
        "\tdocker container run --rm \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT) \\\\" \
        "\t\tubuntu \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"sed -i -e 's/python-Dockerfile/tensorflow-Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yml \\\\" \
        "\t\t\t && sed -i -e 's/pytorch-Dockerfile/tensorflow-Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yml \\\\" \
        "\t\t\t && sed -i -e 's/PKG_MANAGER=conda/PKG_MANAGER=pip/g' \\\\" \
        "\t\t\t\tMakefile \\\\" \
        "\t\t\t && sed -i -e \\\\\"/'test': \['pytest', 'pytest-pep8'\],/a \\\\" \
        "\t\t\t\t\\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ 'tf-cpu': ['tensorflow'],\\\\" \
        "\t\t\t\t\\\\n\\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ 'tf-gpu': ['tensorflow-gpu'],\\\\\" \\\\" \
        "\t\t\t\tsetup.py\"" \
        "" \
        "tensorflow-models: tensorflow docker-rebuild" \
        "ifneq (\$(wildcard \${MODELS}), )" \
        "\techo \"Updating TensorFlow Models Repository\"" \
        "\tcd \${MODELS} \\\\" \
        "\t&& git checkout master \\\\" \
        "\t&& git pull" \
        "\tcd \${MOUNT_DIR}" \
        "else" \
        "\techo \"Cloning TensorFlow Models Repository to \${MODELS}\"" \
        "\tmkdir -p \${MODELS}" \
        "\tgit clone https://github.com/tensorflow/models.git \${MODELS}" \
        "endif" \
        "" \
        "test: docker-up" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \"py.test\\\\" \
        "\t\t\t\t--basetemp=pytest \\\\" \
        "\t\t\t\t--doctest-modules \\\\" \
        "\t\t\t\t--ff \\\\" \
        "\t\t\t\t--pep8 \\\\" \
        "\t\t\t\t-r all \\\\" \
        "\t\t\t\t-vvv\"" \
        "" \
        "upgrade-packages: docker-up" \
        "ifeq (\"\${PKG_MANAGER}\", \"pip\")" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"pip3 install -U pip \\\\" \
        "\t\t\t && pip3 freeze | \\\\" \
        "\t\t\t\tgrep -v \$(PROJECT) | \\\\" \
        "\t\t\t\tcut -d = -f 1 > requirements.txt \\\\" \
        "\t\t\t && pip3 install -U -r requirements.txt \\\\" \
        "\t\t\t && pip3 freeze > requirements.txt \\\\" \
        "\t\t\t && sed -i -e '/^-e/d' requirements.txt\"" \
        "else ifeq (\"\${PKG_MANAGER}\", \"conda\")" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"conda update conda \\\\" \
        "\t\t\t && conda update --all \\\\" \
        "\t\t\t && pip freeze > requirements.txt \\\\" \
        "\t\t\t && sed -i -e '/^-e/d' requirements.txt\"" \
        "endif" \
        > "${MAIN_DIR}${FILE_SEP}Makefile"
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
        "# PyCharm Setup" \
        "1. Database -> New -> Data Source -> PostgreSQL" \
        "1. Name: <project_name>_postgres@localhost" \
        "1. Host: localhost" \
        "1. Port: 5432" \
        "1. Database: <project_name>" \
        "1. User: **Postgres** username" \
        "1. Password: **Postgres** password" \
        "" \
        "# SNAKEVIZ Execution" \
        "1. Create profile file" \
        "    - Jupyter Notebook" \
        "        - \`%prun -D profile.prof enter_cmd_or_file\`" \
        "    - Command Line" \
        "        - \`python -m cProfile -o profile.prof program.py\`" \
        "1. Start server **from the command line** on port 10000" \
        "    - \`snakeviz profile.prof --hostname 0.0.0.0 --port 10000 -s\`" \
        "1. Open host web browser" \
        "    - \`http://0.0.0.0:10000/snakeviz/\`" \
        "" \
        "# Memory Profiler" \
        "1. Open Jupyter Notebook" \
        "1. Load Extension" \
        "    - \`%load_ext memory_profiler\`" \
        "1. Run profiler" \
        "    - \`%memit enter_code_here\`" \
        > "${MAIN_DIR}${FILE_SEP}README.md"
}


requirements() {
    touch "${MAIN_DIR}${FILE_SEP}requirements.txt"
}


setup() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        "from codecs import open" \
        "from pathlib import Path" \
        "import re" \
        "" \
        "from setuptools import setup, find_packages" \
        "" \
        "" \
        "with open('${SOURCE_DIR}${FILE_SEP}__init__.py', 'r') as fd:" \
        "    version = re.search(r'^__version__\s*=\s*[\'\"]([^\'\"]*)[\'\"]'," \
        "                        fd.read(), re.MULTILINE).group(1)" \
        "" \
        "here = Path(__file__).absolute().parent" \
        "with open(here / 'README.md', encoding='utf-8') as f:" \
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
        "        'click'," \
        "        'PyYAML'," \
        "        ]," \
        "    extras_require={" \
        "        'build': ['setuptools', 'wheel']," \
        "        'data': ['cufflinks', 'matplotlib', 'pandas']," \
        "        'database': ['psycopg2', 'sqlalchemy']," \
        "        'docs': ['sphinx', 'sphinx_rtd_theme']," \
        "        'notebook': ['jupyter', 'jupyterlab']," \
        "        'profile': ['memory_profiler', 'snakeviz']," \
        "        'test': ['pytest', 'pytest-pep8']," \
        "        }," \
        "    package_dir={'${MAIN_DIR}': '${SOURCE_DIR}'}," \
        "    include_package_data=True," \
        "    entry_points={" \
        "        'console_scripts': [" \
        "            'count=${SOURCE_DIR}.cli:count'," \
        "        ]" \
        "    }" \
        ")" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${MAIN_DIR}${FILE_SEP}setup.py"
}

utils() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        '""" Package Utilities Module' \
        "" \
        '"""' \
        "import logging" \
        "import logging.config" \
        "import functools" \
        "import operator" \
        "import os" \
        "from pathlib import Path" \
        "import re" \
        "from typing import Any, Dict, List, Union" \
        "" \
        "import yaml" \
        "" \
        "from ${MAIN_DIR}.globals import LOGGER_CONFIG, PACKAGE_ROOT" \
        "" \
        "" \
        "def logger_setup(file_path: Union[None, str] = None," \
        "                 logger_name: str = 'package') -> logging.Logger:" \
        '    """' \
        "    Configure logger with console and file handlers." \
        "" \
        "    :param file_path: if supplied the path will be appended by a timestamp \\\\" \
        "        and \".log\" else the default name of \"info.log\" will be saved in the \\\\" \
        "        location of the caller." \
        "    :param logger_name: name to be assigned to logger" \
        '    """' \
        "    with open(LOGGER_CONFIG, 'r') as f:" \
        "        config = yaml.safe_load(f.read())" \
        "        if file_path:" \
        "            time_stamp = datetime.datetime.now().strftime('%Y-%m-%d_%H:%M:%S')" \
        "            file_path = f'{file_path}_{time_stamp}.log'" \
        "            nested_set(config, ['handlers', 'file', 'filename'], file_path)" \
        "        logging.config.dictConfig(config)" \
        "    return logging.getLogger(logger_name)" \
        "" \
        "" \
        "def nested_get(nested_dict: Dict[Any, Any], key_path: List[Any]) -> Any:" \
        '    """' \
        "    Retrieve value from a nested dictionary." \
        "" \
        "    :param nested_dict: nested dictionary" \
        "    :param key_path: list of key levels with the final entry being the target" \
        '    """' \
        "    return functools.reduce(operator.getitem, key_path, nested_dict)" \
        "" \
        "" \
        "def nested_set(nested_dict: Dict[Any, Any], key_path: List[Any], value: Any):" \
        '    """' \
        "    Set object of nested dictionary." \
        "" \
        "    :param nested_dict: nested dictionary" \
        "    :param key_path: list of key levels with the final entry being the target" \
        "    :param value: new value of the target key in \`key_path\`" \
        '    """' \
        "    nested_get(nested_dict, key_path[:-1])[key_path[-1]] = value" \
        "" \
        "" \
        "def project_vars():" \
        '    """Load project specific environment variables."""' \
        "    with open(PACKAGE_ROOT / 'envfile'), 'r') as f:" \
        "        txt = f.read()" \
        "    env_vars = re.findall(r'export\s(.*)=(.*)', txt)" \
        "    for name, value in env_vars:" \
        "        os.environ[name] = value" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        ""\
        > "${SRC_PATH}${FILE_SEP}utils.py"
}

directories
cli
conftest
constructor_pkg
constructor_test
db
docker_compose
docker_python
docker_pytorch
docker_tensorflow
envfile
exceptions
git_attributes
git_config
git_ignore
globals
license
logger_config
makefile
manifest
readme
requirements
setup
utils
git_init
