#!/bin/bash
# test_pyproject_generator.sh

TEST_DIR="test123"

echo
echo "################################"
echo "Cleaning Docker Artifacts..."
for c in $(docker ps --format "{{.Names}}" | grep "${TEST_DIR}");
do
    docker container rm -f "${c}";
done
docker image rm "${TEST_DIR}:0.1.0"
docker network rm "${USER}-${TEST_DIR}-network"
docker volume rm "${USER}-${TEST_DIR}-secret"
docker system prune -f

echo
echo "################################"
echo "Remove Existing Test Directory..."
sudo rm -rf "${TEST_DIR}"

echo
echo "################################"
echo "Creating Test package..."
./pyproject_generator/pypackage_generator_1.sh "${TEST_DIR}" \

#echo
#echo "################################"
#echo "Update Docker configuration file..."
#cd "${TEST_DIR}" \
#    && make update-package-tooling
