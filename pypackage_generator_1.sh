#! /bin/bash

# Arguments
PKG_NAME=${1:?"Specify a package name"}
SOURCE_DIR="${2:-$1}"

if [[ ${SOURCE_DIR} == *-* ]]; then
    msg="\n\nBy Python convention the source directory name may not contain "
    msg+="hyphens.\n"
    msg+="This script uses the package name (mandatory first argument) for "
    msg+="the source directory name if a second argument is not provided.\n"
    msg+="\npypackage_generator_1.sh <package_name> <source_directory>\n"
    msg+="\n\nPlease supply a source directory name without hyphens."
    printf %b "${msg}"
    exit 0
fi

# Source Variables
if [ -f envfile ]; then
    source envfile
else
    echo "Environment variable file (envfile) not found."
    echo "Default values will be used."
fi

# Assign Variables
: "${AUTHOR:=EnterAuthorName}"
: "${CACHE_DIR:=cache}"
: "${DATA_DIR:=data}"
: "${DOCKER_DIR:=docker}"
: "${DOCS_DIR:=docs}"
: "${EMAIL:=EnterAuthorEmail}"
: "${HOST_USER:="${USER}"}"
: "${HOST_GROUP_ID:=$(id -g "${HOST_USER}")}"
: "${HOST_USER_ID:=$(id -u "${HOST_USER}")}"
: "${NOTEBOOK_DIR:=notebooks}"
: "${PKG_VERSION:=0.1.0}"
: "${PYTEST_DIR:=pytest}"
: "${SCRIPTS_DIR:=scripts}"
: "${SECRETS_DIR:=secrets}"
: "${TESTS_DIR:=tests}"
: "${WHEELS_DIR:=wheels}"

# Directory Paths
CACHE_PATH="${PKG_NAME}/${CACHE_DIR}"
DATA_PATH="${PKG_NAME}/${DATA_DIR}"
DOCKER_PATH="${PKG_NAME}/${DOCKER_DIR}"
DOCS_PATH="${PKG_NAME}/${DOCS_DIR}"
NOTEBOOK_PATH="${PKG_NAME}/${NOTEBOOK_DIR}"
PYTEST_PATH="${PKG_NAME}/${PYTEST_DIR}"
SCRIPTS_PATH="${PKG_NAME}/${SCRIPTS_DIR}"
SECRETS_PATH="${DOCKER_PATH}/${SECRETS_DIR}"
SOURCE_PATH="${PKG_NAME}/${SOURCE_DIR}"
TESTS_PATH="${PKG_NAME}/${TESTS_DIR}"
WHEELS_PATH="${PKG_NAME}/${WHEELS_DIR}"


directories() {
    mkdir -p \
        "${PKG_NAME}" \
        "${CACHE_PATH}" \
        "${DATA_PATH}" \
        "${DOCKER_PATH}" \
        "${DOCS_PATH}" \
        "${NOTEBOOK_PATH}" \
        "${PYTEST_PATH}" \
        "${SCRIPTS_PATH}" \
        "${SECRETS_PATH}" \
        "${SOURCE_PATH}" \
        "${TESTS_PATH}" \
        "${WHEELS_PATH}"
}


constructor_package() {
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        "" \
        "import importlib.metadata" \
        "" \
        "" \
        "__version__ = importlib.metadata.version('${SOURCE_DIR}')" \
        > "${SOURCE_PATH}/__init__.py"
}


constructor_tests() {
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        > "${TESTS_PATH}/__init__.py"
}


docker_compose_yaml() {
    script_name="${DOCKER_PATH}/docker-compose.yaml"
    printf "%s\n" \
        "services:" \
        "" \
        "  python:" \
        "    image: ${PKG_NAME}:\${VERSION}" \
        "    restart: always" \
        "    container_name: \${COMPOSE_PROJECT_NAME:-default}-${PKG_NAME}-python" \
        "    env_file: \".env\"" \
        "    build:" \
        "      context: .." \
        "      dockerfile: docker/python.Dockerfile" \
        "    cap_add:" \
        "      - SYS_PTRACE" \
        "    environment:" \
        "      - COMPOSE_PROJECT_NAME:\${COMPOSE_PROJECT_NAME}" \
        "      - HOST_USER:\${HOST_USER}" \
        "      - HOST_UID:\${HOST_UID}" \
        "      - HOST_GID:\${HOST_GID}" \
        "      - PORT_JUPYTER:\${PORT_JUPYTER}" \
        "      - PORT_PROFILE:\${PORT_PROFILE}" \
        "    networks:"\
        "      - ${PKG_NAME}-network" \
        "    ports:" \
        "      - \${PORT_JUPYTER}:\${PORT_JUPYTER}" \
        "      - \${PORT_PROFILE}:\${PORT_PROFILE}" \
        "    secrets:" \
        "      - package" \
        "    tty: true" \
        "    volumes:" \
        "      - ..:/usr/src/${PKG_NAME}" \
        "      - ${PKG_NAME}-secret:/usr/src/${PKG_NAME}/docker/secrets" \
        "" \
        "networks:" \
        "  ${PKG_NAME}-network:" \
        "    name: \${COMPOSE_PROJECT_NAME:-default}-${PKG_NAME}-network" \
        "" \
        "secrets:" \
        "  package:" \
        "    file: secrets/package.txt" \
        "" \
        "volumes:" \
        "  ${PKG_NAME}-db:" \
        "    name: \${COMPOSE_PROJECT_NAME:-default}-${PKG_NAME}-db" \
        "  ${PKG_NAME}-secret:" \
        "    name: \${COMPOSE_PROJECT_NAME:-default}-${PKG_NAME}-secret" \
        "" \
        > "${script_name}"
        cp "${script_name}" "${DOCKER_PATH}/original-docker-compose.yaml"
}


docker_config_py() {
    script_name=${SCRIPTS_PATH}/"docker_config.py"
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        "\"\"\"Docker Configuration Module\"\"\"" \
        "" \
        "from enum import Enum" \
        "import logging" \
        "import os" \
        "from pathlib import Path" \
        "import re" \
        "from typing import Iterable, Optional" \
        "import urllib.request" \
        "" \
        "import yaml" \
        "" \
        "from ${SOURCE_DIR}.pkg_globals import PACKAGE_NAME, PACKAGE_ROOT" \
        "" \
        "" \
        "logger = logging.getLogger('package')" \
        "DOCKER_DIR = PACKAGE_ROOT / '${DOCKER_DIR}'" \
        "NVIDIA_NGC_PYTORCH_URL = (" \
        "    'https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch'" \
        ")" \
        "SECRETS_DIR = DOCKER_DIR / 'secrets'" \
        "" \
        "" \
        "class ComposeService(Enum):" \
        "    \"\"\"Implemented Docker Compose services.\"\"\"" \
        "" \
        "    LATEX = 'latex'" \
        "    NGINX = 'nginx'" \
        "    PGADMIN = 'pgadmin'" \
        "    POSTGRES = 'postgres'" \
        "" \
        "" \
        "class ComposeConfiguration:" \
        "    \"\"\"Docker Compose Configuration Class\"\"\"" \
        "" \
        "    _compose_file = DOCKER_DIR / 'docker-compose.yaml'" \
        "    _original_compose_file = DOCKER_DIR / 'original-docker-compose.yaml'" \
        "" \
        "    def __init__(self):" \
        "        with open(self._original_compose_file, 'r') as f:" \
        "            self._config = yaml.safe_load(f)" \
        "        logger.debug(" \
        "            'Initial Docker Compose Configuration:\n\n%s' % self._config" \
        "        )" \
        "" \
        "        self._container_prefix = (" \
        "            f'{os.environ[\"COMPOSE_PROJECT_NAME\"]}-{PACKAGE_NAME}'" \
        "        )" \
        "        self._network = f'{PACKAGE_NAME}-network'" \
        "        self._volume_db = f'{PACKAGE_NAME}-db'" \
        "        self._volume_secret = f'{PACKAGE_NAME}-secret'" \
        "        self._volumes = (" \
        "            self._volume_db," \
        "            self._volume_secret," \
        "        )" \
        "" \
        "        self._mask_secrets = [" \
        "            f'{self._volume_secret}:{SECRETS_DIR}'," \
        "        ]" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return '{type(self).__name__}()'" \
        "" \
        "    def _add_secrets(self):  # TODO: Makefile has a rule to create these..." \
        "        \"\"\"Add database secrets.\"\"\"" \
        "        secrets = {" \
        "            'db-database': {'file': 'secrets/db_database.txt'}," \
        "            'db-init-password': {'file': 'secrets/db_init_password.txt'}," \
        "            'db-init-username': {'file': 'secrets/db_init_username.txt'}," \
        "            'db-password': {'file': 'secrets/db_password.txt'}," \
        "            'db-username': {'file': 'secrets/db_username.txt'}," \
        "            'package': {'file': 'secrets/package.txt'}," \
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
        "            'package'," \
        "        ]" \
        "" \
        "    def _add_volumes(self):" \
        "        \"\"\"Add volumes.\"\"\"" \
        "        for volume in self._volumes:" \
        "            self._config['volumes'][volume] = {" \
        "                'name': f'{PACKAGE_NAME}-{volume}'" \
        "            }" \
        "" \
        "    def add_gpu(self):" \
        "        \"\"\"Add GPU configuration to Python container.\"\"\"" \
        "        py_service = self._config['services']['python']" \
        "        py_service['build']['shm_size'] = '1g'" \
        "        py_service['cap_add'] = ['SYS_PTRACE']" \
        "        py_service['deploy'] = {" \
        "            'resources': {" \
        "                'reservations': {" \
        "                    'devices': [" \
        "                        {" \
        "                            'driver': 'nvidia'," \
        "                            'capabilities': ['gpu']," \
        "                            'count': 'all'," \
        "                        }," \
        "                    ]," \
        "                }," \
        "            }," \
        "        }" \
        "        py_service['ipc'] = 'host'" \
        "        py_service['shm_size'] = '24g'" \
        "        py_service['ulimits'] = {'memlock': -1}" \
        "" \
        "    def _add_latex(self):" \
        "        \"\"\"Add LaTeX service to configuration.\"\"\"" \
        "        self._config['services']['latex'] = {" \
        "            'image': 'blang/latex'," \
        "            'restart': 'always'," \
        "            'container_name': f'{self._container_prefix}-latex'," \
        "            'networks': [self._network]," \
        "            'tty': True," \
        "            'volumes': [" \
        "                f'..:/usr/src/{PACKAGE_NAME}'," \
        "                *self._mask_secrets," \
        "            ]," \
        "            'working_dir': str(PACKAGE_ROOT)," \
        "        }" \
        "" \
        "    def _add_nginx(self):" \
        "        \"\"\"Add NGINX service to configuration.\"\"\"" \
        "        self._config['services']['nginx'] = {" \
        "            'container_name': f'{self._container_prefix}-nginx'," \
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
        "    def _add_pgadmin(self):" \
        "        \"\"\"Add PGAdmin service to configuration.\"\"\"" \
        "        self._config['services']['pgadmin'] = {" \
        "            'container_name': f'{self._container_prefix}-pgadmin'," \
        "            'env_file': '.env'," \
        "            'environment': {" \
        "                'PGADMIN_DEFAULT_EMAIL': '\${PGADMIN_DEFAULT_EMAIL:-pgadmin@pgadmin.org}'," \
        "                'PGADMIN_DEFAULT_PASSWORD': '\${PGADMIN_DEFAULT_PASSWORD:-admin}'," \
        "                'PORT_PGADMIN': '\${PORT_PGADMIN}'," \
        "            }," \
        "            'image': 'dpage/pgadmin4'," \
        "            'depends_on': ['postgres']," \
        "            'networks': [self._network]," \
        "            'ports': [" \
        "                '\${PORT_PGADMIN}:80'," \
        "            ]," \
        "            'volumes': [" \
        "                *self._mask_secrets," \
        "            ]," \
        "        }" \
        "" \
        "    def _add_postgres(self):" \
        "        \"\"\"Add PostgreSQL service to configuration.\"\"\"" \
        "        self._config['services']['postgres'] = {" \
        "            'container_name': f'{self._container_prefix}-postgres'," \
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
        "    def _update_depends_on(self, service_name: ComposeService):" \
        "        \"\"\"Update the Python service \`depends_on\` tag.\"\"\"" \
        "        py_tag = self._config['services']['python']" \
        "        # fmt: off" \
        "        py_tag['depends_on'] = (" \
        "            py_tag.get('depends_on', [])" \
        "            + [service_name.value]" \
        "        )" \
        "        # fmt: on" \
        "" \
        "    def add_service(self, service_name: ComposeService):" \
        "        \"\"\"" \
        "        Add service to configuration." \
        "" \
        "        :param service_name: Name of the Docker service to add" \
        "        \"\"\"" \
        "        service_name = service_name.value" \
        "        getattr(self, f'_add_{service_name}')()" \
        "        logger.debug('Docker service added: %s' % service_name)" \
        "" \
        "    def remove_service(self, service_name: ComposeService):" \
        "        \"\"\"" \
        "        Remove service from configuration." \
        "" \
        "        :param service_name: Name of the Docker service to remove" \
        "        \"\"\"" \
        "        service_name = service_name.value" \
        "        del self._config['services'][service_name]" \
        "        logger.debug('Docker service removed: %s' % service_name)" \
        "" \
        "    def write(self, des: Optional[Path] = None):" \
        "        \"\"\"" \
        "        Write Docker Compose configuration YAML file." \
        "" \
        "        :param des: Destination path to write configuration (default: \\" \
        "            docker-compose.yaml)" \
        "        .. warning::" \
        "            This method will overwrite the destination file (des)." \
        "        \"\"\"" \
        "        des = des if des else self._compose_file" \
        "        with open(des, 'w') as f:" \
        "            yaml.dump(self._config, f, sort_keys=False)" \
        "        logger.info('Docker Compose Configuration file written: %s' % des)" \
        "" \
        "" \
        "class PythonDockerfileConfiguration:" \
        "    \"\"\"Python Dockerfile Configuration Class\"\"\"" \
        "" \
        "    _python_dockerfile = DOCKER_DIR / 'python.Dockerfile'" \
        "    _original_python_dockerfile = DOCKER_DIR / 'original_python.Dockerfile'" \
        "" \
        "    def __init__(self):" \
        "        with open(self._original_python_dockerfile, 'r') as f:" \
        "            self._dockerfile = f.readlines()" \
        "        logger.debug('Initial Python Dockerfile:\n\n%s' % self._dockerfile)" \
        "" \
        "    def update_pkg_dependencies(self, deps: Iterable[str]):" \
        "        \"\"\"" \
        "        Update package dependencies." \
        "" \
        "        :param deps: Name(s) of optional dependencies defined in the pyproject.toml file." \
        "        \"\"\"" \
        "        deps = ','.join(deps)" \
        "        pkg_install_idx = [" \
        "            n for n, _ in enumerate(self._dockerfile) if 'install -e' in _" \
        "        ][0]" \
        "        self._dockerfile[pkg_install_idx] = (" \
        "            f'    && pip3 install -e .[{deps}] \\\\\\n'" \
        "        )" \
        "" \
        "    def nvidia_pytorch_(self):" \
        "        \"\"\"Update Python Dockerfile to use NVIDIA PyTorch base image.\"\"\"" \
        "        page = urllib.request.urlopen(NVIDIA_NGC_PYTORCH_URL)" \
        "        text = page.read().decode()" \
        "        match = re.search(r'(?<=latestTag\":\")(.*?)(?=\")', text)" \
        "        tag = match.group(0).rstrip('-igpu')" \
        "        self._dockerfile[0] = f'FROM nvcr.io/nvidia/pytorch:{tag}\n'" \
        "        env_tz_idx = [" \
        "            n for n, _ in enumerate(self._dockerfile) if 'TZ=Etc' in _" \
        "        ][0]" \
        "        self._dockerfile.insert(" \
        "            env_tz_idx, f'ENV TORCH_HOME={PACKAGE_ROOT}${CACHE_DIR}\n'" \
        "        )" \
        "" \
        "    def write(self, des: Optional[Path] = None):" \
        "        \"\"\"" \
        "        Write Python Dockerfile." \
        "" \
        "        :param des: Destination path to write Python Dockerfile (default: \\" \
        "            python.Dockerfile)" \
        "        .. warning::" \
        "            This method will overwrite the destination file (des)." \
        "        \"\"\"" \
        "        des = des if des else self._python_dockerfile" \
        "        with open(des, 'w') as f:" \
        "            f.writelines(self._dockerfile)" \
        "        logger.info('Python Dockerfile file written: %s' % des)" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    compose_config = ComposeConfiguration()" \
        "    services = (" \
        "        ComposeService.LATEX," \
        "        ComposeService.NGINX," \
        "        ComposeService.PGADMIN," \
        "        ComposeService.POSTGRES," \
        "    )" \
        "    for s in services:" \
        "        compose_config.add_service(s)" \
        "    compose_config.add_gpu()" \
        "    compose_config.write()" \
        "" \
        "    python_dockerfile_config = PythonDockerfileConfiguration()" \
        "    python_dockerfile_config.update_pkg_dependencies(" \
        "        deps=['build', 'test', 'jupyter', 'pytorch']," \
        "    )" \
        "    python_dockerfile_config.nvidia_pytorch_()" \
        "    python_dockerfile_config.write()" \
        > "${script_name}"
    chmod u+x ./"${script_name}"
}


docker_env_link() {
    ln "usr_vars" "docker/.env"
}


docker_ignore() {
    printf "%s\n" \
        "${CACHE_DIR}" \
        "${DATA_DIR}" \
        "*.egg-info" \
        ".idea" \
        ".pytest_cache" \
        ".pytest" \
        "" \
        > "${PKG_NAME}/.dockerignore"
}


docker_python() {
    script_name="${DOCKER_PATH}/python.Dockerfile"
    printf "%s\n" \
        "FROM python:latest" \
        "" \
        "ENV TZ=Etc/UTC" \
        "" \
        "WORKDIR /usr/src/${PKG_NAME}" \
        "" \
        "COPY . ." \
        "" \
        "RUN pip3 install --upgrade pip \\" \
        "    && apt update -y \\" \
        "    && ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime \\" \
        "    && echo \$TZ > /etc/timezone \\" \
        "    && apt install -y \\" \
        "        build-essential \\" \
        "        fonts-humor-sans \\" \
        "        libpq-dev \\" \
        "        pandoc \\" \
        "        texlive-fonts-recommended \\" \
        "        texlive-plain-generic \\" \
        "        texlive-xetex \\" \
        "        tzdata \\" \
        "    && pip3 install -e .[build,test] \\" \
        "    && rm -rf /tmp/* \\" \
        "    && rm -rf /var/lib/apt/lists/* \\" \
        "    && apt clean -y" \
        "" \
        "CMD [ \"/bin/bash\" ]" \
        "" \
        > "${script_name}"
        cp "${script_name}" "${DOCKER_PATH}/original_python.Dockerfile"
}


docker_secret_package() {
    printf "%s" \
        "${PKG_NAME}" \
        > "${SECRETS_PATH}/package.txt"
}


exceptions_py() {
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        "\"\"\"Exception Module\"\"\"" \
        "" \
        "from typing import Optional" \
        "" \
        "" \
        "class Error(Exception):" \
        "    \"\"\"Base class for package exceptions." \
        "" \
        "    :Attributes:"\
        "" \
        "    - **expression**: *str* input expression in which the error occurred" \
        "    - **message**: *str* explanation of the error" \
        "    \"\"\"" \
        "" \
        "    def __init__(" \
        "        self," \
        "        expression: Optional[str] = None," \
        "        message: Optional[str] = None," \
        "    ):" \
        "        self.expression = expression" \
        "        self.message = message" \
        "" \
        "" \
        "class InputError(Error):" \
        "    \"\"\"Exception raised for errors in the input.\"\"\"" \
        > "${SOURCE_PATH}/exceptions.py"
}


git_ignore() {
    printf "%s\n" \
        "# Cached files" \
        "${CACHE_DIR}/" \
        "" \
        "# Compiled source" \
        "*.com" \
        "dist/" \
        "*.egg-info/" \
        "*.class" \
        "*.dll" \
        "*.exe" \
        "*.o" \
        "*.pdf" \
        "*.pyc" \
        "*.so*" \
        "" \
        "# Docker files" \
        "${DOCKER_DIR}/.env" \
        "${DOCKER_DIR}/secrets/" \
        "" \
        "# Ipython files" \
        ".ipynb_checkpoints/" \
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
        "*.coverage*" \
        "htmlcov/" \
        "*.profile" \
        "" \
        "# PyCharm files" \
        ".idea/" \
        "" \
        "# pytest files" \
        ".cache/" \
        ".hypothesis/" \
        ".pytest_cache" \
        "pytest/" \
        "" \
        "# Raw data" \
        "${DATA_DIR}/" \
        "" \
        "# Sphinx files" \
        "${DOCS_DIR}/_build/" \
        "${DOCS_DIR}/_static/" \
        "${DOCS_DIR}/_templates/" \
        "${DOCS_DIR}/Makefile" \
        "" \
        "# User specific files" \
        "usr_vars" \
        > "${PKG_NAME}/.gitignore"
}


git_init() {
    git init
    git add --all
    git commit -m "Initial Commit"
}


git_pull_request_template() {
    printf "%s\n" \
        "# Summary" \
        "<description_of_PR>" \
        "" \
        "# Test Plan" \
        "- pass all unit tests" \
        "    - \`make test\`" \
        "- build documentation without warnings or errors" \
        "    - \`make docs\`" \
        "" \
        "# Checklist" \
        "- [ ] PEP8 Compliant" \
        "- [ ] Unit Test Coverage" \
        "- [ ] Updated HISTORY.md" \
        "" \
        "# Issues Closed (optional)" \
        "- < issue(s) reference >" \
        > "${PKG_NAME}/.github${FILE_SEP}PULL_REQUEST_TEMPLATE.md"
}


history_md() {
    printf "%s\n" \
        "# Release History" \
        "## ${PKG_VERSION} (YYYY-MM-DD)" \
        "" \
        "**Improvements**" \
        "- "\
        > "${PKG_NAME}/HISTORY.md"
}


license.txt() {
        touch "${PKG_NAME}/LICENSE"
}


makefile_config_py() {
    script_name="${SCRIPTS_PATH}/makefile_config.py"
    printf "%s\n" \
        "#! /usr/bin/env python" \
        "# -*- coding: utf-8 -*-" \
        "\"\"\"Makefile Configuration Module\"\"\"" \
        "" \
        "import logging" \
        "from typing import Iterable" \
        "" \
        "from ${PKG_NAME}.pkg_globals import PACKAGE_NAME, PACKAGE_ROOT" \
        "" \
        "" \
        "logger = logging.getLogger('package')" \
        "" \
        "" \
        "class MakefileConfiguration:" \
        "    \"\"\"Makefile Configuration Class\"\"\"" \
        "" \
        "    _file = PACKAGE_ROOT / 'Makefile'" \
        "" \
        "    def __init__(self):" \
        "        self._makefile = ''" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return f'{type(self).__name__}()'" \
        "" \
        "    def add_variables_(self):" \
        "        \"\"\"Add Makefile variables.\"\"\"" \
        "        self._makefile += (" \
        "            'PKG_NAME=${PKG_NAME}\n'" \
        "            '\n'" \
        "            '\$(shell scripts/create_usr_vars.sh)\n'" \
        "            'ifeq (, \$(wildcard docker/.env))\n'" \
        "            '\t\$(shell ln -s ../usr_vars docker/.env)\n'" \
        "            'endif\n'" \
        "            'include usr_vars\n'" \
        "            'export\n'" \
        "            '\n'" \
        "            'ifeq (\"\$(shell uname -s)\", \"Linux*\")\n'" \
        "            '\tBROWSER=/usr/bin/firefox\n'" \
        "            'else ifeq (\"\$(shell uname -s)\", \"Linux\")\n'" \
        "            '\tBROWSER=/usr/bin/firefox\n'" \
        "            'else\n'" \
        "            '\tBROWSER=open\n'" \
        "            'endif\n'" \
        "            '\n'" \
        "            'CONTAINER_PREFIX:=\$(COMPOSE_PROJECT_NAME)-\$(PKG_NAME)\n'" \
        "            \"DOCKER_IMAGE=\$(shell head -n 1 docker/python.Dockerfile | cut -d ' ' -f 2)\n\"" \
        "            'PROFILE_PY:=\"\"\n'" \
        "            'PROFILE_PROF:=\$(notdir \$(PROFILE_PY:.py=.prof))\n'" \
        "            'PROFILE_PATH:=profiles/\$(PROFILE_PROF)\n'" \
        "            'SRC_DIR=/usr/src/\$(PKG_NAME)\n'" \
        "            'TEX_FILE:=\"\"\n'" \
        "            'TEX_WORKING_DIR:=\"\"\n'" \
        "            'USER:=\$(shell echo \$\${USER%%@*})\n'" \
        "            'USER_ID:=\$(shell id -u \$(USER))\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_phony_(self, prerequisites: Iterable[str]):" \
        "        \"\"\"" \
        "        Add .PHONY rule." \
        "" \
        "        :param prerequisites: Prerequisites to add to the .PHONY rule" \
        "        \"\"\"" \
        "        prerequisites = ' '.join(prerequisites)" \
        "        self._makefile += f'.PHONY: {prerequisites}\n\n'" \
        "" \
        "    def add_deploy_(self):" \
        "        \"\"\"Add rule to build a package wheel.\"\"\"" \
        "        self._makefile += (" \
        "            'deploy: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python pip3 wheel --wheel-dir=${WHEELS_DIR} .[deploy]\n'" \
        "            '\t@git tag -a v\$(VERSION) -m \"Version: v\$(VERSION)\"\n'" \
        "            '\t@printf \"%s\\\\n\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"####################################################################\" \\\\\n'" \
        "            '\t\t\"Enter the following to push new version tag to the central repository:\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"git push origin v\$(VERSION)\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"####################################################################\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docker_down_(self):" \
        "        \"\"\"Add rule to take down Docker containers.\"\"\"" \
        "        self._makefile += (" \
        "            'docker-down:\n'" \
        "            '\t@docker compose -f docker/docker-compose.yaml down\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docker_images_update_(self):" \
        "        \"\"\"Add rule to update Docker images.\"\"\"" \
        "        self._makefile += (" \
        "            'docker-images-update:\n'" \
        "            \"\t@docker image ls | grep -v REPOSITORY | cut -d ' ' -f 1 | xargs -L1 docker pull\n\"" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docker_rebuild_(self):" \
        "        \"\"\"Add rule to rebuild Docker containers.\"\"\"" \
        "        self._makefile += (" \
        "            'docker-rebuild:\n'" \
        "            '\t@docker compose -f docker/docker-compose.yaml up -d --build 2>&1 | tee docker/image_build.log\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docker_up_(self):" \
        "        \"\"\"Add rule to start Docker containers.\"\"\"" \
        "        self._makefile += (" \
        "            'docker-up:\n'" \
        "            '\t@docker compose -f docker/docker-compose.yaml up -d\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docs_(self):" \
        "        \"\"\"Add rule to build Sphinx documentation.\"\"\"" \
        "        self._makefile += (" \
        "            'docs: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \"cd docs && make html\"\n'" \
        "            '\t@\${BROWSER} http://localhost:\$(PORT_NGINX) 2>&1 &\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docs_init_(self):" \
        "        \"\"\"Add rule to initialize Sphinx documentation while getting started.\"\"\"" \
        "        self._makefile += (" \
        "            '_docs-init:\n'" \
        "            '\t@rm -rf ${DOCS_DIR}/*\n'" \
        "            '\t@docker compose -f ${DOCKER_DIR}/docker-compose.yaml build python\n'" \
        "            '\t@docker container run --rm -v \`pwd\`:/usr/src/\$(PKG_NAME) \$(PKG_NAME)-python:\$(VERSION) \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"cd /usr/src/\$(PKG_NAME)/${DOCS_DIR} \\\\\n'" \
        "            '\t\t\t && sphinx-quickstart -q \\\\\n'" \
        "            '\t\t\t\t-p \$(PKG_NAME) \\\\\n'" \
        "            '\t\t\t\t-a \"${AUTHOR}\" \\\\\n'" \
        "            '\t\t\t\t-v \$(VERSION) \\\\\n'" \
        "            '\t\t\t\t--ext-autodoc \\\\\n'" \
        "            '\t\t\t\t--ext-viewcode \\\\\n'" \
        "            '\t\t\t\t--makefile \\\\\n'" \
        "            '\t\t\t\t--no-batchfile \\\\\n'" \
        "            '\t\t\t && cd .. \\\\\n'" \
        "            '\t\t\t && adduser --system --no-create-home --uid \$(USER_ID) --group \$(USER) &> /dev/null \\\\\n'" \
        "            '\t\t\t && chown -R \$(USER):\$(USER) ${DOCS_DIR}\"\n'" \
        "            '\t@git fetch\n'" \
        "            '\t@git checkout origin/master -- docs/\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_docs_view_(self):" \
        "        \"\"\"Add rule to view Sphinx documentation in the default browser.\"\"\"" \
        "        self._makefile += (" \
        "            'docs-view: docker-up\n'" \
        "            '\t@\${BROWSER} http://localhost:\$(PORT_NGINX) &\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_format_style_(self):" \
        "        \"\"\"Add rule to format Python code style.\"\"\"" \
        "        self._makefile += (" \
        "            'format-style: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"ruff format \\\\\n'" \
        "            '\t\t\t && isort \$(PKG_NAME)/*\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_getting_started_(self):" \
        "        \"\"\"Add rule to configure new developers local environment.\"\"\"" \
        "        self._makefile += (" \
        "            'getting-started: secret-templates _docs-init\n'" \
        "            '\t@mkdir -p ${CACHE_DIR} htmlcov ${NOTEBOOK_DIR} profiles ${WHEELS_DIR} \\\\\n'" \
	    "            '\t\t@printf \"%s\\\\n\" \\\\\n'" \
		"            '\t\t\t\"\" \\\\\n'" \
		"            '\t\t\t\"\" \\\\\n'" \
		"            '\t\t\t\"\" \\\\\n'" \
		"            '\t\t\t\"####################################################################\" \\\\\n'" \
		"            '\t\t\t\"Please update the secret files in the directory docker/secrets.\" \\\\\n'" \
		"            '\t\t\t\"####################################################################\" \\\\\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_ipython_(self):" \
        "        \"\"\"Add rule to start IPython interpreter.\"\"\"" \
        "        self._makefile += (" \
        "            'ipython: docker-up\n'" \
        "            '\tdocker container exec -it \$(CONTAINER_PREFIX)-python ipython\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_latexmk_(self):" \
        "        \"\"\"Add rule to compile LaTeX files to PDF.\"\"\"" \
        "        self._makefile += (" \
        "            'latexmk: docker-up\n'" \
        "            '\tdocker container exec -w \$(TEX_WORKING_DIR) \$(CONTAINER_PREFIX)-latex \\\\\n'" \
        "            '\t\t/bin/bash -c \"latexmk -f -pdf \$(TEX_FILE) && latexmk -c\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_notebook_(self):" \
        "        \"\"\"Add rule to start Jupyter notebook.\"\"\"" \
        "        self._makefile += (" \
        "            'notebook: docker-up _notebook-server\n'" \
        "            '\t@printf \"%s\\\\n\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"####################################################################\" \\\\\n'" \
        "            '\t\t\"Use this link on the host to access the Jupyter server.\" \\\\\n'" \
        "            '\t\t\"\"\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"jupyter lab list 2>&1 \\\\\n'" \
        "            \"\t\t\t | grep -o 'http.*\$(PORT_JUPYTER)\\\\S*' \\\\\n\"" \
        "            \"\t\t\t | sed -e 's/\\\\(http:\\\\/\\\\/\\\\).*\\\\(:\\\\)/\\\\1localhost:/'\\\"\n\"" \
        "            '\t@printf \"%s\\\\n\" \\\\\n'" \
        "            '\t\t\"\" \\\\\n'" \
        "            '\t\t\"####################################################################\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_notebook_delete_checkpoints_(self):" \
        "        \"\"\"Add rule to delete Jupyter checkpoint directories.\"\"\"" \
        "        self._makefile += (" \
        "            'notebook-delete-checkpoints: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\trm -rf \"\$(find -L -type d -name .ipynb_checkpoints)\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_notebook_server_(self):" \
        "        \"\"\"Add rule to start Jupyter notebook server.\"\"\"" \
        "        self._makefile += (" \
        "            '_notebook-server: _notebook-stop-server\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"jupyter labextension disable \\\\\"@jupyterlab/apputils-extension:announcements\\\\\" \\\\\n'" \
        "            '\t\t\t && jupyter lab \\\\\n'" \
        "            '\t\t\t\t--allow-root \\\\\n'" \
        "            '\t\t\t\t--no-browser \\\\\n'" \
        "            '\t\t\t\t--ServerApp.ip=0.0.0.0 \\\\\n'" \
        "            '\t\t\t\t--ServerApp.port=\$(PORT_JUPYTER) \\\\\n'" \
        "            '\t\t\t\t&\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_notebook_stop_server_(self):" \
        "        \"\"\"Add rule to stop Jupyter notebook server.\"\"\"" \
        "        self._makefile += (" \
        "            '_notebook-stop-server:\n'" \
        "            '\t@-docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \"jupyter lab stop \$(PORT_JUPYTER)\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_package_dependencies_(self):" \
        "        \"\"\"Add rule to log package dependencies to file requirements_txt.\"\"\"" \
        "        self._makefile += (" \
        "            'package-dependencies: docker-up\n'" \
	    "            '\t@printf \"%s\\\\n\" \\\\\n'" \
		"            '\t\t\"# \${PKG_NAME} Version: \$(VERSION)\" \\\\\n'" \
		"            '\t\t\"# Docker Base Image: \$(DOCKER_IMAGE)\" \\\\\n'" \
		"            '\t\t\"#\" \\\\\n'" \
		"            '\t\t> requirements.txt\n'" \
	    "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
		"            '\t\t/bin/bash -c \\\\\n'" \
		"            '\t\t\t\"pip freeze -l --exclude \$(PKG_NAME) >> requirements.txt\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_pgadmin_(self):" \
        "        \"\"\"Add rule to display pgAdmin.\"\"\"" \
        "        self._makefile += (" \
        "            'pgadmin: docker-up\n'" \
        "            '\t\${BROWSER} http://localhost:\$(PORT_PGADMIN) &\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_profile_(self):" \
        "        \"\"\"Add rule to profile Python code.\"\"\"" \
        "        self._makefile += (" \
        "            'profile: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"python -m cProfile -o \$(PROFILE_PATH) \$(PROFILE_PY)\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_psql_(self):" \
        "        \"\"\"Add rule to display PostreSQL interactive terminal.\"\"\"" \
        "        self._makefile += (" \
        "            'psql: docker-up\n'" \
        "            '\t@docker container exec -it \$(CONTAINER_PREFIX)-postgres \\\\\n'" \
        "            '\t\tpsql -U \${POSTGRES_USER} \$(PKG_NAME)\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_secret_templates_(self):" \
        "        \"\"\"Add rule to create Docker secret templates.\"\"\"" \
        "        self._makefile += (" \
        "            'secret-templates:\n'" \
        "            '\t@mkdir -p docker/secrets \\\\\n'" \
        "            '\t\t&& cd docker/secrets \\\\\n'" \
        "            '\t\t&& printf \"%s\" \"\$(PKG_NAME)\" > \"db_database.txt\" \\\\\n'" \
        "            '\t\t&& printf \"%s\" \"admin\" > \"db_init_password.txt\" \\\\\n'" \
        "            '\t\t&& printf \"%s\" \"admin\" > \"db_init_username.txt\" \\\\\n'" \
        "            '\t\t&& printf \"%s\" \"password\" > \"db_password.txt\" \\\\\n'" \
        "            '\t\t&& printf \"%s\" \"username\" > \"db_username.txt\" \\\\\n'" \
        "            '\t\t&& printf \"%s\" \"\$(PKG_NAME)\" > \"package.txt\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_snakeviz_(self):" \
        "        \"\"\"Add rule to display code profile with SnakeViz.\"\"\"" \
        "        self._makefile += (" \
        "            'snakeviz: docker-up profile _snakeviz-server\n'" \
        "            '\t@sleep 0.5\n'" \
        "            '\t@\${BROWSER} http://0.0.0.0:\$(PORT_PROFILE)/snakeviz/ &\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_snakeviz_server_(self):" \
        "        \"\"\"Add rule to start SnakeViz server.\"\"\"" \
        "        self._makefile += (" \
        "            '_snakeviz-server: docker-up\n'" \
        "            '\t@docker container exec -w /usr/src/\$(PKG_NAME)/profiles \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"snakeviz \$(PROFILE_PROF) \\\\\n'" \
        "            '\t\t\t\t--hostname 0.0.0.0 \\\\\n'" \
        "            '\t\t\t\t--port \$(PORT_PROFILE) \\\\\n'" \
        "            '\t\t\t\t--server &\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_test_(self):" \
        "        \"\"\"Add rule to execute pytest.\"\"\"" \
        "        self._makefile += (" \
        "            'test: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python py.test \$(PKG_NAME)\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python \\\\\n'" \
        "            '\t\t/bin/bash -c \\\\\n'" \
        "            '\t\t\t\"adduser --system --no-create-home --uid \$(USER_ID) --group \$(USER) &> /dev/null; \\\\\n'" \
        "            '\t\t\t chown -R \$(USER):\$(USER) pytest\"\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_test_coverage_(self):" \
        "        \"\"\"Add rule to execute pytest and report code coverage.\"\"\"" \
        "        # fmt: off" \
        "        self._makefile += (" \
        "            'test-coverage: test\n'" \
        "            '\t@\${BROWSER} htmlcov/index.html &\n'" \
        "            '\n'" \
        "        )" \
        "        # fmt: on" \
        "" \
        "    def add_update_tooling_(self):" \
        "        \"\"\"Add rule to update package tooling.\"\"\"" \
        "        self._makefile += (" \
        "            'update-package-tooling: docker-up _update-tooling-config docker-rebuild package-dependencies\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_update_tooling_config_(self):" \
        "        \"\"\"Add rule to update package tooling configuration files.\"\"\"" \
        "        self._makefile += (" \
        "            '_update-tooling-config: docker-up\n'" \
        "            '\t@docker container exec \$(CONTAINER_PREFIX)-python ./${SCRIPTS_DIR}/tooling_config.py\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def write(self):" \
        "        \"\"\"Write Makefile to package root directory.\"\"\"" \
        "        self._file.write_text(self._makefile)" \
        "        logger.debug('Makefile written: %s' % self._file)" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    config = MakefileConfiguration()" \
        "    config.add_variables_()" \
        "    config.add_phony_(['format-style'])  # docs format-style upgrade-packages" \
        "    config.add_deploy_()" \
        "    config.add_docker_down_()" \
        "    config.add_docker_images_update_()" \
        "    config.add_docker_rebuild_()" \
        "    config.add_docker_up_()" \
        "    # config.add_docs_()" \
        "    # config.add_docs_init_()" \
        "    # config.add_docs_view_()" \
        "    config.add_format_style_()" \
        "    # config.add_ipython_()" \
        "    # config.add_latexmk_()" \
        "    # config.add_notebook_()" \
        "    # config.add_notebook_delete_checkpoints_()" \
        "    # config.add_notebook_server_()" \
        "    # config.add_notebook_stop_server_()" \
        "    config.add_package_dependencies_()" \
        "    # config.add_pgadmin_()" \
        "    # config.add_profile_()" \
        "    # config.add_psql_()" \
        "    config.add_secret_templates_()" \
        "    # config.add_snakeviz_()" \
        "    # config.add_snakeviz_server_()" \
        "    config.add_test_()" \
        "    config.add_test_coverage_()" \
        "    # config.add_update_nvidia_base_images_()" \
        "    config.add_update_tooling_()" \
        "    config.add_update_tooling_config_()" \
        "    config.write()" \
        > "${script_name}"
    chmod u+x "${script_name}"
}


makefile_create_sh() {
    script_name=${SCRIPTS_PATH}/"makefile_create.sh"
    printf "%s\n" \
        "#!/bin/bash" \
        "# makefile_create.sh" \
        "" \
        "help_function()" \
        "{" \
        "    echo \"\"" \
        "    echo \"Create project Makefile file.\"" \
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
        "source usr_vars" \
        "" \
        "docker compose -f docker/docker-compose.yaml up -d" \
        "docker container exec \"\${COMPOSE_PROJECT_NAME}-${PKG_NAME}-python\" \\" \
        "    /bin/bash -c \\" \
        "        \"./${SCRIPTS_DIR}/makefile_config.py \\" \
        "         && useradd -u \${HOST_UID} \${HOST_USER} &> /dev/null || true \\" \
        "         && groupadd \${HOST_GID} &> /dev/null || true \\" \
        "         && chown \${HOST_UID}:\${HOST_GID} Makefile\"" \
        "" \
        > "${script_name}"
    chmod u+x "${script_name}"
}


manifest_in() {
    touch "${PKG_NAME}/MANIFEST.in"
}


pkg_globals_py() {
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        "\"\"\"Global Variables Module\"\"\"" \
        "" \
        "from pathlib import Path" \
        "" \
        "from ${SOURCE_DIR} import __version__" \
        "" \
        "" \
        "PACKAGE_ROOT = Path(__file__).parents[1]" \
        "DATASET_DIR = Path('/data/ai/datasets')" \
        "PACKAGE_NAME = PACKAGE_ROOT.name" \
        "PACKAGE_VERSION = f'{PACKAGE_NAME} v{__version__}'" \
        "with (PACKAGE_ROOT / 'usr_vars').open('r') as f:" \
        "    line = f.readline()" \
        "USER = line.split('=')[-1].rstrip('\n')" \
        "" \
        "FONT_SIZE = {" \
        "    'axis': 18," \
        "    'label': 14," \
        "    'legend': 12," \
        "    'super_title': 24," \
        "    'title': 20," \
        "}" \
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
        > "${SOURCE_PATH}/pkg_globals.py"
    }


pyproject_toml() {
    printf "%s\n" \
        "[build-system]" \
        "build-backend = \"setuptools.build_meta\"" \
        "requires = [" \
        "    \"setuptools\"," \
        "]" \
        "" \
        "[tool.setuptools.packages.find]" \
        "where = [\"/usr/src/${PKG_NAME}\"]" \
        "include = [\"${PKG_NAME}\"]" \
        "namespaces = true" \
        "" \
        "[project]" \
        "version = \"${PKG_VERSION}\"" \
        "name = \"${PKG_NAME}\"" \
        "dependencies = [" \
        "    \"click\"," \
        "    \"isort\"," \
        "    \"matplotlib\"," \
        "    \"pandas\"," \
        "    \"plotly\"," \
        "    \"pyyaml\"," \
        "    \"ruff\"," \
        "]" \
        "" \
        "[project.optional-dependencies]" \
        "all = [\"${PKG_NAME}[build, docs, jupyter, profile, postgres, test]\"]" \
        "deploy = [\"${PKG_NAME}[docs, jupyter, postgres]\"]" \
        "build = [" \
        "    \"setuptools\"," \
        "    \"wheel\"," \
        "]" \
        "docs = [" \
        "    \"sphinx\"," \
        "    \"sphinx_rtd_theme\"," \
        "]" \
        "jupyter = [" \
        "# requires header files:" \
        "#    pandoc" \
        "#    texlive-fonts-recommended" \
        "#    texlive-plain-generic" \
        "#    texlive-xetex" \
        "    \"jupyter\"," \
        "    \"jupyterlab\"," \
        "    \"kaleido\"," \
        "    \"pandoc\"," \
        "    \"protobuf\"," \
        "]" \
        "profile = [" \
        "    \"memory_profiler\"," \
        "    \"snakeviz\"," \
        "]" \
        "postgres = [" \
        "# requires header files:" \
        "#    build-essential" \
        "#    libpq-dev" \
        "#    wget" \
        "    \"psycopg2\"," \
        "    \"sqlalchemy\"," \
        "]" \
        "pytorch = [" \
        "    \"captum\"," \
        "    \"gpustat\"," \
        "    \"lovely-tensors\"," \
        "    \"optuna\"," \
        "    \"ray[all]\"," \
        "    # \"torch\"," \
        "    # \"torchdata\"," \
        "    \"torchinfo\"," \
        "    \"torchmetrics\"," \
        "    # \"torchvision\"," \
        "]" \
        "test = [" \
        "    \"Faker\"," \
        "    \"pytest\"," \
        "    \"pytest-cov\"," \
        "    \"pytest-ruff\"," \
        "    \"pytest-sugar\"," \
        "]" \
        "" \
        "[tool.coverage.html]" \
        "directory = \"htmlcov\"" \
        "title = \"${PKG_NAME} Test Coverage\"" \
        "" \
        "[tool.coverage.paths]" \
        "source = [" \
        "    \"${SOURCE_DIR}/\"," \
        "]" \
        "" \
        "[tool.coverage.report]" \
        "omit = [" \
        "    \"*/__init__.py\"" \
        "]" \
        "" \
        "[tool.coverage.run]" \
        "parallel = true" \
        "" \
        "[tool.isort]" \
        "src_paths = [" \
        "    \"${SOURCE_DIR}\"," \
        "    \"${SCRIPTS_DIR}\"," \
        "]" \
        "line_length = 79" \
        "lines_after_imports = 2" \
        "include_trailing_comma = true" \
        "combine_as_imports = true" \
        "" \
        "[tool.pytest.ini_options]" \
        "addopts = [" \
        "    \"-rvvv\"," \
        "    \"--basetemp=pytest\"," \
        "    # \"--cache-clear\"," \
        "    \"--color=yes\"," \
        "    \"--cov=${SOURCE_DIR}\"," \
        "    \"--cov-report=html\"," \
        "    \"--doctest-modules\"," \
        "    \"--ff\"," \
        "    \"--force-sugar\"," \
        "    \"--import-mode=importlib\"," \
        "    \"--ruff\"," \
        "    \"--ruff-format\"," \
        "]" \
        "testpaths = [" \
        "    \"${TESTS_DIR}\"," \
        "]" \
        "" \
        "[tool.ruff]" \
        "line-length = 79" \
        "src = [" \
        "    \"${NOTEBOOK_DIR}\"," \
        "    \"${SOURCE_DIR}\"," \
        "    \"${SCRIPTS_DIR}\"," \
        "]" \
        "" \
        "[tool.ruff.format]" \
        "docstring-code-format = true" \
        "quote-style = \"single\"" \
        "" \
        > "${PKG_NAME}/pyproject.toml"
}


# TODO: write in tooling_config.py
readme_md() {
    pass
}


requirements_txt() {
    touch "${PKG_NAME}/requirements.txt"
}


sphinx_config_py() {
    script_name="${SCRIPTS_PATH}/sphinx_config.py"
    printf "%s\n" \
        "#! /usr/bin/env python" \
        "# -*- coding: utf-8 -*-" \
        "\"\"\"Sphinx Documentation Configuration Module\"\"\"" \
        "" \
        "import logging" \
        "import shutil" \
        "import subprocess" \
        "from typing import Iterable" \
        "" \
        "from ${PKG_NAME} import __version__" \
        "from ${PKG_NAME}.pkg_globals import PACKAGE_NAME, PACKAGE_ROOT" \
        "" \
        "" \
        "logger = logging.getLogger('package')" \
        "" \
        "" \
        "class SphinxConfiguration:" \
        "    \"\"\"Sphinx Documentation Configuration Class\"\"\"" \
        "" \
        "    _docs_path = PACKAGE_ROOT / '${DOCS_DIR}'" \
        "    _config_py_path = _docs_path / 'conf.py'" \
        "    _custom_css_path = _docs_path / '_static' / 'custom.css'" \
        "    _index_rst_path = _docs_path / 'index.rst'" \
        "    _links_rst_path = _docs_path / 'links.rst'" \
        "    _package_rst_path = _docs_path / 'package.rst'" \
        "    _tutorials_dir_path = _docs_path / 'tutorials'" \
        "    _tutorials_rst_path = _docs_path / 'tutorials.rst'" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return f'{type(self).__name__}()'" \
        "" \
        "    def initialize_sphinx(self):" \
        "        \"\"\"Initialize Sphinx documentation.\"\"\"" \
        "        shutil.rmtree(self._docs_path)" \
        "        self._docs_path.mkdir()" \
        "        cmd = (" \
        "            f'cd {PACKAGE_ROOT}'" \
        "            '&& pip install -e .[docs] '" \
        "            f'&& cd {self._docs_path} '" \
        "            '&& sphinx-quickstart '" \
        "            '    -q '" \
        "            f'    -p \"{PACKAGE_NAME}\" '" \
        "            '    -a \"${AUTHOR}\" '" \
        "            f'    -v {__version__} '" \
        "            '    --ext-autodoc '" \
        "            '    --ext-viewcode '" \
        "            '    --makefile '" \
        "            '    --no-batchfile'" \
        "        )" \
        "        subprocess.run(cmd, shell=True)" \
        "" \
        "    def add_config_py(self):" \
        "        \"\"\"Add Sphinx configuration file (conf.py).\"\"\"" \
        "        self._config_py_path.unlink()" \
        "        self._config_py_path.write_text(" \
        "            'import os\n'" \
        "            'import sys\n'" \
        "            '\n'" \
        "            'from ${PKG_NAME} import __version__\n'" \
        "            '\n'" \
        "            \"sys.path.insert(0, os.path.abspath('../${PKG_NAME}'))\n\"" \
        "            '\n'" \
        "            \"project = '${PKG_NAME}'\n\"" \
        "            \"copyright = '$(date +%Y), ${AUTHOR}'\n\"" \
        "            \"author = '${AUTHOR}'\n\"" \
        "            '\n'" \
        "            'version = __version__\n'" \
        "            'release = __version__\n'" \
        "            '\n'" \
        "            'extensions = [\n'" \
        "            \"    'sphinx.ext.autodoc',\n\"" \
        "            \"    'sphinx.ext.viewcode',\n\"" \
        "            ']\n'" \
        "            '\n'" \
        "            \"templates_path = ['_templates']\n\"" \
        "            \"exclude_patterns = ['_build', 'links.rst', 'Thumbs.db', '.DS_Store']\n\"" \
        "            \"rst_epilog = ''\n\"" \
        "            '\n'" \
        "            \"with open('links.rst') as f:\n\"" \
        "            '    rst_epilog += f.read()'" \
        "            '\n'" \
        "            \"html_theme = 'sphinx_rtd_theme'\n\"" \
        "            \"html_favicon = '_static/${PKG_NAME}.png'\n\"" \
        "            \"html_logo = '_static/logo.svg'\n\"" \
        "            \"html_static_path = ['_static']\n\"" \
        "            \"html_css_files = ['custom.css']\n\"" \
        "        )" \
        "" \
        "    def add_custom_css(self):" \
        "        \"\"\"Add custom css file.\"\"\"" \
        "        self._custom_css_path.write_text(" \
        "            '.wy-nav-content {max-width: 1200px !important;}'" \
        "        )" \
        "" \
        "    def update_index_rst(self):" \
        "        \"\"\"Update index.rst file.\"\"\"" \
        "        txt = self._index_rst_path.read_text().split('\n')" \
        "        txt[0] = f'{PACKAGE_NAME} API'" \
        "        txt[1] = '=' * len(txt[0])" \
        "        # fmt: off" \
        "        idx = [" \
        "            n for n, _ in enumerate(txt, start=1)" \
        "            if ':caption: Contents:' in _][0]" \
        "        # fmt: on" \
        "        txt[idx:idx] = ('\n', 'package', 'tutorials')" \
        "        self._index_rst_path.write_text('\n'.join(txt))" \
        "" \
        "    def add_links_rst(self):" \
        "        \"\"\"Add links.rst file.\"\"\"" \
        "        self._links_rst_path.write_text(" \
        "            '.. _PyTorch Documentation: https://pytorch.org/docs/stable/index.html\n'" \
        "        )" \
        "" \
        "    def add_package_rst(self):" \
        "        \"\"\"Add package.rst file.\"\"\"" \
        "        self._package_rst_path.write_text(" \
        "            '.. toctree::\n'" \
        "            '    :maxdepth: 2\n'" \
        "            '\n'" \
        "            'Base Modules\n'" \
        "            '============\n'" \
        "            '\n'" \
        "            'exceptions\n'" \
        "            '----------\n'" \
        "            '.. automodule:: exceptions\n'" \
        "            '    :members:\n'" \
        "            '    :show-inheritance:\n'" \
        "            '    :synopsis: Package exceptions module.\n'" \
        "            '\n'" \
        "            'utils\n'" \
        "            '-----\n'" \
        "            '.. automodule:: utils\n'" \
        "            '    :members:\n'" \
        "            '    :show-inheritance:\n'" \
        "            '    :synopsis: Package utilities module.\n'" \
        "            '\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def add_tutorials(self):" \
        "        \"\"\"Add tutorials directory and tutorials.rst file.\"\"\"" \
        "        self._tutorials_dir_path.mkdir(parents=True, exist_ok=True)" \
        "        self._tutorials_rst_path.write_text(" \
        "            'Tutorials\n'" \
        "            '=========\n'" \
        "            '\n'" \
        "            '.. toctree::\n'" \
        "            '    :maxdepth: 1\n'" \
        "            '\n'" \
        "        )" \
        "" \
        "    def update_permissions(self):" \
        "        \"\"\"Add tutorials directory and tutorials.rst file.\"\"\"" \
        "        cmds = (" \
        "            'useradd -u \${HOST_UID} \${HOST_USER} &> /dev/null || true'," \
        "            'groupadd \${HOST_GID} &> /dev/null || true'," \
        "            'chown \${HOST_UID}:\${HOST_GID} -R ' + str(self._docs_path)," \
        "        )" \
        "        for cmd in cmds:" \
        "            subprocess.run(cmd, shell=True)" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    config = SphinxConfiguration()" \
        "    config.initialize_sphinx()" \
        "    config.add_config_py()" \
        "    config.add_custom_css()" \
        "    config.update_index_rst()" \
        "    config.add_links_rst()" \
        "    config.add_package_rst()" \
        "    config.add_tutorials()" \
        "    config.update_permissions()" \
        > "${script_name}"
    chmod u+x "${script_name}"
}


tooling_config_py() {
    script_name="${SCRIPTS_PATH}/tooling_config.py"
    printf "%s\n" \
        "#! /usr/bin/env python3" \
        "# -*- coding: utf-8 -*-" \
        "\"\"\"Package Tooling Configuration Module\"\"\"" \
        "" \
        "from enum import Enum" \
        "import logging" \
        "from pathlib import Path" \
        "from typing import Optional" \
        "" \
        "import yaml" \
        "" \
        "from docker_config import (" \
        "    ComposeConfiguration," \
        "    ComposeService," \
        "    PythonDockerfileConfiguration," \
        ")" \
        "from makefile_config import MakefileConfiguration" \
        "from sphinx_config import SphinxConfiguration" \
        "from ${SOURCE_DIR}.pkg_globals import PACKAGE_ROOT" \
        "" \
        "logger = logging.getLogger('package')" \
        "" \
        "" \
        "class Tool(Enum):" \
        "    \"\"\"Implemented tools.\"\"\"" \
        "" \
        "    DOCUMENTATION = 'documentation'" \
        "    GPU = 'gpu'" \
        "    JUPYTER = 'jupyter'" \
        "    LATEX = 'latex'" \
        "    POSTGRES = 'postgres'" \
        "    PYTHON_PROFILE = 'python_profile'" \
        "    PYTORCH = 'pytorch'" \
        "" \
        "" \
        "class ToolingConfiguration:" \
        "    \"\"\"Tooling Configuration Class\"\"\"" \
        "" \
        "    _default_extras_require = ['build', 'test']" \
        "" \
        "    def __init__(self):" \
        "        self._docker_config = ComposeConfiguration()" \
        "        self._extras_require = []" \
        "        self._makefile_rules = []" \
        "        self._phony = ['format-style']" \
        "        self._python_dockerfile_config = PythonDockerfileConfiguration()" \
        "" \
        "    def __repr__(self) -> str:" \
        "        return f'{type(self).__name__})'" \
        "" \
        "    def _add_documentation(self):" \
        "        \"\"\"Add Sphinx documentation.\"\"\"" \
        "        self._docker_config.add_service(ComposeService.NGINX)" \
        "        self._extras_require.append('docs')" \
        "        self._makefile_rules += [" \
        "            'add_docs_'," \
        "            'add_docs_init_'," \
        "            'add_docs_view_'," \
        "        ]" \
        "        self._phony.append('docs')" \
        "        sphinx_config = SphinxConfiguration()" \
        "        sphinx_config.initialize_sphinx()" \
        "        sphinx_config.add_config_py()" \
        "        sphinx_config.add_custom_css()" \
        "        sphinx_config.update_index_rst()" \
        "        sphinx_config.add_links_rst()" \
        "        sphinx_config.add_package_rst()" \
        "        sphinx_config.add_tutorials()" \
        "        sphinx_config.update_permissions()" \
        "" \
        "    def _add_gpu(self):" \
        "        \"\"\"Add GPU configuration to Docker Compose.\"\"\"" \
        "        self._docker_config.add_gpu()" \
        "" \
        "    def _add_jupyter(self):" \
        "        \"\"\"Add Jupyter tool.\"\"\"" \
        "        self._extras_require.append('jupyter')" \
        "        self._makefile_rules += [" \
        "            'add_ipython_'," \
        "            'add_notebook_'," \
        "            'add_notebook_delete_checkpoints_'," \
        "            'add_notebook_server_'," \
        "            'add_notebook_stop_server_'," \
        "        ]" \
        "" \
        "    def _add_latex(self):" \
        "        \"\"\"Add LaTeX tool.\"\"\"" \
        "        self._docker_config.add_service(ComposeService.LATEX)" \
        "        self._makefile_rules.append('add_latexmk_')" \
        "        self._phony.append('latexmk')" \
        "" \
        "    def _add_python_profile(self):" \
        "        \"\"\"Add Python profiling tools.\"\"\"" \
        "        self._extras_require.append('profile')" \
        "        self._makefile_rules += [" \
        "            'add_profile_'," \
        "            'add_snakeviz_'," \
        "            'add_snakeviz_server_'," \
        "        ]" \
        "" \
        "    def _add_postgres(self):" \
        "        \"\"\"Add PostgreSQL database tool.\"\"\"" \
        "        self._extras_require.append('postgres')" \
        "        for service in (ComposeService.PGADMIN, ComposeService.POSTGRES):" \
        "            self._docker_config.add_service(service)" \
        "        self._makefile_rules += [" \
        "            'add_pgadmin_'," \
        "            'add_psql_'," \
        "        ]" \
        "" \
        "    def _add_pytorch(self):" \
        "        \"\"\"Add NVIDIA NGC PyTorch tool.\"\"\"" \
        "        self._extras_require.append('pytorch')" \
        "        self._python_dockerfile_config.nvidia_pytorch_()" \
        "" \
        "    def add_tool(self, tool_name: Tool):" \
        "        \"\"\"" \
        "        Add tool to package." \
        "" \
        "        :param tool_name: Name of the package tool to add" \
        "        \"\"\"" \
        "        tool_name = tool_name.value" \
        "        getattr(self, f'_add_{tool_name}')()" \
        "        logger.debug('Package tool added: %s' % tool_name)" \
        "" \
        "    def write(self):" \
        "        \"\"\"Write Docker and Makefile configuration files.\"\"\"" \
        "        self._docker_config.write()" \
        "        if self._extras_require:" \
        "            self._extras_require += self._default_extras_require" \
        "            self._python_dockerfile_config.update_pkg_dependencies(" \
        "                self._extras_require" \
        "            )" \
        "        self._python_dockerfile_config.write()" \
        "        if self._makefile_rules:" \
        "            makefile_config = MakefileConfiguration()" \
        "            makefile_config.add_variables_()" \
        "            makefile_config.add_phony_(self._phony)" \
        "            makefile_config.add_deploy_()" \
        "            makefile_config.add_docker_down_()" \
        "            makefile_config.add_docker_images_update_()" \
        "            makefile_config.add_docker_rebuild_()" \
        "            makefile_config.add_docker_up_()" \
        "            makefile_config.add_format_style_()" \
        "            makefile_config.add_package_dependencies_()" \
        "            makefile_config.add_secret_templates_()" \
        "            makefile_config.add_test_()" \
        "            makefile_config.add_test_coverage_()" \
        "            makefile_config.add_update_tooling_()" \
        "            makefile_config.add_update_tooling_config_()" \
        "            for rule in self._makefile_rules:" \
        "                getattr(makefile_config, rule)()" \
        "            makefile_config.write()" \
        "" \
        "" \
        "if __name__ == '__main__':" \
        "    config = ToolingConfiguration()" \
        "    tools = (" \
        "        Tool.DOCUMENTATION," \
        "        Tool.GPU," \
        "        Tool.JUPYTER," \
        "        Tool.LATEX," \
        "        Tool.POSTGRES," \
        "        Tool.PYTHON_PROFILE," \
        "        Tool.PYTORCH," \
        "    )" \
        "    for t in tools:" \
        "        config.add_tool(t)" \
        "    config.write()" \
        > "${script_name}"
    chmod u+x "${script_name}"
}


usr_vars_sh() {
    script_name=${SCRIPTS_PATH}/"create_usr_vars.sh"
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
        "DIR=\"\$(dirname \"\$0\")\"" \
        "FILE=\"\$(basename \"\$0\")\"" \
        "UID=\"\$(stat -c %u \${DIR}/\${FILE})\"" \
        "GID=\"\$(stat -c %g \${DIR}/\${FILE})\"" \
        "VERSION=\"\$(grep -A 1 \"\\[project\\]\" pyproject.toml | grep \"version\" | cut -d = -f 2 | tr -d '[\" ]')\"" \
        "" \
        "# Create usr_vars configuration file" \
        "INITIAL_PORT=\$(( (UID - 500) * 50 + 10000 ))" \
        "printf \"%s\n\" \\" \
        "    \"COMPOSE_PROJECT_NAME=\${USER}\" \\" \
        "    \"\" \\" \
        "    \"VERSION=\${VERSION}\" \\" \
        "    \"\" \\" \
        "    \"HOST_USER=\${USER}\" \\" \
        "    \"HOST_UID=\${UID}\" \\" \
        "    \"HOST_GID=\${GID}\" \\" \
        "    \"\" \\" \
        "    \"PORT_JUPYTER=\$((INITIAL_PORT + 1))\" \\" \
        "    \"PORT_NGINX=\$((INITIAL_PORT + 2))\" \\" \
        "    \"PORT_PROFILE=\$((INITIAL_PORT + 3))\" \\" \
        "    \"PORT_POSTGRES=\$((INITIAL_PORT + 4))\" \\" \
        "    \"PORT_PGADMIN=\$((INITIAL_PORT + 5))\" \\" \
        "    \"\" \\" \
        "    > \"usr_vars\"" \
        "echo \"Successfully created: usr_vars\"" \
        "" \
        > "${script_name}"
    chmod u+x ./"${script_name}"
}


directories
makefile_config_py
docker_config_py
constructor_package
constructor_tests
docker_compose_yaml
docker_ignore
docker_python
docker_secret_package
exceptions_py
git_ignore
git_pull_request_template
history_md
makefile_create_sh
manifest_in
pkg_globals_py
pyproject_toml
requirements_txt
sphinx_config_py
tooling_config_py
usr_vars_sh

cd "${PKG_NAME}" || exit
./"${SCRIPTS_DIR}/create_usr_vars.sh"
docker_env_link
./"${SCRIPTS_DIR}/makefile_create.sh"
make package-dependencies
make secret-templates
git_init
make format-style
