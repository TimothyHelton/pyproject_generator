#!/bin/bash
# test_pyproject_generator.sh

test_dir="test123"

if [ -d "${test_dir}" ]; then
    echo "Closing containers and deleting test package"
    cd "${test_dir}" || exit;
    make docker-down;
    cd .. && sudo rm -rf "${test_dir}"
fi

echo
echo "################################"
echo "Cleaning Docker Artifacts..."
docker image rm "${test_dir}_python:0.1.0"
docker network rm "${USER}-${test_dir}-network"
docker volume rm "${USER}-${test_dir}-secret"

echo
echo "################################"
echo "Creating Test package..."
./pyproject_generator/pypackage_generator.sh "${test_dir}" \

echo
echo "################################"
echo "Update Docker configuration file..."
cd "${test_dir}" \
    && make docker-update-config

