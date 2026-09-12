#!/usr/bin/env bash
set -Eeu

readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# Written down here so the gate fails when a rebuild resolves a different
# MSTest. Reading it from the image instead would compare the image against
# itself and pass whatever the rebuild brought in.
readonly EXPECTED=4.0

# Asks for the assembly the kata is actually compiled against, so the gate
# fails when the MSTest the image has is not the one named above. Matching on
# the leading major.minor lets a patch release through and stops only a minor
# or major move.
readonly ACTUAL=$(docker run --rm -i ${IMAGE_NAME} sh -c 'ls ~/.nuget/packages/mstest.testframework/ | head -1')

if echo "${ACTUAL}" | grep -q "${EXPECTED}"; then
  echo "VERSION CONFIRMED as mstest ${EXPECTED}"
else
  echo "VERSION EXPECTED: ${EXPECTED}"
  echo "VERSION   ACTUAL: ${ACTUAL}"
  exit 42
fi
