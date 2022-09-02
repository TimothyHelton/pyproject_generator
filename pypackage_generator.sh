#! /bin/bash

: "${AUTHOR:=EnterAuthorName}"
: "${EMAIL:=EnterAuthorEmail}"
: "${PYTHON_VERSION:=3.10}"
: "${PKG_VERSION:=0.1.0}"

###############################################################################

# Source Environment Variables
if [ -f envfile ]; then
    source envfile
else
    echo "Environment variable file (envfile) not found."
    echo "Default values will be used."
fi

MAIN_DIR=${1:?"Specify a package name"}
SOURCE_DIR="${2:-$1}"
: "${DATA_DIR:=data}"
: "${DOCKER_DIR:=docker}"
: "${DOCS_DIR:=docs}"
: "${FILE_SEP:=/}"
: "${HOST_USER:="$USER"}" \
: "${HOST_GROUP_ID:=$(id -g "$HOST_USER")}" \
: "${HOST_USER_ID:=$(id -u "$HOST_USER")}" \
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

ROOT_PATH="${MAIN_DIR}${FILE_SEP}"
DOCKER_PATH="${ROOT_PATH}${DOCKER_DIR}${FILE_SEP}"
SCRIPTS_PATH="${ROOT_PATH}${SCRIPTS_DIR}${FILE_SEP}"
SECRETS_PATH="${DOCKER_PATH}${SECRETS_DIR}${FILE_SEP}"
SRC_PATH="${ROOT_PATH}${SOURCE_DIR}${FILE_SEP}"
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
        > "${ROOT_PATH}.coveragerc"
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
        mkdir "${ROOT_PATH}${dir}"
    done
    # Secrets directory
    mkdir "${SECRETS_PATH}"
    # Sphinx Documentation directory
    mkdir -p "${ROOT_PATH}docs${FILE_SEP}_build${FILE_SEP}html"
    # Test directory
    mkdir "${SRC_PATH}${TEST_DIR}"
}


docker_compose() {
    printf "%s\n" \
        "services:" \
        "" \
        "  nginx:" \
        "    container_name: \${COMPOSE_PROJECT_NAME:-default}_${MAIN_DIR}_nginx" \
        "    env_file:" \
        "        .env" \
        "    environment:" \
        "      PORT_NGINX: \${PORT_NGINX}" \
        "    image: nginx:alpine" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - '\${PORT_NGINX}:80'" \
        "    restart: always" \
        "    volumes:" \
        "      - ../docs/_build/html:/usr/share/nginx/html:ro" \
        "" \
        "  python:" \
        "    container_name: \${COMPOSE_PROJECT_NAME:-default}_${MAIN_DIR}_python" \
        "    build:" \
        "      context: .." \
        "      dockerfile: docker/\${ENVIRONMENT}.Dockerfile" \
        "    env_file:" \
        "        .env" \
        "    environment:" \
        "      - ENVIRONMENT=\${ENVIRONMENT}" \
        "      - PORT_GOOGLE=\${PORT_GOOGLE}" \
        "      - PORT_JUPYTER=\${PORT_JUPYTER}" \
        "      - PORT_PROFILE=\${PORT_PROFILE}" \
        "    image: ${MAIN_DIR}_python" \
        "    networks:"\
        "      - ${MAIN_DIR}-network" \
        "    ports:" \
        "      - \${PORT_GOOGLE}:6006" \
        "      - \${PORT_JUPYTER}:\${PORT_JUPYTER}" \
        "      - \${PORT_PROFILE}:\${PORT_PROFILE}" \
        "    restart: always" \
        "    secrets:" \
        "      - package" \
        "    tty: true" \
        "    volumes:" \
        "      - ..:/usr/src/${MAIN_DIR}" \
        "      - ${MAIN_DIR}-secret:/usr/src/${MAIN_DIR}/docker/secrets" \
        "" \
        "networks:" \
        "  ${MAIN_DIR}-network:" \
        "    name: \${COMPOSE_PROJECT_NAME:-default}-${MAIN_DIR}-network" \
        "" \
        "secrets:" \
        "  package:" \
        "    file: secrets/package.txt" \
        "" \
        "volumes:" \
        "  ${MAIN_DIR}-db:" \
        "    name: \${COMPOSE_PROJECT_NAME:-default}-${MAIN_DIR}-db" \
        "  ${MAIN_DIR}-secret:" \
        "" \
        > "${DOCKER_PATH}docker-compose.yaml"
}


docker_config_py() {
    script_name=${SCRIPTS_PATH}"docker_config.py"
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        '""" Docker Configuration Module' \
        "" \
        '"""' \
        "from enum import Enum" \
        "import logging" \
        "from pathlib import Path" \
        "from typing import Optional" \
        "" \
        "import yaml" \
        "" \
        "from ${SOURCE_DIR}.pkg_globals import PACKAGE_ROOT" \
        "" \
        "logger = logging.getLogger('package')" \
        "" \
        "" \
        "class ComposeService(Enum):" \
        '    """Implemented Docker Compose services."""' \
        "    LATEX = 'latex'" \
        "    MONGO = 'mongo'" \
        "    NGINX = 'nginx'" \
        "    POSTGRES = 'postgres'" \
        "    PGADMIN = 'pgadmin'" \
        "    PYTHON = 'python'" \
        "" \
        "" \
        "class ComposeConfiguration:" \
        '    """' \
        "    Docker Compose Configuration Class" \
        "" \
        "    :Attributes:" \
        "" \
        "    - **filepath**: *Path* Path to Docker Compose configuration file" \
        '    """' \
        "    default_filepath = PACKAGE_ROOT / 'docker' / 'docker-compose.yaml'" \
        "" \
        "    def __init__(self, filepath: Optional[Path] = None):" \
        "        self.filepath = filepath if filepath else self.default_filepath" \
        "        with open(self.filepath, 'r') as f:" \
        "            self._config = yaml.safe_load(f)" \
        "        logger.debug('Initial Docker Compose Configuration:\n\n%s'" \
        "                     % self._config)" \
        "" \
        "        self._container_prefix = (" \
        "            self._config['services']['python']['container_name']" \
        "            .rsplit('_', 1)[0])" \
        "        self._package = self._container_prefix.rsplit('}_', 1)[1]" \
        "        self._network = f'{self._package}-network'" \
        "        self._volume_db = f'{self._package}-db'" \
        "        self._volume_secret = f'{self._package}-secret'" \
        "        self._working_dir = f'/usr/src/{self._package}'" \
        "" \
        "        self._mask_secrets = [" \
        "            f'{self._volume_secret}:{self._working_dir}/docker/secrets'," \
        "        ]" \
        "" \
        "        self._docker_dir = PACKAGE_ROOT / 'docker'" \
        "        self._docker_secrets_dir = self._docker_dir / 'secrets'" \
        "        self._mongo_init_dir = self._docker_dir / 'mongo_init'" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return (f'{type(self).__name__}('" \
        "                f'filepath={self.filepath!r}'" \
        "                f')')" \
        "" \
        "    @property" \
        "    def config(self):" \
        '        """Docker Compose configuration."""' \
        "        return self._config" \
        "" \
        "    def _add_secrets(self):" \
        '        """Add database secrets."""' \
        "        secrets = {" \
        "            'db-database': {'file': 'secrets/db_database.txt'}," \
        "            'db-password': {'file': 'secrets/db_password.txt'}," \
        "            'db-username': {'file': 'secrets/db_username.txt'}," \
        "            'db-init-password': {'file': 'secrets/db_init_password.txt'}," \
        "            'db-init-username': {'file': 'secrets/db_init_username.txt'}," \
        "        }" \
        "        self._config['secrets'] = {" \
        "            **self._config.get('secrets', {})," \
        "            **secrets," \
        "        }" \
        "        self._config['services']['python']['secrets'] = [" \
        "            'db-database'," \
        "            'db-password'," \
        "            'db-username'," \
        "            'db-init-password'," \
        "            'db-init-username'," \
        "        ]" \
        "" \
        "    def _add_db_volume(self):" \
        '        """Add database volume."""' \
        "        self._config['volumes'][self._volume_db] = {" \
        "            'name': f'{self._container_prefix}-db'" \
        "        }" \
        "" \
        "    def _add_latex(self):" \
        '        """Add LaTeX service to configuration."""' \
        "        self._config['services']['latex'] = {" \
        "            'container_name': f'{self._container_prefix}_latex'," \
        "            'image': 'blang/latex'," \
        "            'networks': [self._network]," \
        "            'restart': 'always'," \
        "            'tty': True," \
        "            'volumes': [" \
        "                f'..:/usr/src/{self._package}'," \
        "                *self._mask_secrets," \
        "            ]," \
        "            'working_dir': self._working_dir," \
        "        }" \
        "" \
        "    def _add_mongo(self):" \
        '        """Add MongoDB service to configuration."""' \
        "        self._config['services']['mongo'] = {" \
        "            'container_name':" \
        "            f'{self._container_prefix}_mongo'," \
        "            'image':" \
        "            'mongo'," \
        "            'env_file':" \
        "            '.env'," \
        "            'environment': {" \
        "                'MONGO_INITDB_ROOT_PASSWORD': '/run/secrets/db-init-password'," \
        "                'MONGO_INITDB_ROOT_USERNAME': '/run/secrets/db-init-username'," \
        "                'PORT_MONGO': '\${PORT_MONGO}'," \
        "            }," \
        "            'networks': [self._network]," \
        "            'ports': [" \
        "                '\$PORT_MONGO:27017'," \
        "            ]," \
        "            'restart':" \
        "            'always'," \
        "            'secrets': [" \
        "                'db-init-password'," \
        "                'db-init-username'," \
        "            ]," \
        "            'volumes': [" \
        "                f'{self._volume_db}:/var/lib/mongo/data'," \
        "                './mongo_init:/docker-entrypoint-initdb.d'," \
        "                *self._mask_secrets" \
        "            ]," \
        "        }" \
        "        self._update_depends_on(ComposeService.MONGO)" \
        "        self._add_secrets()" \
        "        self._mongo_init_dir.mkdir(parents=True, exist_ok=True)" \
        "        self._mongo_create_admin()" \
        "        self._mongo_create_user()" \
        "" \
        "    def _mongo_create_admin(self):" \
        '        """Write script file that creates MongoDB Admin user."""' \
        "        text = [" \
        "            '#!/bin/bash'," \
        "            '# create_admin.sh'," \
        "            ''," \
        "            '# Create Administrator'," \
        "            'mongo admin -u \$MONGO_INITDB_ROOT_USERNAME '" \
        "            '-p \$MONGO_INITDB_ROOT_PASSWORD << EOF'," \
        "            '    db.createUser({user: \"admin\", pwd: \"admin\", '" \
        "            'roles: [\"root\"]});'" \
        "            'EOF'," \
        "            ''," \
        "        ]" \
        "        with open(self._mongo_init_dir / 'create_admin', 'w') as f:" \
        "            f.writelines('\n'.join(text))" \
        "" \
        "    def _mongo_create_user(self):" \
        '        """Write script file that creates MongoDB user."""' \
        "        text = [" \
        "            '#!/bin/bash'," \
        "            ''," \
        "            'help_function()'," \
        "            '{'," \
        "            '   echo ""'," \
        "            '   echo \"Script will create a MongoDB database user with '" \
        "            'supplied password.\"'," \
        "            '   echo \"\"'," \
        "            '   echo \"Usage: \$0 -u username -p password -db database\"'," \
        "            '   echo -e \"\t-u username\"'," \
        "            '   echo -e \"\t-p password\"'," \
        "            '   echo -e \"\t-d database\"'," \
        "            '  exit 1'," \
        "            '}'," \
        "            ''," \
        "            'while getopts \"u:p:d:\" opt'," \
        "            'do'," \
        "            '    case \"\$opt\" in'," \
        "            '      u ) username=\"\$OPTARG\" ;;'," \
        "            '      p ) password=\"\$OPTARG\" ;;'," \
        "            '      d ) database=\"\$OPTARG\" ;;'," \
        "            '      ? ) help_function ;;'," \
        "            '   esac'," \
        "            'done'," \
        "            ''," \
        "            '# Print help_function in case parameters are empty'," \
        "            'if [ -z \"\$username\" ] || [ -z \"\$password\" ] || '" \
        "            '[ -z \"\$database\" ]'," \
        "            'then'," \
        "            '   echo ""'," \
        "            '   echo \"Missing Parameters: All parameters are required.\";'," \
        "            '   help_function'," \
        "            'fi'," \
        "            ''," \
        "            '# Create User'," \
        "            'mongo admin -u \$MONGO_INITDB_ROOT_USERNAME '" \
        "            '-p \$MONGO_INITDB_ROOT_PASSWORD << EOF'," \
        "            '    db.createUser({user: \"\${username}\", pwd: \"\${password}\", '" \
        "            'roles: [\"readWrite\"]});'" \
        "            'EOF'," \
        "            ''," \
        "            ]" \
        "        with open(self._mongo_init_dir / 'create_user.sh', 'w') as f:" \
        "            f.writelines('\n'.join(text))" \
        "" \
        "    def _add_nginx(self):" \
        '        """Add NGINX service to configuration."""' \
        "        self._config['services']['nginx'] = {" \
        "            'container_name': f'{self._container_prefix}_nginx'," \
        "            'env_file': '.env'," \
        "            'environment': {" \
        "                'PORT_NGINX': '\${PORT_NGINX}'," \
        "            }," \
        "            'image': 'nginx:alpine'," \
        "            'networks': [self._network]," \
        "            'ports': [" \
        "                '\${PORT_NGINX}:80'," \
        "            ]," \
        "            'restart': 'always'," \
        "            'volumes': [" \
        "                '../docs/_build/html:/usr/share/nginx/html:ro'," \
        "                *self._mask_secrets," \
        "            ]," \
        "        }" \
        "" \
        "    def _add_postgres(self):" \
        '        """Add PostgreSQL service to configuration."""' \
        "        self._config['services']['postgres'] = {" \
        "            'container_name': f'{self._container_prefix}_postgres'," \
        "            'env_file': '.env'," \
        "            'image': 'postgres:alpine'," \
        "            'environment': {" \
        "                'PORT_POSTGRES': '\${PORT_POSTGRES}'," \
        "                'POSTGRES_DB_FILE': '/run/secrets/db-database'," \
        "                'POSTGRES_PASSWORD_FILE': '/run/secrets/db-password'," \
        "                'POSTGRES_USER_FILE': '/run/secrets/db-username'," \
        "            }," \
        "            'networks': [self._network]," \
        "            'ports': [" \
        "                '\$PORT_POSTGRES:5432'," \
        "            ]," \
        "            'restart': 'always'," \
        "            'secrets': [" \
        "                'db-database'," \
        "                'db-password'," \
        "                'db-username'," \
        "            ]," \
        "            'volumes': [" \
        "                f'{self._volume_db}:/var/lib/postgresql/data'," \
        "                *self._mask_secrets," \
        "            ]," \
        "        }" \
        "        self._update_depends_on(ComposeService.POSTGRES)" \
        "        self._add_secrets()" \
        "" \
        "    def _add_pgadmin(self):" \
        '        """Add PGAdmin service to configuration."""' \
        "        self._config['services']['pgadmin'] = {" \
        "            'container_name':" \
        "            f'{self._container_prefix}_pgadmin'," \
        "            'env_file':" \
        "            '.env'," \
        "            'environment': {" \
        "                'PGADMIN_DEFAULT_EMAIL':" \
        "                '\${PGADMIN_DEFAULT_EMAIL:-pgadmin@pgadmin.org}'," \
        "                'PGADMIN_DEFAULT_PASSWORD':" \
        "                '\${PGADMIN_DEFAULT_PASSWORD:-admin}'," \
        "                'PORT_DATABASE_ADMINISTRATION':" \
        "                '\$PORT_DATABASE_ADMINISTRATION'," \
        "            }," \
        "            'external_links': [" \
        "                f'{self._package}_postgres:{self._package}_postgres'," \
        "            ]," \
        "            'image':" \
        "            'dpage/pgadmin4'," \
        "            'depends_on': ['postgres']," \
        "            'networks': [self._network]," \
        "            'ports': [" \
        "                '\$PORT_DATABASE_ADMINISTRATION:80'," \
        "            ]," \
        "            'volumes': [" \
        "                *self._mask_secrets," \
        "            ]," \
        "        }" \
        "" \
        "    def _update_depends_on(self, service_name: ComposeService):" \
        '        """Update the Python service `depends_on` tag."""' \
        "        py_tag = self._config['services']['python']" \
        "        py_tag['depends_on'] = (py_tag.get('depends_on', [])" \
        "                                + [service_name.value])" \
        "" \
        "    def add_gpu(self):" \
        '        """Add GPU configuration to Python container."""' \
        "        py_service = self._config['services']['python']" \
        "        py_service['build']['shm_size'] = '1g'" \
        "        py_service['deploy'] = {" \
        "            'resources': {" \
        "                'reservations': {" \
        "                    'devices': [" \
        "                        {'capabilities': ['gpu']}," \
        "                    ]," \
        "                }," \
        "            }," \
        "        }" \
        "        py_service['ipc'] = 'host'" \
        "        py_service['shm_size'] = '16g'" \
        "        py_service['ulimits'] = {'memlock': -1}" \
        "" \
        "    def add_service(self, service_name: ComposeService):" \
        '        """' \
        "        Add service to configuration." \
        "" \
        "        :param service_name: Name of the Docker service to add" \
        '        """' \
        "        service_name = service_name.value" \
        "        getattr(self, f'_add_{service_name}')()" \
        "        logger.debug('Docker service added: %s' % service_name)" \
        "" \
        "    def remove_service(self, service_name: ComposeService):" \
        '        """' \
        "        Remove service from configuration." \
        "" \
        "        :param service_name: Name of the Docker service to remove" \
        '        """' \
        "        service_name = service_name.value" \
        "        del self._config['services'][service_name]" \
        "        logger.debug('Docker service removed: %s' % service_name)" \
        "" \
        "    def write(self, des: Optional[Path] = None):" \
        '        """' \
        "        Write Docker Compose configuration YAML file." \
        "" \
        "        :param des: Destination path to write configuration (default: the \\" \
        "            initial filepath supplied during instantiation)" \
        '        """' \
        "        des = des if des else self.filepath" \
        "        with open(des, 'w') as f:" \
        "            yaml.dump(self._config, f)" \
        "        logger.debug('Docker Compose Configuration file written: %s' % des)" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    config = ComposeConfiguration()" \
        "    services = (" \
        "        ComposeService.MONGO," \
        "    )" \
        "    for s in services:" \
        "        config.add_service(s)" \
        "    config.add_gpu()" \
        "    config.write()" \
        "" \
        > "${script_name}"
    chmod u+x ./"${script_name}"
}


docker_env_link() {
    ln "${ROOT_PATH}usr_vars" "${DOCKER_PATH}.env"
}


docker_ignore() {
    printf "%s\n" \
        "*.egg-info" \
        ".idea" \
        ".pytest_cache" \
        "data" \
        ".pytest" \
        "wheels" \
        "" \
        > "${ROOT_PATH}.dockerignore"
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
        "\t#&& pip3 install --no-cache-dir -r requirements.txt \\\\" \
        "\t&& pip3 install -e .[all] \\\\" \
        "\t&& rm -rf /tmp/* \\" \
        "\t&& rm -rf /var/lib/apt/lists/* \\" \
        "\t&& apt clean -y" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${DOCKER_PATH}python.Dockerfile"
}


docker_pytorch() {
    printf "%b\n" \
        "FROM nvcr.io/nvidia/pytorch:" \
        "" \
        "ENV TORCH_HOME=/usr/src/${MAIN_DIR}/cache" \
        "" \
        "WORKDIR /usr/src/${MAIN_DIR}" \
        "" \
        "COPY . ." \
        "" \
        "RUN pip install -e .[all] \\" \
        "\t&& apt update -y \\" \
        "\t# && apt -y upgrade \\" \
        "\t&& apt install -y\\" \
        "\t\tfonts-humor-sans \\" \
        "\t# && conda update -y conda \\" \
        "\t# && while read requirement; do conda install --yes \${requirement}; done < requirements_pytorch.txt \\" \
        "\t&& rm -rf /tmp/* \\" \
        "\t&& rm -rf /var/lib/apt/lists/* \\" \
        "\t&& apt clean -y" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${DOCKER_PATH}pytorch.Dockerfile"
}


docker_tensorflow() {
    printf "%b\n" \
        "FROM nvcr.io/nvidia/tensorflow:" \
        "" \
        "WORKDIR /usr/src/${SOURCE_DIR}" \
        "" \
        "COPY . ." \
        "" \
        "RUN cd /opt \\\\" \
        "\t&& apt update -y \\\\" \
        "\t#&& apt upgrade -y \\\\  Do not upgrade NVIDIA image OS" \
        "\t&& apt install -y \\\\" \
        "\t\tapt-utils \\\\" \
        "\t\tfonts-humor-sans \\" \
        "\t&& cd /usr/src/${SOURCE_DIR} \\\\" \
        "\t&& pip install --upgrade pip \\\\" \
        "\t&& pip install -e .[all] \\\\" \
        "\t&& rm -rf /tmp/* \\\\" \
        "\t&& rm -rf /var/lib/apt/lists/* \\\\" \
        "\t&& apt clean" \
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
        "# Docker files" \
        "docker/.env" \
        "docker/secrets/*" \
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
        "${ROOT_PATH}.idea${FILE_SEP}*" \
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
        "" \
        "# User specific files" \
        "usr_vars" \
        "" \
        > "${ROOT_PATH}.gitignore"
}


git_init() {
    git init
    git add --all
    git commit -m "Initial Commit"
}


makefile() {
    printf "%b\n" \
        "PROJECT=${MAIN_DIR}" \
        "" \
        "ifeq (, \$(wildcard docker/.env))" \
        "        \$(shell scripts/create_usr_vars.sh)" \
        "        \$(info #######################################################)" \
        "        \$(info # Created user variables file: usr_vars #)" \
        "        \$(info #######################################################)" \
        "endif" \
        "include usr_vars" \
        "export" \
        "" \
        "ifeq (\"\$(shell uname -s)\", \"Linux*\")" \
        "\tBROWSER=/usr/bin/firefox" \
        "else ifeq (\"\$(shell uname -s)\", \"Linux\")" \
        "\tBROWSER=/usr/bin/firefox" \
        "else" \
        "\tBROWSER=open" \
        "endif" \
        "" \
        "CONTAINER_PREFIX:=\$(COMPOSE_PROJECT_NAME)_\$(PROJECT)" \
        "DOCKER_IMAGE=\$(shell head -n 1 docker/\$(ENVIRONMENT).Dockerfile | cut -d ' ' -f 2)" \
        "PKG_MANAGER=pip" \
        'PROFILE_PY:=""' \
        "PROFILE_PROF:=\$(notdir \$(PROFILE_PY:.py=.prof))" \
        "PROFILE_PATH:=profiles/\$(PROFILE_PROF)" \
        "SRC_DIR=/usr/src/${SOURCE_DIR}" \
        "TEX_WORKING_DIR=\${SRC_DIR}/\${TEX_DIR}" \
        "USER:=\$(shell echo \$\${USER%%@*})" \
        "USER_ID:=\$(shell id -u \$(USER))" \
        "VERSION=\$(shell echo \$(shell cat ${SOURCE_DIR}/__init__.py | grep \"^__version__\" | cut -d = -f 2))" \
        "" \
        ".PHONY: docs format-style upgrade-packages" \
        "" \
        "deploy: docker-up" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python pip3 wheel --wheel-dir=wheels ." \
        "\tgit tag -a v\$(VERSION) -m \"Version \$(VERSION)\"" \
        "\t@echo" \
        "\t@echo" \
        "\t@echo Enter the following to push this tag to the repository:" \
        "\t@echo git push origin v\$(VERSION)" \
        "" \
        "docker-down:" \
        "\tdocker compose -f docker/docker-compose.yaml down" \
        "" \
        "docker-images-update:" \
        "\tdocker image ls | grep -v REPOSITORY | cut -d ' ' -f 1 | xargs -L1 docker pull" \
        ""\
        "docker-rebuild: setup.py" \
        "\tdocker compose -f docker/docker-compose.yaml up -d --build" \
        "" \
        "docker-up:" \
        "\tdocker compose -f docker/docker-compose.yaml up -d" \
        "" \
        "docker-update-config: docker-update-compose-file docker-rebuild" \
        "\t@echo \"Docker environment updated successfully\"" \
        "" \
        "docker-update-compose-file:" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python scripts/docker_config.py" \
        "" \        "docs: docker-up" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \"pip install -e .[docs] && cd docs && make html\"" \
        "\t\${BROWSER} http://localhost:\$(PORT_NGINX) &" \
        "" \
        "docs-init: docker-up" \
        "\tfind docs -maxdepth 1 -type f -delete" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
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
        "\tdocker compose -f docker/docker-compose.yaml restart nginx" \
        "\tgit fetch" \
        "\tgit checkout origin/master -- docs/" \
        "" \
        "docs-view: docker-up" \
        "\t\${BROWSER} http://localhost:\$(PORT_NGINX) &" \
        "" \
        "format-style: docker-up" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python yapf -i -p -r --style \"pep8\" \${SRC_DIR}" \
        "" \
        "getting-started: secret-templates docs-init" \
        "\tmkdir -p cache" \
        "\tmkdir -p htmlcov" \
        "\tmkdir -p notebooks" \
        "\tmkdir -p profiles" \
        "\tmkdir -p wheels" \
        "" \
        "ipython: docker-up" \
        "\tdocker container exec -it \$(CONTAINER_PREFIX)_python ipython" \
        "" \
        "latexmk: docker-up" \
        "\tdocker container exec -w \$(TEX_WORKING_DIR) \$(CONTAINER_PREFIX)_latex \\\\" \
        "\t\t/bin/bash -c \"latexmk -f -pdf \$(TEX_FILE) && latexmk -c\"" \
        "" \
        "mongo-create-admin: docker-up" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_mongo ./docker-entrypoint-initdb.d/create_admin.sh" \
        "" \
        "mongo-create-user: docker-up" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_mongo ./docker-entrypoint-initdb.d/create_user.sh -u \$(DB_USERNAME) -p \$(DB_PASSWORD) -d \$(DB)" \
        "" \
        "notebook: docker-up notebook-server" \
        "\t@echo \"\\\\n\\\\n\\\\n##################################################\"" \
        "\t@echo \"\\\\nUse this link on the host to access the Jupyter server.\"" \
        "\t@docker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"jupyter notebook list \\\\" \
        "\t\t\t | grep -o '^http\S*' \\\\" \
        "\t\t\t | sed -e 's/\(http:\/\/\).*\(:\)/localhost:/'\"" \
        "\t@echo \"\\\\n##################################################\"" \
        "" \
        "notebook-server: notebook-stop-server" \
        "\t@docker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"jupyter lab \\\\" \
        "\t\t\t\t--allow-root \\\\" \
        "\t\t\t\t--ip=0.0.0.0 \\\\" \
        "\t\t\t\t--no-browser \\\\" \
        "\t\t\t\t--port=\$(PORT_JUPYTER) \\\\" \
        "\t\t\t\t&\"" \
        "" \
        "notebook-stop-server:" \
        "\t@-docker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \"jupyter notebook stop \$(PORT_JUPYTER)\"" \
        "" \
        "package-dependencies: docker-up" \
        "\tprintf \"%s\\\\n\" \\\\" \
        "\t\t\"# ${PROJECT} Version: \$(VERSION)\" \\\\" \
        "\t\t\"# From NVIDIA NGC CONTAINER: \$(DOCKER_IMAGE)\" \\\\" \
        "\t\t\"#\" \\\\" \
        "\t> requirements.txt" \
        "ifeq (\"\${PKG_MANAGER}\", \"conda\")" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"conda list --export >> requirements.txt \\\\" \
        "\t\t\t && sed -i -e '/^\$(PROJECT)/ s/./# &/' requirements.txt\"" \
        "else ifeq (\"\${PKG_MANAGER}\", \"pip\")" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"pip freeze >> requirements.txt \\\\" \
        "\t\t\t && sed -i -e '/^-e/d' requirements.txt\"" \
        "endif" \
        "" \
        "pgadmin: docker-up" \
        "\t\${BROWSER} http://localhost:\$(PORT_DATABASE_ADMINISTRATION) &" \
        "" \
        "profile: docker-up" \
        "\t@docker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"python -m cProfile -o \$(PROFILE_PATH) \$(PROFILE_PY)\"" \
        "psql: docker-up" \
        "\tdocker container exec -it \$(CONTAINER_PREFIX)_postgres \\\\" \
        "\t\tpsql -U \${POSTGRES_USER} \$(PROJECT)" \
        "" \
        "secret-templates:" \
        "\tcd docker/secrets \\" \
        "\t\t&& printf '%s' \"\$(PROJECT)\" > 'db_database.txt' \\" \
        "\t\t&& printf '%s' \"admin\" > 'db_init_password.txt' \\" \
        "\t\t&& printf '%s' \"admin\" > 'db_init_username.txt' \\" \
        "\t\t&& printf '%s' \"password\" > 'db_password.txt' \\" \
        "\t\t&& printf '%s' \"username\" > 'db_username.txt' \\" \
        "\t\t&& printf '%s' \"\$(PROJECT)\" > 'package.txt'" \
        "" \
        "snakeviz: docker-up profile snakeviz-server" \
        "\tsleep 0.5" \
        "\t\${BROWSER} http://0.0.0.0:\$(PORT_PROFILE)/snakeviz/ &" \
        "" \
        "snakeviz-server: docker-up" \
        "\t@docker container exec \\\\" \
        "\t\t-w /usr/src/\$(PROJECT)/profiles \\\\" \
        "\t\t\$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"snakeviz \$(PROFILE_PROF) \\\\" \
        "\t\t\t\t--hostname 0.0.0.0 \\\\" \
        "\t\t\t\t--port \$(PORT_PROFILE) \\\\" \
        "\t\t\t\t--server &\"" \
        "" \
        "test: docker-up format-style" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python py.test \$(PROJECT)" \
        "" \
        "test-coverage: test" \
        "\t\${BROWSER} htmlcov/index.html &"\
        "" \
        "update-nvidia-base-images: docker-up" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t./${SCRIPTS_DIR}/update_nvidia_tags.py \\\\" \
        "" \
        "upgrade-packages: docker-up" \
        "ifeq (\"\${PKG_MANAGER}\", \"pip\")" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"pip3 install -U pip \\\\" \
        "\t\t\t && pip3 freeze | \\\\" \
        "\t\t\t\tgrep -v \$(PROJECT) | \\\\" \
        "\t\t\t\tcut -d = -f 1 > requirements.txt \\\\" \
        "\t\t\t && pip3 install -U -r requirements.txt \\\\" \
        "\t\t\t && pip3 freeze > requirements.txt \\\\" \
        "\t\t\t && sed -i -e '/^-e/d' requirements.txt\"" \
        "else ifeq (\"\${PKG_MANAGER}\", \"conda\")" \
        "\tdocker container exec \$(CONTAINER_PREFIX)_python \\\\" \
        "\t\t/bin/bash -c \\\\" \
        "\t\t\t\"conda update conda \\\\" \
        "\t\t\t && conda update --all \\\\" \
        "\t\t\t && pip freeze > requirements.txt \\\\" \
        "\t\t\t && sed -i -e '/^-e/d' requirements.txt\"" \
        "endif" \
        > "${ROOT_PATH}Makefile"
}


manifest() {
    touch "${ROOT_PATH}MANIFEST.in"
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
        > "${ROOT_PATH}.github${FILE_SEP}PULL_REQUEST_TEMPLATE.md"
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
        "# ${SRC_DIR} Project" \
        "The ${SRC_DIR} project is <enter_description>." \
        "" \
        "## Getting Started" \
        "${SRC_DIR} is a fully functioning Python package that may be installed using" \
        "\`pip\`." \
        "Docker Images are built into the package and a Makefile provides an easy to call" \
        "repetitive commands." \
        "" \
        "### Makefile Code Completion" \
        "It's handy to have code completion when calling targets from the Makefile." \
        "To enable this feature add the following to your user profile file." \
        "- On Ubuntu this would be your \`~/.profile\` file." \
        "- On a Mac this would be you \`~/.bash_profile\` file." \
        "\`\`\`bash" \
        "complete -W \"\`grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_.-]*$//'\`\" make" \
        "\`\`\`" \
        "" \
        "### Clone the Repository" \
        "First, make a local copy of the project." \
        "After setting up SSH keys on GitHub call the following command to clone the" \
        "repository." \
        "\`\`\`bash" \
        "git clone <enter_path_to_repo>${SRC_DIR}.git" \
        "\`\`\`" \
        "A directory called \`${MAIN_DIR}\` will be created where the command was executed." \
        "This \`${MAIN_DIR}\` directory will be referred to as the \"package root directory\"" \
        "throughout the project." \
        "" \
        "### Initialize the Project" \
        "Some functionality of the package is created locally." \
        "Run the following command from the package root directory to finish setting up" \
        "the project." \
        "\`\`\`bash" \
        "make getting-started" \
        "\`\`\`" \
        "" \
        "### Jupyter Notebooks" \
        "While Jupyter notebooks are not ideal for source code, they can be powerful" \
        "when applied to path finding and creating training material." \
        "The ${MAIN_DIR} project is capable of creating a Jupyter server in the" \
        "Python container." \
        "Since the package root directory is mounted to the Docker container any changes" \
        "made on the client will persist on the host and vice versa." \
        "For consistency when creating notebooks please store them in the \`notebooks\`" \
        "directory." \
        "Call the following commands from the package root directory to start and stop" \
        "the Jupyter server." \
        "" \
        "#### Create a Notebook Server" \
        "\`\`\`bash" \
        "make notebook" \
        "\`\`\`" \
        "" \
        "#### Shutdown a Notebook Server" \
        "\`\`\`bash" \
        "make notebook-stop-server" \
        "\`\`\`" \
        "" \
        "### Test Framework" \
        "The ${MAIN_DIR_DIR} is configured to use the pytest test framework in conjunction with" \
        "coverage and the YAPF style linter." \
        "To run the tests and display a coverage report call the following command from" \
        "the package root directory." \
        "" \
        "#### Test Coverage" \
        "\`\`\`bash" \
        "make test-coverage" \
        "\`\`\`" \
        "" \
        "To only run the tests, and not display the coverage, call the following." \
        "" \
        "### Tests" \
        "\`\`\`bash" \
        "make test" \
        "\`\`\`" \
        "" \
        "#### Update Style" \
        "To only run the YAPF style linter call this command from the package root" \
        "directory." \
        "\`\`\`bash" \
        "make format-style" \
        "\`\`\`" \
        "" \
        "## Dependencies" \
        "Since the ${MAIN_DIR} utilizes NVIDIA optimized Docker images most " \
        "of the Python dependencies could be installed using PIP or Conda." \
        "The \`requirements.txt\` file contains a reference to the specific" \
        "base image used during development and a list of dependencies." \
        "" \
        "There is a make target to update the requirements file." \
        "" \
        "\`\`\`bash" \
        "make package-dependencies" \
        "\`\`\`" \
        "" \
        "## Documentation" \
        "The package also has an NGINX container to host interactive documentation." \
        "Calling the following commands from the package root directory will result in" \
        "a local web browser displaying the package HTML documentation." \
        "" \
        "### Build Documentation" \
        "\`\`\`bash" \
        "make docs" \
        "\`\`\`" \
        "" \
        "### View Documentation without Building" \
        "\`\`\`bash" \
        "make docs-view" \
        "\`\`\`" \
        "" \
        "## Profilers" \
        "Before refactoring it's usually a ***great*** idea to profile the code." \
        "The following methods describe the profilers that are available in the ${MAIN_DIR}" \
        "environment, and how to use them." \
        "" \
        "" \
        "### SNAKEVIZ Execution" \
        "To test an entire script just enter the following from the project root" \
        "directory." \
        "" \
        "#### Profile Script" \
        "\`\`\`bash" \
        "make snakeviz PROFILE_PY=script.py" \
        "\`\`\`" \
        "" \
        "### Memory Profiler" \
        "1. Open Jupyter Notebook" \
        "1. Load Extension" \
        "    - \`%load_ext memory_profiler\`" \
        "1. Run profiler" \
        "    - \`%memit enter_code_here\`" \
        "" \
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
        > "${ROOT_PATH}HISTORY.md"
}


requirements() {
    touch "${ROOT_PATH}requirements.txt"
}


secret_package() {
    printf "%s" \
        "${MAIN_DIR}" \
        > "${SECRETS_PATH}package.txt"
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
        "    --pycodestyle" \
        "testpaths =" \
        "    ${SOURCE_DIR}" \
        "" \
        > "${ROOT_PATH}setup.cfg"
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
        "    'mongo': {" \
        "        'pymongo'," \
        "    }," \
        "    'profile': {" \
        "        'memory_profiler'," \
        "        'snakeviz'," \
        "    }," \
        "    'postgres': {" \
        "        'psycopg2-binary'," \
        "        'sqlalchemy'," \
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
        "          'pandas'," \
        "          'pyyaml'," \
        "          'yapf'," \
        "      ]," \
        "      extras_require={" \
        "          'all': combine_dependencies(dependencies.keys())," \
        "          'build': combine_dependencies(('build', 'test'))," \
        "          'docs': combine_dependencies('docs')," \
        "          'jupyter': combine_dependencies('jupyter')," \
        "          'mongo': combine_dependencies(" \
        "              [x for x in dependencies if 'postgres' not in x])," \
        "          'postgres': combine_dependencies(" \
        "              [x for x in dependencies if 'mongo' not in x])," \
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
        > "${ROOT_PATH}setup.py"
}


sphinx_autodoc() {
    printf "%s\n" \
        "Package Modules" \
        "===============" \
        "" \
        ".. toctree::" \
        "    :maxdepth: 2" \
        "" \
        "cli" \
        "---" \
        ".. automodule:: cli" \
        "    :members:" \
        "    :show-inheritance:" \
        "    :synopsis: Package command line interface calls." \
        "" \
        "db" \
        "--" \
        ".. automodule:: db" \
        "    :members:" \
        "    :show-inheritance:" \
        "    :synopsis: Package database module." \
        "" \
        "utils" \
        "-----" \
        ".. automodule:: utils" \
        "    :members:" \
        "    :show-inheritance:" \
        "    :synopsis: Package utilities module." \
        "" \
        > "${DOCS_DIR}/package.rst"
}


sphinx_custom_css() {
    printf "%s\n" \
        ".wy-nav-content {" \
        "max-width: 1200px !important;" \
        "}" \
        > "${DOCS_DIR}/_static/custom.css"
}


sphinx_initialization() {
    source usr_vars
    docker container exec "${COMPOSE_PROJECT_NAME}_${MAIN_DIR}_python" \
        /bin/bash -c \
            "cd docs \
             && sphinx-quickstart -q \
                --project \"${MAIN_DIR}\" \
                --author \"${AUTHOR}\" \
                -v 0.1.0 \
                --ext-autodoc \
                --ext-viewcode \
                --makefile \
                --no-batchfile \
             && useradd -u ${HOST_USER_ID} ${HOST_USER} &> /dev/null || true \
             && groupadd ${HOST_USER} &> /dev/null || true \
             && chown -R ${HOST_USER}:${HOST_USER} *"
    docker compose -f docker/docker-compose.yaml restart nginx
    sphinx_autodoc
    sphinx_custom_css
    sphinx_links
    docker container exec "${COMPOSE_PROJECT_NAME}_${MAIN_DIR}_python" \
        yapf -i -p -r --style "pep8" docs
}


sphinx_links() {
    touch "${DOCS_DIR}/links.rst"
}


sphinx_update_config() {
    script_name=${SCRIPTS_PATH}"update_sphinx_config.py"
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Script to update Sphinx documentation configuration files.' \
        "" \
        '"""' \
        "import re" \
        "from pathlib import Path" \
        "" \
        "from ${SOURCE_DIR}.pkg_globals import PACKAGE_ROOT" \
        "" \
        "" \
        "def update_config():" \
        '    """Update the docs/config.py file."""' \
        "    conf_header = [" \
        "        'import os'," \
        "        'import sys'," \
        "        ''," \
        "        'from ${SOURCE_DIR} import __version__'," \
        "        ''," \
        "        \"sys.path.insert(0, os.path.abspath('../${SOURCE_DIR}'))\"," \
        "        ''," \
        "    ]" \
        "" \
        "    conf_links = [" \
        "        \"rst_epilog = ''\"," \
        "        ''," \
        "        '# Read all link targets from one file'," \
        "        \"with open('links.rst') as f:\"," \
        "        \"    rst_epilog += f.read()\"," \
        "    ]" \
        "" \
        "    with open(conf_path, 'r+') as f:" \
        "        text = f.read()" \
        "" \
        "        text = re.sub(r'0.1.0', '__version__', text)" \
        "        text = re.sub(r'alabaster', 'sphinx_rtd_theme', text)" \
        "        text = re.sub(r\"'_build'\", \"'_build', 'links.rst'\", text)" \
        "" \
        "        lines = text.split('\n')" \
        "        for n, line in enumerate(lines):" \
        "            if line.startswith('project ='):" \
        "                header_end = n" \
        "            if line.startswith('exclude_patterns = '):" \
        "                links_begin = n + 1" \
        "                break" \
        "" \
        "        lines = conf_header \\" \
        "            + lines[header_end:links_begin] \\" \
        "            + conf_links \\" \
        "            + lines[links_begin:] \\" \
        "            + [\"html_css_files=['custom.css']\", '']" \
        "" \
        "        f.seek(0)" \
        "        f.writelines('\n'.join(lines))" \
        "        f.truncate()" \
        "" \
        "" \
        "def update_index():" \
        '    """Update the docs/index.rst file."""' \
        "    with open(index_path, 'r+') as f:" \
        "        lines = f.readlines()" \
        "        for n, line in enumerate(lines):" \
        "            if line.startswith('Welcome'):" \
        "                header_end = n" \
        "            if line.endswith('Contents:\n'):" \
        "                toctree_end = n + 1" \
        "                break" \
        "        lines = lines[header_end:toctree_end] \\" \
        "            + ['\n   package\n'] \\" \
        "            + lines[toctree_end:]" \
        "        title = '${SOURCE_DIR} API'" \
        "        lines[0] = title + '\n'" \
        "        lines[1] = '=' * len(title)" \
        "" \
        "        f.seek(0)" \
        "        f.writelines(lines)" \
        "        f.truncate()" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    docs_dir = PACKAGE_ROOT / 'docs'" \
        "    conf_path = docs_dir / 'conf.py'" \
        "    index_path = docs_dir / 'index.rst'" \
        "" \
        "    update_config()" \
        "    update_index()" \
        "" \
        > "${script_name}"
    chmod u+x ./"${script_name}"
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
        "    'package': ('package', '${SOURCE_DIR}')," \
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


update_nvidia_tags() {
    script_name=${SCRIPTS_PATH}"update_nvidia_tags.py"
    printf "%s\n" \
        "${PY_SHEBANG}" \
        "${PY_ENCODING}" \
        '""" Script to update NVIDIA NGC Docker Tags.' \
        "" \
        '"""' \
        "import re" \
        "import urllib.request" \
        "" \
        "from ${SOURCE_DIR}.pkg_globals import PACKAGE_ROOT" \
        "" \
        "DOCKER_DIR = PACKAGE_ROOT / 'docker'" \
        "NVIDIA_NGC_URL = 'https://catalog.ngc.nvidia.com/orgs/nvidia/containers/'" \
        "REGEX = r'(?<=latestTag\":\")(.*?)(?=\")'" \
        "FRAMEWORKS = (" \
        "    'pytorch'," \
        "    'tensorflow'," \
        ")" \
        "" \
        "" \
        "def update_dockerfiles():" \
        '    """Update NVIDIA Dockerfiles with the latest tags."""' \
        "" \
        "    for framework in FRAMEWORKS:" \
        "        page = urllib.request.urlopen(f'{NVIDIA_NGC_URL}{framework}')" \
        "        text = page.read().decode()" \
        "        match = re.search(REGEX, text)" \
        "        tag = match.group(0)" \
        "        " \
        "        with open(DOCKER_DIR / f'{framework}.Dockerfile', 'r+') as f:" \
        "            lines = f.readlines()" \
        "            lines[0] = lines[0].replace('\n', f'{tag}\n')" \
        "            f.seek(0)" \
        "            f.writelines(lines)" \
        "            f.truncate()" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    update_dockerfiles()" \
        "" \
        > "${script_name}"
    chmod u+x ./"${script_name}"
}


usr_vars() {
    script_name=${SCRIPTS_PATH}"create_usr_vars.sh"
    file_name=${ROOT_PATH}"usr_vars"
    printf "%s\n" \
        "#!/bin/bash" \
        "# create_usr_vars.sh" \
        "" \
        "help_function()" \
        "{" \
        "    echo \"\"" \
        "    echo \"Create usr_vars configuration file.\"" \
        "    echo \"\"" \
        "    echo \"Usage: \$0\"" \
        "    exit 1" \
        "}" \
        "" \
        "# Parse arguments" \
        "while getopts \"p:\" opt" \
        "do" \
        "    case \$opt in" \
        "        ? ) help_function ;;" \
        "    esac" \
        "done" \
        "" \
        "# Create usr_vars configuration file" \
        "INITIAL_PORT=\$(( (\$UID - 500) * 50 + 10000 ))" \
        "printf \"%s\n\" \\" \
        "    'COMPOSE_PROJECT_NAME=\${USER}' \\" \
        "    \"\" \\" \
        "    'ENVIRONMENT=python' \\" \
        "    \"\" \\" \
        "    \"# Ports\" \\" \
        "    \"PORT_GOOGLE=\$INITIAL_PORT\" \\" \
        "    \"PORT_JUPYTER=\$((\$INITIAL_PORT + 1))\" \\" \
        "    \"PORT_NGINX=\$((\$INITIAL_PORT + 2))\" \\" \
        "    \"PORT_PROFILE=\$((\$INITIAL_PORT + 3))\" \\" \
        "    \"PORT_POSTGRES=\$((\$INITIAL_PORT + 4))\" \\" \
        "    \"PORT_MONGO=\$((\$INITIAL_PORT + 5))\" \\" \
        "    \"PORT_DATABASE_ADMINISTRATION=\$((\$INITIAL_PORT + 6))\" \\" \
        "    \"\" \\" \
        "    > \"${file_name}\"" \
        "echo \"Successfully created: usr_vars\"" \
        "" \
        > "${script_name}"
    chmod u+x ./"${script_name}"
    ./"${script_name}"
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
        "from ${SOURCE_DIR}.exceptions import InputError" \
        "from ${SOURCE_DIR}.pkg_globals import FONT_SIZE, TIME_FORMAT" \
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
        "        and \".log\" else the default name of \"info.log\" will be saved in the \\" \
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
    > "${ROOT_PATH}.yapfignore"
}


directories
usr_vars
cli
conftest
constructor_pkg
constructor_test
db
docker_compose
docker_config_py
docker_env_link
docker_ignore
docker_python
docker_pytorch
docker_tensorflow
exceptions
git_ignore
pkg_globals
makefile
manifest
pull_request_template
readme
release_history
requirements
secret_package
setup_cfg
setup_py
test_cli
test_conftest
test_db
test_utils
update_nvidia_tags
sphinx_update_config
utils
yapf_ignore

cd "${MAIN_DIR}" || exit
make docker-up
sphinx_initialization
source usr_vars
docker container exec "${COMPOSE_PROJECT_NAME}_${SOURCE_DIR}_python" \
    ./scripts/update_sphinx_config.py
rm ./scripts/update_sphinx_config.py
make docs
make package-dependencies
make secret-templates
make update-nvidia-base-images
make test-coverage
git_init

# Update scripts/docker_config.py with desired services and then call:
#   $ docker container exec ${CONTAINER_PREFIX}_python scripts/docker_config.py
#   $ make docker-rebuild
