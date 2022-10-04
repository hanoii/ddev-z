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
  echo -e "cd path/to/test/z1\ncd -\nsleep 1\nls -lRA /mnt/ddev-global-cache/z/\nz" | ddev exec "bash -i"
  echo -e "cd path/to/test/z2\ncd -\nsleep 1\nls -lRA /mnt/ddev-global-cache/z/\nz" | ddev exec "bash -i"
  echo -e "z z1\n" | ddev exec "bash -i"
  echo -e "z z2\n" | ddev exec "bash -i"
  run bash -c 'echo -e "z z3\n" | ddev exec "bash -i"'
  assert_failure
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get hanoii/ddev-z with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get hanoii/ddev-z
  ddev restart >/dev/null
  echo -e "cd path/to/test/z1\ncd -\nsleep 1\nls -lRA /mnt/ddev-global-cache/z/\nz" | ddev exec "bash -i"
  echo -e "cd path/to/test/z2\ncd -\nsleep 1\nls -lRA /mnt/ddev-global-cache/z/\nz" | ddev exec "bash -i"
  echo -e "z z1\n" | ddev exec "bash -i"
  echo -e "z z2\n" | ddev exec "bash -i"
  run bash -c 'echo -e "z z3\n" | ddev exec "bash -ix"'
  assert_failure
}
