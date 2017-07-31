#!/bin/bash
#
# Run the Pyflame test suite.
#
# If invoked without arguments, this will make a best effort to run the test
# suite against python2 and python3. If you would like to force the test suite
# to run against a specific version of python, invoke with the python
# interpreter names as arguments. These should be strings suitable for passing
# to virtualenv -p.

set -e

# This script creates its own virtualenv and things can get weird if you try to
# nest them.
if [ -n "${VIRTUAL_ENV}" ]; then
  echo "Do not invoke runtests.sh from within a virtualenv!"
  exit 1
fi

ENVDIR="./.test_env"
trap 'rm -rf ${ENVDIR}' EXIT

# Run tests using pip; $1 = python version
run_pip_tests() {
  rm -rf "${ENVDIR}"
  virtualenv -q -p "$1" "${ENVDIR}" &>/dev/null

  . "${ENVDIR}/bin/activate"
  pip install -q pytest

  find tests/ -name '*.pyc' -delete
  py.test -q tests/
}

# Make a best effort to run the tests against some Python version.
try_pip_tests() {
  if command -v "$1" &>/dev/null; then
    echo -n "Running test suite against interpreter "
    "$1" --version
    run_pip_tests "$1"
  fi
}

# RPM tests are not allowed to use virtualenv at all.
run_rpm_tests() {
  py.test-2 tests/
  py.test-3 tests/
}

if [ $# -eq 0 ]; then
  try_pip_tests python2
  try_pip_tests python3
elif [ "$1" = "rpm" ]; then
  run_rpm_tests
else
  for py in "$@"; do
    run_pip_tests "$py"
  done
fi
