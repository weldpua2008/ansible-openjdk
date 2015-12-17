#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
RDIR="$( dirname "$SOURCE" )"
SUDO=`which sudo 2> /dev/null`
SUDO_OPTION="--sudo"
OS_TYPE=${1:-}
OS_VERSION=${2:-}
ANSIBLE_VERSION=${3:-}
JDK_TYPE=${4:-"open"}
JDK_VERSION=${5:-"7"}
ANSIBLE_VAR=""
ANSIBLE_INVENTORY="tests/test-inventory"
ANSIBLE_PLAYBOOk="tests/test.yml"
ANSIBLE_LOG_LEVEL="-vvv"

#ANSIBLE_SHORT_VERSION=`ansible-playbook --version 2> /dev/null|cut -d " " -f2|cut -d "." -f1,2`

# if there wasn't sudo then ansible couldn't use it
if [ "x$SUDO" == "x" ];then
    SUDO_OPTION=""
fi

#if [ "${OS_TYPE}" == "centos" ];then
#    if [ "${OS_VERSION}" == "7" ];then
#        ANSIBLE_VAR="apache_use_service=False"
#    fi
#
#fi

ANSIBLE_VAR="${JDK_TYPE}=${JDK_VERSION}"
ANSIBLE_EXTRA_VARS=""
if [ "${ANSIBLE_VAR}x" != "x" ];then
    ANSIBLE_EXTRA_VARS=" -e \"${ANSIBLE_VAR}\" "
fi

#
cd $RDIR/..
printf "[defaults]\nroles_path = ../" > ansible.cfg
#

function test_playbook_syntax(){

    ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOk} --syntax-check || (echo "ansible playbook syntax check was failed" && exit 2 )
}

function test_playbook(){
    # first run
    ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOk} ${ANSIBLE_LOG_LEVEL} --connection=local ${SUDO_OPTION} ${ANSIBLE_EXTRA_VARS} || ( echo "first run was failed" && exit 2 )
    echo "============================================="
    echo "================ second start ==============="
    echo "============================================="
    ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOk} ${ANSIBLE_LOG_LEVEL} --connection=local ${SUDO_OPTION} ${ANSIBLE_EXTRA_VARS}


    # Run the role/playbook again, checking to make sure it's idempotent.
    ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOk} ${ANSIBLE_LOG_LEVEL} --connection=local ${SUDO_OPTION} ${ANSIBLE_EXTRA_VARS} | grep -q 'changed=0.*failed=0' && (echo 'Idempotence test: pass' ) || (echo 'Idempotence test: fail' && exit 1)
}
function extra_tests(){
    java -version
}

function main(){
    test_playbook_syntax
    test_playbook
    extra_tests
}

################ run #########################
set -e
main
