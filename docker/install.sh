#!/usr/bin/env bash
set -Eeu

# Everything here exists so that a kata's test run never starts MSBuild.
#
# dotnet test restores, builds and runs in one command, and on a kata this size
# almost all of that is MSBuild rather than compiling. The other csharp
# start-points avoid it by calling csc directly with an explicit list of
# references, and this one does the same.
#
# MSTest needs one thing the others do not. With EnableMSTestRunner a test
# project is an executable, and its Main is written during the build by an
# MSBuild task. With no MSBuild there is no Main, and csc says so:
#
#   error CS5001: Program does not contain a static 'Main' method
#
# MSTestEntryPoint.cs is that Main, carried here and compiled into every kata.
#
# Two things are prepared, both identical for every kata and every run:
#   1. the packages, in ~/.nuget/packages
#   2. the reference assemblies csc is pointed at, and the runtime config the
#      compiled kata is launched with
#
# The dotnet commands populate ~/.nuget/packages, so the current user must be
# sandbox: that is the user a kata runs as, and the one that has to read them.

[ "$(whoami)" == sandbox ] || (>&2 echo 'User must be sandbox' ; kill -INT $$)

readonly REFS_DIR="${HOME}/dojo_refs"
readonly ENTRY_DIR="${HOME}/mstest_entry"
readonly SEED_DIR=/tmp/seed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. and 2. A single ordinary build settles both. It resolves the packages,
#    and its output directory is exactly the set of assemblies a kata has to be
#    compiled against and run beside.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mkdir -p "${SEED_DIR}"
cp /config.csproj "${SEED_DIR}/seed.csproj"
cd "${SEED_DIR}"

# A test of its own, so the build produces what a real one would. Its result is
# never read; what is wanted is the output directory it leaves behind.
cat > Seed.cs <<'CS'
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class Seed
{
    [TestMethod]
    public void the_image_can_build_and_run_a_test()
    {
        Assert.AreEqual(42, 6 * 7);
    }
}
CS
# MSTestEntryPoint.cs is deliberately NOT part of this build. This one goes
# through MSBuild, which writes an entry point of its own, and two of them in
# one assembly is error CS0017. It is only needed on the csc path, where there
# is no MSBuild to write one.
dotnet build

readonly OUT_DIR="$(ls -d "${SEED_DIR}"/bin/Debug/net*/ | head -1)"

mkdir -p "${REFS_DIR}"
cp "${OUT_DIR}"*.dll "${REFS_DIR}/"
cp "${OUT_DIR}"seed.runtimeconfig.json "${REFS_DIR}/dojo.runtimeconfig.json"
# The kata compiles its own assembly every run. Shipping the seed's would put a
# stale one beside it, and a stale assembly answers for the learner's edit.
rm -f "${REFS_DIR}/seed.dll"

mkdir -p "${ENTRY_DIR}"
cp /MSTestEntryPoint.cs "${ENTRY_DIR}/"

# Read by check_version.sh, so the gate states the version this image holds
# rather than one written down when someone last edited it. nuget unpacks each
# package into a directory named for the version it resolved, so that is what
# is read: the version that actually arrived, not the one asked for.
#
# It goes in HOME rather than at / because this script runs as sandbox, which
# owns nothing above its own home.
readonly MSTEST_VERSION=$(ls "${HOME}/.nuget/packages/mstest.testframework/" | head -1)

if [ -z "${MSTEST_VERSION}" ]; then
  >&2 echo 'ERROR: could not read the resolved mstest version'
  exit 1
fi

echo "{\"mstest\":\"${MSTEST_VERSION}\"}" > "${HOME}/versions.json"

cd /
rm -rf "${SEED_DIR}"

echo "reference assemblies: $(ls -1 "${REFS_DIR}"/*.dll | wc -l)"
ls -l "${ENTRY_DIR}/MSTestEntryPoint.cs" "${REFS_DIR}/dojo.runtimeconfig.json"
