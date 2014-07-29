#!/bin/bash

trap 'yabt_trap_err ${LINENO} $?' ERR

yabt_trap_err()
{
	MYSELF="$0"              # equals to my script name
	LASTLINE="$1"            # argument 1: last line of error occurrence
	LASTERR="$2"             # argument 2: error code of last command

	echo "execution error at line ${LASTLINE} of ${MYSELF} (exit code ${LASTERR}) : aborting..." 1>&2

	exit ${LASTERR}
}

TMP_DIR="$(mktemp -d)"

mkdir ${TMP_DIR}/SPECS
cp -v $(dirname $0)/yabt.spec ${TMP_DIR}/SPECS/

mkdir ${TMP_DIR}/SOURCES
cp -v $(dirname $0)/../{LICENSE,README.md} $(dirname $0)/../src/*.sh $(dirname $0)/../conf/*.conf ${TMP_DIR}/SOURCES/

rpmbuild -ba --define "_topdir ${TMP_DIR}" ${TMP_DIR}/SPECS/yabt.spec

cp -v ${TMP_DIR}/RPMS/*/*  ${TMP_DIR}/SRPMS/* $(dirname $0)/../dist/

rm -rf ${TMP_DIR}

echo "Done: see generated RPMs at $(readlink -f $(dirname $0)/../dist)"
