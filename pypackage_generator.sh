#! /bin/bash

: "${AUTHOR:=EnterAuthorName}"
: "${EMAIL:=EnterAuthorEmail}"
: "${PYTHON_VERSION:=3.9}"
: "${PKG_VERSION:=0.1.0}"

###############################################################################

MAIN_DIR=${1:?"Specify a package name"}
SOURCE_DIR="${2:-$1}"
: "${DATA_DIR:=data}"
: "${DOCKER_DIR:=docker}"
: "${DOCS_DIR:=docs}"
: "${FILE_SEP:=/}"
: "${MONGO_INIT_DIR:=mongo_init}"
: "${NODEJS_VERSION:=12}"
: "${NOTEBOOK_DIR:=notebooks}"
: "${PROFILE_DIR:=profiles}"
: "${SCRIPTS_DIR:=scripts}"
: "${SECRETS_DIR:=secrets}"
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

YEAR=$(date +%Y)

SUB_DIRECTORIES=("${DATA_DIR}" \
                 "${DOCKER_DIR}" \
                 "${DOCS_DIR}" \
                 "${NOTEBOOK_DIR}" \
                 "${PROFILE_DIR}" \
                 "${SCRIPTS_DIR}" \
                 "${SOURCE_DIR}" \
                 "${WHEEL_DIR}" \
                 "htmlcov" \
                 ".github")

PY_SHEBANG="#! /usr/bin/env python3"
PY_ENCODING="# -*- coding: utf-8 -*-"

DOCKER_PATH="${MAIN_DIR}${FILE_SEP}${DOCKER_DIR}${FILE_SEP}"
MONGO_INIT_PATH="${DOCKER_PATH}${MONGO_INIT_DIR}${FILE_SEP}"
SECRETS_PATH="${DOCKER_PATH}${SECRETS_DIR}${FILE_SEP}"
SRC_PATH="${MAIN_DIR}${FILE_SEP}${SOURCE_DIR}${FILE_SEP}"
TEST_PATH="${SRC_PATH}${TEST_DIR}${FILE_SEP}"


cli() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Command Line Interface Module' \
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
        "@click.option('-q'," \
        "              count=True," \
        "              required=False," \
        "              help='Decrease output level one (-q) or multiple times (-qqq).')" \
        "@click.option('-v'," \
        "              count=True," \
        "              required=False," \
        "              help='Increase output level one (-v) or multiple times (-vvv).')" \
        "def count(number: int, q, v):" \
        '    """' \
        "    Display progressbar while counting to the user provided integer \`number\`." \
        '    """' \
        "    click.clear()" \
        "    logging_level = logging.INFO + 10 * q - 10 * v" \
        "    logging.basicConfig(level=logging_level)" \
        "    with click.progressbar(range(int(number)), label='Counting') as bar:" \
        "        for n in bar:" \
        "            click.secho(f'\n\nProcessing: {n}', fg='green')" \
        "            time.sleep(0.5)" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${SRC_PATH}cli.py"
}


common_image() {
    printf "%s\n" \
        "\t&& curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \\\\" \
        "\t&& apt-get update -y \\\\" \
        "\t&& apt-get upgrade -y \\\\" \
        "\t&& apt-get install -y \\\\" \
        "\t\tapt-utils \\\\" \
        "\t\tnodejs \\\\" \
        "\t# && jupyter labextension install @telamonian/theme-darcula \\\\" \
        "\t# && jupyter labextension install jupyterlab-plotly \\\\" \
        "\t# && jupyter labextension install jupyterlab-toc \\\\" \
        "\t&& rm -rf /tmp/* \\\\" \
        "\t&& rm -rf /var/lib/apt/lists/* \\\\" \
        "\t&& apt-get clean"
}


conftest() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Test Configuration File' \
        "" \
        '"""' \
        "import datetime" \
        "import time" \
        "" \
        "import numpy as np" \
        "import pytest" \
        "" \
        "from ..pkg_globals import TIME_FORMAT" \
        "" \
        "TEST_ARRAY = np.linspace(0, 255, 9, dtype=np.uint8).reshape(3, 3)" \
        "TEST_LABEL = 'test_string'" \
        "TEST_TIME = (2019, 12, 25, 8, 16, 32)" \
        "TEST_DATETIME = datetime.datetime(*TEST_TIME)" \
        "TEST_STRFTIME = TEST_DATETIME.strftime(TIME_FORMAT)" \
        "" \
        "" \
        "@pytest.fixture" \
        "def patch_datetime(monkeypatch):" \
        "    class CustomDatetime:" \
        "        @classmethod" \
        "        def now(cls):" \
        "            return TEST_DATETIME" \
        "" \
        "    monkeypatch.setattr(datetime, 'datetime', CustomDatetime)" \
        "" \
        "" \
        "@pytest.fixture" \
        "def patch_strftime(monkeypatch):" \
        "    def custom_strftime(fmt):" \
        "        return fmt.rstrip(TIME_FORMAT) + TEST_STRFTIME" \
        "" \
        "    monkeypatch.setattr(time, 'strftime', custom_strftime)" \
        > "${TEST_PATH}conftest.py"
}


constructor_pkg() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        "from pkg_resources import get_distribution, DistributionNotFound" \
        "from os import path" \
        "" \
        "from . import pkg_globals" \
        "# from . import cli" \
        "# from . import db" \
        "from . import exceptions" \
        "from . import utils" \
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
        > "${TEST_PATH}__init__.py"
}


coveragerc() {
    printf "%s\n" \
        "[run]" \
        "parallel = True" \
        "" \
        "[paths]" \
        "source =" \
        "    ${SOURCE_DIR}/" \
        "" \
        "[report]" \
        "omit =" \
        "    setup.py" \
        "    */__init__.py" \
        "    */tests/*" \
        "" \
        "[html]" \
        "directory = htmlcov" \
        "title = ${MAIN_DIR} Test Coverage" \
        > "${MAIN_DIR}${FILE_SEP}.coveragerc"
}


db() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Database Module' \
        "" \
        '"""' \
        "import logging" \
        "from typing import Callable, Iterable, Optional, Union" \
        "" \
        "import pandas as pd" \
        "import sqlalchemy as sa" \
        "from sqlalchemy.orm import sessionmaker" \
        "from sqlalchemy.sql import select" \
        "" \
        "from ${SOURCE_DIR}.utils import docker_secret" \
        "" \
        "logger = logging.getLogger('package')" \
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
        "    def __init__(self," \
        "                 host: Optional[str] = None," \
        "                 database: Optional[str] = None):" \
        "        self.dialect = 'postgresql'" \
        "        self.driver = None" \
        "        self.db_name = database if database else docker_secret('db-database')" \
        "        self.host = host if host else 'junk_postgres'" \
        "        self.meta = sa.MetaData()" \
        "        self.password = docker_secret('db-password')" \
        "        self.port = 5432" \
        "        self.user = docker_secret('db-username')" \
        "" \
        "        self.dialect = (f'{self.dialect}+{self.driver}'" \
        "                        if self.driver else self.dialect)" \
        "        self.engine = sa.create_engine(" \
        "            f'{self.dialect}://{self.user}:{self.password}'" \
        "            f'@{self.host}:{self.port}/{self.db_name}')" \
        "        self.conn = self.engine.connect()" \
        "        self.session = sessionmaker(bind=self.engine)" \
        "        self.tables = self.engine.table_names()" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return (f'<{type(self).__name__}('" \
        "                f'host={self.host!r}, '" \
        "                f'database={self.db_name!r}'" \
        "                f')>')" \
        "" \
        "    def __enter__(self):" \
        "        return self" \
        "" \
        "    def __exit__(self, exc_type, exc_val, exc_tb):" \
        "        self.conn.close()" \
        "        self.engine.dispose()" \
        "        self.session.close_all()" \
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
        "            sa.Column('password', sa.String(20), nullable=False))" \
        "        self._pref = sa.Table(" \
        "            'user_pref', self.meta," \
        "            sa.Column('pref_id', sa.Integer, primary_key=True)," \
        "            sa.Column('user_id'," \
        "                      sa.Integer," \
        "                      sa.ForeignKey(\"user.user_id\")," \
        "                      nullable=False)," \
        "            sa.Column('pref_name', sa.String(40), nullable=False)," \
        "            sa.Column('pref_value', sa.String(100)))" \
        "        self.meta.create_all(self.engine)" \
        "" \
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
        "def sql_data(" \
        "    host: str," \
        "    database: str," \
        "    schema: str," \
        "    table_name: str," \
        "    query: Callable," \
        ") -> pd.DataFrame:" \
        '    """' \
        "    Retrieve data from a database table." \
        "" \
        "    :param host: name of database host" \
        "    :param database: name of database" \
        "    :param schema: name of table schema" \
        "    :param table_name: name of table" \
        "    :param query: callable that returns a ORM SQLAlchemy select statement" \
        "    :return: data frame containing data from query" \
        "" \
        "    Example \`query\`:" \
        "    def query_example(session, table):" \
        "        cols = ('col1', 'col2')" \
        "        return session.query(*[table.c[x] for x in cols]).statement" \
        '    """' \
        "    with Connect(host=host, database=database) as c:" \
        "        table = sa.Table(" \
        "            table_name," \
        "            c.meta," \
        "            autoload=True," \
        "            autoload_with=c.engine," \
        "            schema=schema," \
        "        )" \
        "        df = pd.read_sql(" \
        "            query(c.session, table)," \
        "            con=c.engine," \
        "        )" \
        "    logger.info('Executed: %s' % query.__name__)" \
        "    return df" \
        "" \
        "" \
        "def sql_table(" \
        "    host: str," \
        "    database: str," \
        "    schema: str," \
        "    table_name: str," \
        "    columns: Optional[Union[str, Iterable[str]]] = None," \
        "    date_columns: Optional[Union[str, Iterable[str]]] = None," \
        ") -> pd.DataFrame:" \
        '    """' \
        "    Retrieve data from a database table." \
        "" \
        "    :param host: name of database host" \
        "    :param database: name of database" \
        "    :param schema: name of table schema" \
        "    :param table_name: name of table" \
        "    :param columns: column names to return (default: returns all columns)" \
        "    :param date_columns: column names to be formatted as dates" \
        "    :return: data frame containing data from table" \
        '    """' \
        "    columns = [columns] if isinstance(columns, str) else columns" \
        "    date_columns = ([date_columns]" \
        "                    if isinstance(date_columns, str) else date_columns)" \
        "    with Connect(host=host, database=database) as c:" \
        "        df = pd.read_sql_table(" \
        "            table_name=table_name," \
        "            con=c.engine," \
        "            schema=schema," \
        "            columns=columns," \
        "            parse_dates=date_columns," \
        "        )" \
        "    logger.info('Retrieved data from: %s/%s' % (database, table_name))" \
        "    return df" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${SRC_PATH}db.py"
}


directories() {
    # Main directory
    mkdir "${MAIN_DIR}"
    # Subdirectories
    for dir in "${SUB_DIRECTORIES[@]}"; do
        mkdir "${MAIN_DIR}${FILE_SEP}${dir}"
    done
    # MongoDB Initialization directory
    mkdir "${MONGO_INIT_PATH}"
    # Secrets directory
    mkdir "${SECRETS_PATH}"
    # Sphinx Documentation directory
    mkdir -p "${MAIN_DIR}${FILE_SEP}docs${FILE_SEP}_build${FILE_SEP}html"
    # Test directory
    mkdir "${SRC_PATH}${TEST_DIR}"
}


docker_compose() {
    printf "%s\n" \
        "version: '3.8'" \
        "" \
        "services:" \
        "" \
        "  latex:" \
        "    container_name: ${MAIN_DIR}_latex" \
        "    image: blang/latex" \
        "    networks:" \
        "      - ${MAIN_DIR}-network" \
        "    restart: always" \
        "    tty: true" \
        "    volumes:" \
        "      - ..:/usr/src/${MAIN_DIR}" \
        "      - secret:/usr/src/${MAIN_DIR}/.git" \
        "      - secret:/usr/src/${MAIN_DIR}/docker/secrets" \
        "    working_dir: /usr/src/${MAIN_DIR}" \
        "" \
        "  mongodb:" \
        "    container_name: ${MAIN_DIR}_mongodb" \
        "    image: mongo" \
        "    environment:" \
        "      MONGO_INITDB_ROOT_PASSWORD: /run/secrets/db-init-password" \
        "      MONGO_INITDB_ROOT_USERNAME: /run/secrets/db-init-username" \
        "      MONGO_INITDB_PASSWORD: /run/secrets/db-password" \
        "      MONGO_INITDB_USERNAME: /run/secrets/db-username" \
        "    networks:" \
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 27017:27017" \
        "    restart: always" \
        "    secrets:" \
        "      - db-database" \
        "      - db-init-password" \
        "      - db-init-username" \
        "      - db-password" \
        "      - db-username" \
        "    volumes:" \
        "      - ${MAIN_DIR}-db:/var/lib/mongodb/data" \
        "      - ./${MONGO_INIT_DIR}:/docker-entrypoint-initdb.d" \
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
        "  pgadmin:" \
        "    container_name: ${MAIN_DIR}_pgadmin" \
        "    image: dpage/pgadmin4" \
        "    depends_on:" \
        "      - postgres" \
        "    environment:" \
        "      PGADMIN_DEFAULT_EMAIL: \${PGADMIN_DEFAULT_EMAIL:-pgadmin@pgadmin.org}" \
        "      PGADMIN_DEFAULT_PASSWORD: \${PGADMIN_DEFAULT_PASSWORD:-admin}" \
        "    external_links:" \
        "      - ${MAIN_DIR}_postgres:${MAIN_DIR}_postgres" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 5000:80" \
        "" \
        "  postgres:" \
        "    container_name: ${MAIN_DIR}_postgres" \
        "    image: postgres:alpine" \
        "    environment:" \
        "      POSTGRES_PASSWORD_FILE: /run/secrets/db-password" \
        "      POSTGRES_DB_FILE: /run/secrets/db-database" \
        "      POSTGRES_USER_FILE: /run/secrets/db-username" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 5432:5432" \
        "    restart: always" \
        "    secrets:" \
        "      - db-database" \
        "      - db-password" \
        "      - db-username" \
        "    volumes:" \
        "      - ${MAIN_DIR}-db:/var/lib/postgresql/data" \
        "" \
        "  python:" \
        "    container_name: ${MAIN_DIR}_python" \
        "    image: ${MAIN_DIR}_python" \
        "    build:" \
        "      context: .." \
        "      dockerfile: docker/python.Dockerfile" \
        "    depends_on:" \
        "      - mongodb" \
        "      - postgres" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - 8888:8080" \
        "    restart: always" \
        "    secrets:" \
        "      - db-database" \
        "      - db-init-password" \
        "      - db-init-username" \
        "      - db-password" \
        "      - db-username" \
        "    tty: true" \
        "    volumes:" \
        "      - ..:/usr/src/${MAIN_DIR}" \
        "      - secret:/usr/src/${MAIN_DIR}/.git" \
        "      - secret:/usr/src/${MAIN_DIR}/docker/secrets" \
        "" \
        "networks:" \
        "  ${MAIN_DIR}-network:" \
        "    name: ${MAIN_DIR}" \
        "" \
        "secrets:" \
        "  db-database:" \
        "    file: secrets/db_database.txt" \
        "  db-init-password:" \
        "    file: secrets/db_init_password.txt" \
        "  db-init-username:" \
        "    file: secrets/db_init_username.txt" \
        "  db-password:" \
        "    file: secrets/db_password.txt" \
        "  db-username:" \
        "    file: secrets/db_username.txt" \
        "" \
        "volumes:" \
        "  ${MAIN_DIR}-db:" \
        "  secret:" \
        "" \
        > "${DOCKER_PATH}docker-compose.yaml"
}


docker_ignore() {
    printf "%s\n" \
        "*.egg-info" \
        ".git" \
        ".idea" \
        ".pytest_cache" \
        "docker/secrets" \
        ".pytest" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}.dockerignore"
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
        "\t&& pip3 install -e .[all] \\\\" \
        "$(common_image)" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${DOCKER_PATH}python.Dockerfile"
}


docker_pytorch() {
    printf "%b\n" \
        "FROM pytorch/pytorch" \
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
        > "${DOCKER_PATH}pytorch.Dockerfile"
}


docker_tensorflow() {
    printf "%b\n" \
        "FROM nvcr.io/nvidia/tensorflow:21.04-tf2-py3" \
        "" \
        "WORKDIR /usr/src/${SOURCE_DIR}" \
        "" \
        "COPY . ." \
        "" \
        "RUN cd /opt \\\\" \
        "\t&& apt-get update -y \\\\" \
        "\t#&& apt-get upgrade -y \\\\  Do not upgrade NVIDIA image OS" \
        "\t&& apt-get install -y \\\\" \
        "\t\tapt-utils \\\\" \
        "\t&& cd /usr/src/${SOURCE_DIR} \\\\" \
        "\t&& pip install --upgrade pip \\\\" \
        "\t&& pip install -e .[all] \\\\" \
        "\t&& rm -rf /tmp/* \\\\" \
        "\t&& rm -rf /var/lib/apt/lists/* \\\\" \
        "\t&& apt-get clean" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${DOCKER_PATH}tensorflow.Dockerfile"
}


exceptions() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
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
        "    def __init__(self, expression: str, message: str):" \
        "        self.expression = expression" \
        "        self.message = message" \
        "" \
        "" \
        "class InputError(Error):" \
        '    """Exception raised for errors in the input."""' \
        > "${SRC_PATH}exceptions.py"
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
        "# Docker secret files" \
        "docker/secrets/*" \
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
        "# Ipython files" \
        ".ipynb_checkpoints" \
        "" \
        "# Logs and databases" \
        "*.log" \
        "*make.bat" \
        "*.sql" \
        "*.sqlite" \
        "" \
        "# OS generated files" \
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
        "htmlcov/*" \
        "*.profile" \
        "" \
        "# Project files" \
        "*wheels" \
        "" \
        "# PyCharm files" \
        ".idea${FILE_SEP}*" \
        "${MAIN_DIR}${FILE_SEP}.idea${FILE_SEP}*" \
        "" \
        "# pytest files" \
        ".cache${FILE_SEP}*" \
        ".pytest_cache" \
        "pytest" \
        "" \
        "# Raw data" \
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
    cd "${MAIN_DIR}" || exit
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
    printf "%b\n" \
        "PROJECT=${MAIN_DIR}" \
        "ifeq (\"\$(shell uname -s)\", \"Linux*\")" \
        "\tBROWSER=/usr/bin/firefox" \
        "else ifeq (\"\$(shell uname -s)\", \"Linux\")" \
        "\tBROWSER=/usr/bin/firefox" \
        "else" \
        "\tBROWSER=open" \
        "endif" \
        "MOUNT_DIR=\$(shell pwd)" \
        "MODELS=/opt/models" \
        "PKG_MANAGER=pip" \
        "PORT:=\$(shell awk -v min=16384 -v max=27000 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')" \
        "NOTEBOOK_NAME=\$(USER)_notebook_\$(PORT)" \
        'PROFILE_PY:=""' \
        "PROFILE_PROF:=\$(notdir \$(PROFILE_PY:.py=.prof))" \
        "PROFILE_PATH:=profiles/\$(PROFILE_PROF)" \
        "SRC_DIR=/usr/src/${SOURCE_DIR}" \
        "TEX_DIR:=\"\"" \
        "TEX_FILE:=\"*.tex\"" \
        "TEX_WORKING_DIR=\${SRC_DIR}/\${TEX_DIR}" \
        "USER=\$(shell echo \$\${USER%%@*})" \
        "VERSION=\$(shell echo \$(shell cat ${SOURCE_DIR}/__init__.py | \\\\" \
        "\t\t\tgrep \"^__version__\" | \\\\" \
        "\t\t\tcut -d = -f 2))" \
        "JUPYTER=lab" \
        "NOTEBOOK_CMD=\"\${BROWSER} \$\$(docker container exec \$(USER)_notebook_\$(PORT) jupyter \$(JUPYTER) list | grep -o '^http\S*')\"" \
        "NOTEBOOK_DELAY=10" \
        "" \
        ".PHONY: docs format-style upgrade-packages" \
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
        "\tdocker-compose -f docker/docker-compose.yaml down" \
        "" \
        "docker-images-update:" \
        "\tdocker image ls | grep -v REPOSITORY | cut -d ' ' -f 1 | xargs -L1 docker pull" \
        ""\
        "docker-rebuild: setup.py" \
        "\tdocker-compose -f docker/docker-compose.yaml up -d --build" \
        "" \
        "docker-up:" \
        "\tdocker-compose -f docker/docker-compose.yaml up -d" \
        "" \
        "docs: docker-up" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \"pip install -e .[docs] && cd docs && make html\"" \
        "\t\${BROWSER} http://localhost:8080\n" \
        "" \
        "docs-init: docker-up" \
        "\tfind docs -maxdepth 1 -type f -delete" \
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
        "\tdocker-compose -f docker/docker-compose.yaml restart nginx" \
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
        "\t\t\t\tfrom ${SOURCE_DIR} import __version__ \\\\" \
        "\t\t\t\t\\\\n\\\\nsys.path.insert(0, os.path.abspath('../${SOURCE_DIR}'))\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"s/version = '0.1.0'/version = __version__/g\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"s/release = '0.1.0'/release = __version__/g\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e \\\\\"s/alabaster/sphinx_rtd_theme/g\\\\\" \\\\" \
        "\t\t\t\tconf.py \\\\" \
        "\t\t\t && sed -i -e 's/[ \\\\t]*\$\$//g' conf.py \\\\" \
        "\t\t\t && echo >> conf.py \\\\" \
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
        "\t\t\"    :synopsis: Package command line interface calls.\" \\\\" \
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
        "format-style: docker-up" \
        "\tdocker container exec \$(PROJECT)_python yapf -i -p -r --style \"pep8\" \${SRC_DIR}" \
        "" \
        "ipython: docker-up" \
        "\tdocker container exec -it \$(PROJECT)_python ipython" \
        "" \
        "latexmk: docker-up" \
        "\tdocker container exec -w \$(TEX_WORKING_DIR) \$(PROJECT)_latex \\\\" \
        "\t\t/bin/bash -c \"latexmk -f -pdf \$(TEX_FILE) && latexmk -c\"" \
        "" \
        "notebook: docker-up notebook-server" \
        "\tsleep 2" \
        "\t(eval \${NOTEBOOK_CMD} || sleep \${NOTEBOOK_DELAY}) || eval \${NOTEBOOK_CMD}" \
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
        "\t\t/bin/bash -c \"jupyter \$(JUPYTER) \\\\" \
        "\t\t\t\t--allow-root \\\\" \
        "\t\t\t\t--ip=0.0.0.0 \\\\" \
        "\t\t\t\t--no-browser \\\\" \
        "\t\t\t\t--port=\$(PORT)\"" \
        "\tdocker network connect \$(PROJECT) \$(NOTEBOOK_NAME)" \
        "" \
        "pgadmin: docker-up" \
        "\t\${BROWSER} http://localhost:5000" \
        "" \
        "profile: docker-up" \
        "\tdocker container exec \$(PROJECT)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"python \\\\" \
        "\t\t\t\t-m cProfile \\\\" \
        "\t\t\t\t-o \$(PROFILE_PATH) \\\\" \
        "\t\t\t\t\$(PROFILE_PY)\"" \
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
        "\t\t\t\"sed -i -e 's/python.Dockerfile/pytorch.Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yaml \\\\" \
        "\t\t\t && sed -i -e 's/tensorflow.Dockerfile/pytorch.Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yaml \\\\" \
        "\t\t\t && sed -i -e 's/PKG_MANAGER=pip/PKG_MANAGER=conda/g' \\\\" \
        "\t\t\t\tMakefile\"" \
        "" \
        "snakeviz: docker-up profile snakeviz-server" \
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
        "\t\t\t\"snakeviz \$(PROFILE_PROF) \\\\" \
        "\t\t\t\t--hostname 0.0.0.0 \\\\" \
        "\t\t\t\t--port \$(PORT) \\\\" \
        "\t\t\t\t--server\"" \
        "\tdocker network connect \$(PROJECT) snakeviz_\$(PORT)" \
        "" \
        "tensorflow: tensorflow-updates docker-rebuild" \
        "" \
        "tensorflow-updates:" \
        "\tdocker container run --rm \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT) \\\\" \
        "\t\tubuntu \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"sed -i -e 's/python.Dockerfile/tensorflow.Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yaml \\\\" \
        "\t\t\t && sed -i -e 's/pytorch.Dockerfile/tensorflow.Dockerfile/g' \\\\" \
        "\t\t\t\tdocker/docker-compose.yaml \\\\" \
        "\t\t\t && sed -i -e 's/PKG_MANAGER=conda/PKG_MANAGER=pip/g' \\\\" \
        "\t\t\t\tMakefile \\\\" \
        "\t\t\t && sed -i -e 's/JUPYTER=lab/JUPYTER=notebook/g' Makefile \\\\" \
        "\t\t\t && echo '*********************************************************************************' \\\\" \
        "\t\t\t && echo '*********************************************************************************' \\\\" \
        "\t\t\t && echo \\" \
        "\t\t\t && echo 'Add \\\"tensorflow\\\" or \\\"tensorflow-gpu\\\" to install_requires in the setup.py file' \\\\" \
        "\t\t\t && echo \\" \
        "\t\t\t && echo '*********************************************************************************' \\\\" \
        "\t\t\t && echo '*********************************************************************************'\"" \
        "" \
        "test: docker-up format-style" \
        "\tdocker container exec \$(PROJECT)_python py.test \$(PROJECT)" \
        "" \
        "test-coverage: test" \
	      "\t\${BROWSER} htmlcov/index.html"\
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
        "" \
        "use-mongo:" \
        "\tdocker container run --rm \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT) \\\\" \
        "\t\tubuntu \\\\" \
        "\t\t\t/bin/bash -c \\\\" \
        "\t\t\t\t\"sed -i '/psycopg2-binary/d' setup.py \\\\" \
        "\t\t\t\t&& sed -i '/sqlalchemy/d' setup.py \\\\" \
        "\t\t\t\t&& sed '/[ ]*pgadmin:/,/postgresql\/data/d' docker/docker-compose.yaml | \\\\" \
        "\t\t\t\t\tsed '/- postgres/d' | \\\\" \
        "\t\t\t\t\tcat -s > temp \\\\" \
        "\t\t\t\t&& mv temp docker/docker-compose.yaml\"" \
        "" \
        "use-postres:" \
        "\tdocker container run --rm \\\\" \
        "\t\t-v \`pwd\`:/usr/src/\$(PROJECT) \\\\" \
        "\t\t-w /usr/src/\$(PROJECT) \\\\" \
        "\t\tubuntu \\\\" \
        "\t\t\t/bin/bash -c \\\\" \
        "\t\t\t\t\"sed -i '/pymongo/d' setup.py \\\\" \
        "\t\t\t\t&& sed '/[ ]*mongodb:/,/mongodb\/data/d' docker/docker-compose.yaml | \\\\" \
        "\t\t\t\t\tsed '/- mongodb/d' | \\\\" \
        "\t\t\t\t\tcat -s > temp \\\\" \
        "\t\t\t\t&& mv temp docker/docker-compose.yaml\"" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}Makefile"
}


manifest() {
    printf "%s\n" \
        "include LICENSE.txt" \
        > "${MAIN_DIR}${FILE_SEP}MANIFEST.in"
}


mongo_init() {
    printf "%s\n" \
        "#!/bin/bash" \
        "" \
        "mongo admin -u \$MONGO_INITDB_ROOT_USERNAME -p \$MONGO_INITDB_ROOT_PASSWORD -- << EOF" \
        "var admin_db=db.getSiblingDB('admin')" \
        "var password='\$MONGO_INITDB_PASSWORD'" \
        "var username='\$MONGO_INITDB_USERNAME'" \
        "" \
        "admin_db.createUser(" \
        "    {" \
        "        user: username," \
        "        pwd: password," \
        "        roles: [{role: 'root', db: 'admin'}]" \
        "    }" \
        ")" \
        "EOF" \
        "" \
        > "${MONGO_INIT_PATH}create_root_user.sh"
}


pull_request_template() {
    printf "%s\n" \
        "# Summary" \
        "< Description of PR >" \
        "" \
        "# Test Plan" \
        "- < Item(s) a reviewer should be able to verify >" \
        "" \
        "# Checklist" \
        "- [ ] PEP8 Compliant" \
        "- [ ] Unit Test Coverage" \
        "- [ ] Updated HISTORY.md" \
        "" \
        "# Issues Closed (optional)" \
        "- < issue(s) reference >" \
        > "${MAIN_DIR}${FILE_SEP}.github${FILE_SEP}PULL_REQUEST_TEMPLATE.md"
}


pkg_globals() {
    printf "%s\n" \
            "${PY_SHEBANG}" \
            "${PY_ENCODING}" \
            '""" Global Variable Module' \
            "" \
            '"""' \
            "from pathlib import Path" \
            "" \
            "PACKAGE_ROOT = Path(__file__).parents[1]" \
            "" \
            "FONT_SIZE = {" \
            "    'axis': 18," \
            "    'label': 14," \
            "    'legend': 12," \
            "    'super_title': 24," \
            "    'title': 20," \
            "}" \
            "" \
            "FONT_FAMILY = 'Courier New, monospace'" \
            "PLOTLY_FONTS = {" \
            "    'axis_font': {" \
            "        'family': FONT_FAMILY," \
            "        'size': FONT_SIZE['axis']," \
            "        'color': 'gray'," \
            "    }," \
            "    'legend_font': {" \
            "        'family': FONT_FAMILY," \
            "        'size': FONT_SIZE['label']," \
            "        'color': 'black'," \
            "    }," \
            "    'title_font': {" \
            "        'family': FONT_FAMILY," \
            "        'size': FONT_SIZE['super_title']," \
            "        'color': 'black'," \
            "    }," \
            "}" \
            "" \
            "TIME_FORMAT = '%Y_%m_%d_%H_%M_%S'" \
            "" \
            "if __name__ == '__main__':" \
            "    pass" \
            > "${SRC_PATH}pkg_globals.py"
    }


readme() {
    printf "%s\n" \
        "# Define System Variables" \
        "1. Enter your username and password for PGAdmin and Postgres" \
        "" \
        "# PGAdmin Setup" \
        "1. From the main directory call \`make pgadmin\`" \
        "    - The default browser will open to \`localhost:5000\`" \
        "1. Enter the **PGAdmin** default user and password." \
        "1. CHANGE THE PASSWORD" \
        "    - The pgAdmin container requires a default password to get started." \
        "1. Click \`Add New Server\`." \
        "    - General Name: Enter the <project_name>" \
        "    - Connection Host: Enter <project_name>_postgres" \
        "    - Connection Username and Password: Enter **Postgres** username and password" \
        "" \
        "# PyCharm Setup" \
        "## Database Configuration" \
        "1. Make sure any new users are added to the database." \
        "    \`\`\`postgresql" \
        "    GRANT CONNECT ON DATABASE ${MAIN_DIR} TO new_user;" \
        "    GRANT USAGE ON SCHEMA public TO new_user;" \
        "    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO new_user;" \
        "    \`\`\`" \
        "1. \`Database\` -> \`New\` -> \`Data Source\` -> \`PostgreSQL\`" \
        "1. \`Name\`: ${MAIN_DIR}_postgres@localhost" \
        "1. \`Host\`: localhost" \
        "1. \`Port\`: 5432" \
        "1. \`Database\`: ${MAIN_DIR}" \
        "1. \`User\`: **Postgres** username" \
        "1. \`Password\`: **Postgres** password" \
        "" \
        "1. \`Settings\` -> \`Project\` -> \`Project Interpreter\` -> point to docker compose file" \
        "" \
        "## Unit Test Configuration" \
        "1. \`Run/Debug Configurations\` -> \`+\` -> \`Python tests\` -> \`pytest\`" \
        "1. \`Target\` -> \`Script path\`" \
        "    - Enter the path to the project root directory." \
        "1. Add the following to the \`Additional Arguments\` field:" \
        "    - \`-vvv\`" \
        "    - \`-r all\`" \
        "    - \`--basetemp=pytest\`" \
        "    - \`--ff\`" \
        "    - \`doctest-modules\`" \
        "        - To ignore specific modules add \`--ignore=<module_name>\`"\
        "1. Check Box -> \`Add content roots to PYTHONPATH\`" \
        "1. Check Box -> \`Add source roots to PYTHONPATH\`" \
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


release_history() {
    printf "%s\n" \
        "# Release History" \
        "## 0.1.0 (YYYY-MM-DD)" \
        "" \
        "**Improvements**" \
        "" \
        "- "\
        > "${MAIN_DIR}${FILE_SEP}HISTORY.md"
}


requirements() {
    touch "${MAIN_DIR}${FILE_SEP}requirements.txt"
}


secret_db_database() {
    printf "%s" \
        "${MAIN_DIR}" \
        > "${SECRETS_PATH}db_database.txt"
}


secret_db_init_password() {
    printf "%s" \
        "password" \
        > "${SECRETS_PATH}db_init_password.txt"
}


secret_db_init_username() {
    printf "%s" \
        "admin" \
        > "${SECRETS_PATH}db_init_username.txt"
}


secret_db_password() {
    printf "%s" \
        "password" \
        > "${SECRETS_PATH}db_password.txt"
}


secret_db_username() {
    printf "%s" \
        "user" \
        > "${SECRETS_PATH}db_username.txt"
}


setup_cfg() {
    printf "%s\n" \
        "# Test coverage" \
        "[coverage:run]" \
        "parallel = True" \
        "" \
        "[coverage:paths]" \
        "source =" \
        "    ${MAIN_DIR}/" \
        "" \
        "[coverage:report]" \
        "omit =" \
        "    docs/*" \
        "    scripts/*" \
        "    setup.py" \
        "    */__init__.py" \
        "    */tests/*" \
        "" \
        "[coverage:html]" \
        "directory = htmlcov" \
        "title = ${MAIN_DIR} Test Coverage" \
        "" \
        "# pytest" \
        "[tool:pytest]" \
        "addopts =" \
        "    -rvvv" \
        "    --basetemp pytest" \
        "    --cov ." \
        "    --cov-report html" \
        "    --doctest-modules" \
        "    --ff" \
        "    --ignore" \
        "        data" \
        "        docker" \
        "        docs" \
        "        htmlcov" \
        "        notebooks" \
        "        profiles" \
        "        wheels" \
        "    --pycodestyle" \
        "" \
        > "${MAIN_DIR}${FILE_SEP}setup.cfg"
}


setup_py() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        "" \
        "from codecs import open" \
        "from pathlib import Path" \
        "from operator import itemgetter" \
        "import re" \
        "from typing import Iterable, List, Union" \
        "" \
        "from setuptools import setup, find_packages" \
        "" \
        "dependencies = {" \
        "    'build': {" \
        "        'setuptools'," \
        "        'wheel'," \
        "    }," \
        "    'docs': {" \
        "        'sphinx'," \
        "        'sphinx_rtd_theme'," \
        "    }," \
        "    'jupyter': {" \
        "        'jupyter'," \
        "        'jupyterlab'," \
        "    }," \
        "    'profile': {" \
        "        'memory_profiler'," \
        "        'snakeviz'," \
        "    }," \
        "    'test': {" \
        "        'Faker'," \
        "        'git-lint'," \
        "        'pytest'," \
        "        'pytest-cov'," \
        "        'pytest-pycodestyle'," \
        "    }," \
        "}" \
        "" \
        "" \
        "def combine_dependencies(extras: Union[str, Iterable[str]]) -> List[str]:" \
        '    """' \
        "    Combine package dependencies." \
        "" \
        "    :param extras: key(s) from the \`dependencies\` dictionary" \
        "    :return: The minimum set of package dependencies contained in \`extras\`." \
        '    """' \
        "    if isinstance(extras, str):" \
        "        deps = set(itemgetter(extras)(dependencies))" \
        "    else:" \
        "        deps = set().union(*itemgetter(*extras)(dependencies))" \
        "    return list(deps)" \
        "" \
        "" \
        "with open('${SOURCE_DIR}${FILE_SEP}__init__.py', 'r') as fd:" \
        "    version = re.search(r'^__version__\s*=\s*[\'\"]([^\'\"]*)[\'\"]', fd.read()," \
        "                        re.MULTILINE).group(1)" \
        "" \
        "here = Path(__file__).absolute().parent" \
        "with open(here / 'README.md', encoding='utf-8') as f:" \
        "    long_description = f.read()" \
        "" \
        "setup(name='${MAIN_DIR}'," \
        "      version=version," \
        "      description='Modules related to EnterDescriptionHere'," \
        "      author='${AUTHOR}'," \
        "      author_email='${EMAIL}'," \
        "      license='BSD'," \
        "      classifiers=[" \
        "          'Development Status :: 1 - Planning'," \
        "          'Environment :: Console'," \
        "          'Intended Audience :: Developers'," \
        "          'License :: OSI Approved'," \
        "          'Natural Language :: English'," \
        "          'Operating System :: OS Independent'," \
        "          'Programming Language :: Python :: ${PYTHON_VERSION%%.*}'," \
        "          'Programming Language :: Python :: ${PYTHON_VERSION}'," \
        "          'Topic :: Software Development :: Build Tools'," \
        "      ]," \
        "      keywords='EnterKeywordsHere'," \
        "      packages=find_packages(exclude=[" \
        "          'data'," \
        "          'docker'," \
        "          'docs'," \
        "          'notebooks'," \
        "          'wheels'," \
        "          '*tests'," \
        "      ])," \
        "      install_requires=[" \
        "          'click'," \
        "          'matplotlib'," \
        "          'opencv-python-headless'," \
        "          'pandas'," \
        "          'psycopg2-binary'," \
        "          'pymongo'," \
        "          'sqlalchemy'," \
        "          'yapf'," \
        "      ]," \
        "      extras_require={" \
        "          'all': combine_dependencies(dependencies.keys())," \
        "          'build': combine_dependencies(('build', 'test'))," \
        "          'docs': combine_dependencies('docs')," \
        "          'jupyter': combine_dependencies('jupyter')," \
        "          'profile': combine_dependencies('profile')," \
        "          'test': combine_dependencies('test')," \
        "      }," \
        "      package_dir={'${MAIN_DIR}': '${SOURCE_DIR}'}," \
        "      include_package_data=True," \
        "      entry_points={'console_scripts': [" \
        "          'count=${SOURCE_DIR}.cli:count'," \
        "      ]})" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${MAIN_DIR}${FILE_SEP}setup.py"
}


test_cli() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Command Line Interface Unit Tests' \
        "" \
        '"""' \
        "from click.testing import CliRunner" \
        "" \
        "from .. import cli" \
        "" \
        "" \
        "def test_count():" \
        "    runner = CliRunner()" \
        "    result = runner.invoke(cli.count, ['1'])" \
        "    assert result.exit_code == 0" \
        > "${TEST_PATH}test_cli.py"
}


test_conftest() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" pytest Fixtures Unit Tests' \
        "" \
        '"""' \
        "import datetime" \
        "import time" \
        "" \
        "from .conftest import TEST_ARRAY, TEST_LABEL, TEST_DATETIME, TEST_STRFTIME" \
        "from ..pkg_globals import TIME_FORMAT" \
        "" \
        "" \
        "# Test patch_datetime()" \
        "def test_patch_datetime(patch_datetime):" \
        "    assert datetime.datetime.now() == TEST_DATETIME" \
        "" \
        "" \
        "# Test patch_strftime()" \
        "def test_patch_strftime(patch_strftime):" \
        "    assert time.strftime(TIME_FORMAT) == TEST_STRFTIME" \
        > "${TEST_PATH}test_conftest.py"
}


test_db() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Database Unit Tests' \
        "" \
        '"""' \
        "import pytest" \
        "" \
        "from .. import db" \
        "" \
        "# DATABASE = '${MAIN_DIR}'" \
        "# HOST = '${MAIN_DIR}_postgres'" \
        "# TABLE_NAME = '<enter_table_name_in_${MAIN_DIR}_db>'" \
        "" \
        "" \
        "# Test Connect.__repr__()" \
        "# def test_connect_repr():" \
        "#     c = db.Connect(host=HOST, database=DATABASE)" \
        "#     assert repr(c) == f\"<Connect(host='{HOST}', database='{DATABASE}')>\"" \
        "" \
        "" \
        "# Test Connect.__enter__() and Connect.__exit__()" \
        "# def test_connect_context_manager():" \
        "#     with db.Connect(host=HOST, database=DATABASE) as c:" \
        "#         _ = c.engine.connect()" \
        "#         assert c.engine.pool.checkedout()" \
        "#     assert not c.engine.pool.checkedout()" \
        "" \
        "" \
        "# Test sql_data()" \
        "# def test_sql_data():" \
        "#     def col_query(session, table):" \
        "#         return session.query(table.c['column_name']).statement" \
        "" \
        "#     df = db.sql_data(host=HOST," \
        "#                      database=DATABASE," \
        "#                      schema='schema_name'," \
        "#                      table_name=TABLE_NAME," \
        "#                      query=col_query)" \
        "#     assert 'column_name' in df.columns" \
        "" \
        "# Test sql_table()" \
        "# def test_sql_table():" \
        "#     df = db.sql_table(host=HOST," \
        "#                       database=DATABASE," \
        "#                       schema='schema_name'," \
        "#                       table_name=TABLE_NAME)" \
        "#     assert 'column_name' in df.columns" \
        > "${TEST_PATH}test_db.py"
}


test_utils() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Utilities Unit Tests' \
        "" \
        '"""' \
        "import logging" \
        "from pathlib import Path" \
        "import warnings" \
        "" \
        "import numpy as np" \
        "import pytest" \
        "" \
        "from .conftest import TEST_STRFTIME" \
        "from .. import exceptions" \
        "from ..pkg_globals import FONT_SIZE, TIME_FORMAT" \
        "from .. import utils" \
        "" \
        "LOGGER = logging.getLogger(__name__)" \
        "" \
        "# Test docker_secret()" \
        "docker_secret = {" \
        "    'database': ('db-database', '${MAIN_DIR}')," \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('secret_name, expected'," \
        "                         list(docker_secret.values())," \
        "                         ids=list(docker_secret.keys()))" \
        "def test_docker_secret_found(secret_name, expected):" \
        "    assert utils.docker_secret(secret_name) == expected" \
        "" \
        "" \
        "def test_docker_secret_missing():" \
        "    assert utils.docker_secret('missing-secret') is None" \
        "" \
        "" \
        "# Test logger_setup()" \
        "logger_setup = {" \
        "    'default args': (None, Path('info.log'))," \
        "    'file_path': ('test_p', Path('test_p-2019_12_25_08_16_32.log'))," \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('file_path, log_file'," \
        "                         list(logger_setup.values())," \
        "                         ids=list(logger_setup.keys()))" \
        "def test_logger_setup(patch_strftime, file_path, log_file):" \
        "    logger = utils.logger_setup(file_path)" \
        "    assert isinstance(logger, logging.Logger)" \
        "    assert log_file in list(Path().glob('*.log'))" \
        "    log_file.unlink()" \
        "" \
        "" \
        "# Test nested_get()" \
        "nested_get = {" \
        "    'first level': (['x'], 0)," \
        "    'nested level': (['a', 'b', 'c'], 2)," \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('key_path, expected'," \
        "                         list(nested_get.values())," \
        "                         ids=list(nested_get.keys()))" \
        "def test_nested_get(key_path, expected):" \
        "    sample_dict = {'a': {'b': {'c': 2}, 'y': 1}, 'x': 0}" \
        "    assert utils.nested_get(sample_dict, key_path) == expected" \
        "" \
        "" \
        "# Test nested_set()" \
        "nested_set = {" \
        "    'first level': (['x'], 00)," \
        "    'nested level': (['a', 'b', 'c'], 22)," \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('key_path, value'," \
        "                         list(nested_set.values())," \
        "                         ids=list(nested_set.keys()))" \
        "def test_nested_set(key_path, value):" \
        "    sample_dict = {'a': {'b': {'c': 2}, 'y': 1}, 'x': 0}" \
        "    utils.nested_set(sample_dict, key_path, value)" \
        "    assert utils.nested_get(sample_dict, key_path) == value" \
        "" \
        "" \
        "# Test progress_str()" \
        "progress_str = {" \
        "    '0%': (0, 100, '\rProgress:  0.0%')," \
        "    '100%': (100, 100, '\rProgress:  100.0%\n\n')," \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('n, total, expected'," \
        "                         list(progress_str.values())," \
        "                         ids=list(progress_str.keys()))" \
        "def test_progress_str(n, total, expected):" \
        "    assert utils.progress_str(n, total) == expected" \
        "" \
        "" \
        "def test_progress_str_zero_division_error():" \
        "    with pytest.raises(ZeroDivisionError):" \
        "        utils.progress_str(100, 0)" \
        "" \
        "" \
        "def test_progress_str_input_error():" \
        "    with pytest.raises(exceptions.InputError):" \
        "        utils.progress_str(100, 50)" \
        "" \
        "" \
        "# Test rle()" \
        "rle = {" \
        "    'None': ([], (None, None, None))," \
        "    'int': ([1, 0, 0, 1, 1, 1], ([0, 1, 3], [1, 2, 3], [1, 0, 1]))," \
        "    'string': (['a', 'b', 'b'], ([0, 1], [1, 2], ['a', 'b']))," \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('arr, expected'," \
        "                         list(rle.values())," \
        "                         ids=list(rle.keys()))" \
        "def test_rle(arr, expected):" \
        "    actual = utils.rle(arr)" \
        "    for a, e in zip(actual, expected):" \
        "        if e is not None:" \
        "            assert np.array_equal(a, np.array(e))" \
        "        else:" \
        "            assert a is e" \
        "" \
        "" \
        "# Test status()" \
        "def test_status(caplog):" \
        "    @utils.status(LOGGER)" \
        "    def foo():" \
        "        return 5" \
        "" \
        "    foo()" \
        "    assert 'Initiated: foo' in caplog.text" \
        "" \
        "" \
        "# Test timestamp_dir()" \
        "timestamp_dir = {" \
        "    'no desc': (None, TEST_STRFTIME)," \
        "    'desc': ('test', f'test-{TEST_STRFTIME}')" \
        "}" \
        "" \
        "" \
        "@pytest.mark.parametrize('desc, log_dir'," \
        "                         list(timestamp_dir.values())," \
        "                         ids=list(timestamp_dir.keys()))" \
        "def test_timestamp_dir(patch_strftime, desc, log_dir):" \
        "    base_dir = Path('/test1/test2')" \
        "    assert utils.timestamp_dir(base_dir, desc) == base_dir / log_dir" \
        "" \
        "" \
        "# Test warning_format()" \
        "def test_warning_format(patch_datetime):" \
        "    utils.warning_format()" \
        "    with pytest.warns(UserWarning):" \
        "        warnings.warn('test', UserWarning)" \
        > "${TEST_PATH}test_utils.py"
}


utils() {
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Package Utilities Module' \
        "" \
        '"""' \
        "import logging" \
        "import logging.config" \
        "import functools" \
        "import operator" \
        "from pathlib import Path" \
        "import time" \
        "from typing import Any, Dict, List, Optional, Tuple, Union" \
        "import warnings" \
        "" \
        "import matplotlib.pyplot as plt" \
        "import numpy as np" \
        "" \
        "from ${SOURCE_DIR}.pkg_globals import FONT_SIZE, TIME_FORMAT" \
        "from ${SOURCE_DIR}.exceptions import InputError" \
        "" \
        "" \
        "def docker_secret(secret_name: str) -> Optional[str]:" \
        '    """' \
        "    Read Docker secret file." \
        "" \
        "    :param secret_name: name of secrete to retrieve" \
        "    :return: contents of secrete file" \
        '    """' \
        "    try:" \
        "        with open(f'/run/secrets/{secret_name}', 'r') as f:" \
        "            return f.read().strip('\n')" \
        "    except IOError:" \
        "        return None" \
        "" \
        "" \
        "def logger_setup(file_path: Union[None, Path, str] = None," \
        "                 logger_name: str = 'package') -> logging.Logger:" \
        '    """' \
        "    Configure logger with console and file handlers." \
        "" \
        "    :param file_path: if supplied the path will be appended by a timestamp \\" \
        '        and ".log" else the default name of "info.log" will be saved in the \\' \
        "        location of the caller." \
        "    :param logger_name: name to be assigned to logger" \
        '    """' \
        "    if file_path:" \
        "        file_path = (Path(file_path).absolute()" \
        "                     if isinstance(file_path, str) else file_path.absolute())" \
        "        file_path = (timestamp_dir(file_path.parent," \
        "                                   file_path.name).with_suffix('.log'))" \
        "    else:" \
        "        file_path = 'info.log'" \
        "    config = {" \
        "        'version': 1," \
        "        'disable_existing_loggers': False," \
        "        'formatters': {" \
        "            'console': {" \
        "                'format': ('%(levelname)s - %(name)s -> Line: %(lineno)d <- '" \
        "                           '%(message)s')," \
        "            }," \
        "            'file': {" \
        "                'format': ('%(asctime)s - %(levelname)s - %(module)s.py -> '" \
        "                           'Line: %(lineno)d <- %(message)s')," \
        "            }," \
        "        }," \
        "        'handlers': {" \
        "            'console': {" \
        "                'class': 'logging.StreamHandler'," \
        "                'level': 'WARNING'," \
        "                'formatter': 'console'," \
        "                'stream': 'ext://sys.stdout'," \
        "            }," \
        "            'file': {" \
        "                'class': 'logging.handlers.RotatingFileHandler'," \
        "                'encoding': 'utf8'," \
        "                'level': 'DEBUG'," \
        "                'filename': file_path," \
        "                'formatter': 'file'," \
        "                'mode': 'w'," \
        "            }," \
        "        }," \
        "        'loggers': {" \
        "            'package': {" \
        "                'level': 'INFO'," \
        "                'handlers': ['console', 'file']," \
        "                'propagate': False," \
        "            }," \
        "        }," \
        "        'root': {" \
        "            'level': 'DEBUG'," \
        "            'handlers': ['console']," \
        "        }," \
        "    }" \
        "    logging.config.dictConfig(config)" \
        "    return logging.getLogger(logger_name)" \
        "" \
        "" \
        "def matplotlib_defaults():" \
        '    """Set matplotlib default values."""' \
        "    params = {" \
        "        'axes.labelsize': FONT_SIZE['label']," \
        "        'axes.titlesize': FONT_SIZE['title']," \
        "        'figure.titlesize': FONT_SIZE['super_title']," \
        "        'patch.edgecolor': 'black'," \
        "        'patch.force_edgecolor': True," \
        "    }" \
        "    plt.rcParams.update(params)" \
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
        "def progress_str(n: int," \
        "                 total: int,"\
        "                 msg: Union[None, str] = 'Progress') -> str:" \
        '    """' \
        "    Generate progress percentage message." \
        "" \
        "    :param n: number of current item" \
        "    :param total: total number of items" \
        "    :param msg: message to prepend to progress percentage" \
        '    """' \
        "    if total == 0:" \
        "        raise ZeroDivisionError('Parameter \`total\` may not be equal to zero.')" \
        "    if n > total:" \
        "        raise InputError(" \
        "            expression='n > total'," \
        "            message='Current item value \`n\` must be less than total.')" \
        "    progress_msg = f'\r{msg}: {n / total: .1%}'" \
        "    return progress_msg if n < total else progress_msg + '\n\n'" \
        "" \
        "" \
        "def rle(arr: Union[List[Any], np.ndarray]) \\" \
        "        -> Union[Tuple[np.ndarray, ...], Tuple[None, ...]]:" \
        '    """' \
        "    Run Length Encode provided array." \
        "" \
        "    :param arr: array to be encoded" \
        "    :return: Start Indices for code, Length of code, Value of code" \
        '    """' \
        "    arr = np.array(arr) if not isinstance(arr, np.ndarray) else arr" \
        "    vec = arr.flatten() if arr.ndim > 1 else arr" \
        "    n = vec.size" \
        "    if n == 0:" \
        "        return None, None, None" \
        "    switch_idx = np.nonzero(vec[1:] != vec[:-1])[0] + 1" \
        "    ids = np.r_[0, switch_idx]" \
        "    lengths = np.diff(np.r_[ids, n])" \
        "    return ids, lengths, vec[ids]" \
        "" \
        "" \
        "def status(status_logger: logging.Logger):" \
        '    """' \
        "    Decorator to issue logging statements and time function execution." \
        "" \
        "    :param status_logger: name of logger to record status output" \
        '    """' \
        "    def status_decorator(func):" \
        "        @functools.wraps(func)" \
        "        def wrapper(*args, **kwargs):" \
        "            name = func.__name__" \
        "            status_logger.info(f'Initiated: {name}')" \
        "            start = time.time()" \
        "            result = func(*args, **kwargs)" \
        "            end = time.time()" \
        "            status_logger.info(f'Completed: {name} -> {end - start:0.3g}s')" \
        "            return result" \
        "" \
        "        return wrapper" \
        "" \
        "    return status_decorator" \
        "" \
        "" \
        "def timestamp_dir(base_dir: Path, desc: Optional[str] = None):" \
        '    """' \
        "    Generate path to new directory with a timestamp." \
        "" \
        "    :param base_dir: path to base directory" \
        "    :param desc: run description" \
        "    :return: file path with timestamp and optional description" \
        '    """' \
        "    desc = '' if desc is None else f'{desc}-'" \
        "    return base_dir / time.strftime(f'{desc}{TIME_FORMAT}')" \
        "" \
        "" \
        "def warning_format():" \
        '    """' \
        "    Set warning output message format." \
        "" \
        "    ..note:: For new formats add helper functions then update the \\" \
        "        \`warnings.formatwarning\` call." \
        '    """' \
        "    def message_only(message, category, filename, lineno, line=''):" \
        "        return f'{message}\n'" \
        "" \
        "    warnings.formatwarning = message_only" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    pass" \
        > "${SRC_PATH}utils.py"
}


yapf_ignore() {
    printf "%s\n" \
        "*/*.egg-info/" \
        "*/data/" \
        "*/docker/" \
        "*/docs/*/" \
        "*/htmlcov/" \
        "*/.ipynb_checkpoints/" \
        "*/notebooks/" \
        "*/profiles/" \
        "*/wheels/" \
        "" \
    > "${MAIN_DIR}${FILE_SEP}.yapfignore"
}


directories
cli
conftest
constructor_pkg
constructor_test
db
docker_compose
docker_ignore
docker_python
docker_pytorch
docker_tensorflow
exceptions
git_attributes
git_config
git_ignore
mongo_init
pkg_globals
license
makefile
manifest
pull_request_template
readme
release_history
requirements
secret_db_database
secret_db_init_password
secret_db_init_username
secret_db_password
secret_db_username
setup_cfg
setup_py
test_cli
test_conftest
test_db
test_utils
utils
yapf_ignore
git_init
