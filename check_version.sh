#!/usr/bin/env bash
set -Eeu

readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# install.sh records the version nuget resolved in the sandbox user's home,
# so the expected version is read from the image rather than written down
# here. Writing it down here would pin the gate to whatever was current when
# someone last edited this file.
readonly VERSIONS=$(docker run --rm -i ${IMAGE_NAME} sh -c 'cat ~/versions.json')
readonly VERSION_REGEX='"mstest":"([0-9.]+)"'
if [[ ! ${VERSIONS} =~ ${VERSION_REGEX} ]]; then
  echo "VERSION ERROR: versions.json has no mstest property"
  echo "VERSION   FILE: ${VERSIONS}"
  exit 42
fi
readonly EXPECTED="${BASH_REMATCH[1]}"

# Asks for the assembly the kata is actually compiled against, so the gate
# fails if the number recorded at build time is not the MSTest the image has.
readonly ACTUAL=$(docker run --rm -i ${IMAGE_NAME} sh -c 'ls ~/.nuget/packages/mstest.testframework/ | head -1')

if [ "${ACTUAL}" == "${EXPECTED}" ]; then
  echo "VERSION CONFIRMED as mstest ${EXPECTED}"
else
  echo "VERSION EXPECTED: ${EXPECTED}"
  echo "VERSION   ACTUAL: ${ACTUAL}"
  exit 42
fi
