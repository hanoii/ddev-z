setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-ddev-z
  mkdir -p $TESTDIR
  export PROJNAME=test-ddev-z
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  rsync -av $DIR/tests/testdata/ "${TESTDIR}"
  brew_prefix=$(brew --prefix)
  docker volume rm $PROJNAME-mariadb || true
  load "${brew_prefix}/lib/bats-support/load.bash"
  load "${brew_prefix}/lib/bats-assert/load.bash"
  ddev start -y >/dev/null
}

teardown() {
  set -eu -
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR}
  ddev restart
  # Adding this manually as I couldn't make it work from `cd` commands
  # It does seem to work just fine interactively and the purpose of this
  # test for z functionality, only for its present and some functional tests.
  ddev exec 'bash -ic "z --add /var/www/html/path/to/test/z1"'
  ddev exec 'bash -ic "z --add /var/www/html/path/to/test/z2"'
  # Test just the presence of z
  ddev exec 'bash -ic "z"'
  # Test changing dirs
  ddev exec 'bash -ic "z z1"'
  ddev exec 'bash -ic "z z2"'
  run ddev exec 'bash -ic "z z3"'
  assert_failure
  # Test persistance of database
  ddev restart
  ddev exec 'bash -ic "z"'
  ddev exec 'bash -ic "z z1"'
  ddev exec 'bash -ic "z z2"'
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get hanoii/ddev-z with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get hanoii/ddev-z
  ddev restart >/dev/null
  # Adding this manually as I couldn't make it work from `cd` commands
  # It does seem to work just fine interactively and the purpose of this
  # test for z functionality, only for its present and some functional tests.
  ddev exec 'bash -ic "z --add /var/www/html/path/to/test/z1"'
  ddev exec 'bash -ic "z --add /var/www/html/path/to/test/z2"'
  # Test just the presence of z
  ddev exec 'bash -ic "z"'
  # Test changing dirs
  ddev exec 'bash -ic "z z1"'
  ddev exec 'bash -ic "z z2"'
  run ddev exec 'bash -ic "z z3"'
  assert_failure
  # Test persistance of database
  ddev restart
  ddev exec 'bash -ic "z"'
  ddev exec 'bash -ic "z z1"'
  ddev exec 'bash -ic "z z2"'
}
