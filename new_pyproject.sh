#!/usr/bin/env bash

NAME=${1:?"Specify a package name"}
GENERATOR=pypackage_generator.sh

################################################################################

# Download latest version of the build file
curl -O https://raw.githubusercontent.com/TimothyHelton/pyproject_generator/master/${GENERATOR}
chmod u+x ${GENERATOR}

# Source Environment Variables
if [ -f envfile ]; then
    source envfile
else
    echo "Environment variable file (envfile) not found."
    echo "Default values will be used."
fi

# Create Project
./pypackage_generator.sh ${NAME}

# Remove Generator
rm ${GENERATOR}

