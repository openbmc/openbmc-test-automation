#! /bin/bash
: '
   ****** Script Details ***************
    Owner       : Sathyajith M.S. (sathyajith.ms@in.ibm.com)
    Description : This script reads CodeDir, testcase name..etc and runs the testcase by calling OBMC_ASMi_TCM_Main.py script
    Usage       : OpenBMC_ASMi_Flow.sh
    Notes       :
'

## Trim all input parameters
TESTCASE=`echo ${TESTCASE} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
TESTCASE_ID=`echo ${TESTCASE_ID} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
CODE_DIR=`echo ${CODE_DIR} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`

ENABLE_STOP_AT_FAILURE=`echo ${ENABLE_STOP_AT_FAILURE} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
ENABLE_START_TRACES=`echo ${ENABLE_START_TRACES} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`

if [ "${STOP_AT_FAILURE}" == "YES" ]
then
    ENABLE_STOP_AT_FAILURE='-S'
fi

if [ "${START_TRACES}" == "YES" ]
then
    ENABLE_START_TRACES='-R'
fi

cd ${CODE_DIR}

if [ "${PYTHON_VER}" == "" ]
then
    PYTHON_VER="python2.6"
fi

#Command="${PYTHON_VER} ${PathToTMMain}TMMain.py -C ${ConfigXml} -F ${TESTCASE} -T ${TESTCASE_ID}  -M 1 ${ENABLE_STOP_AT_FAILURE} ${ENABLE_START_TRACES}"

Command="${PYTHON_VER} ${PathToTMMain}TMMain.py -F ${TESTCASE} -T ${TESTCASE_ID} -M 1 ${ENABLE_STOP_AT_FAILURE} ${ENABLE_START_TRACES}"

echo "COMMAND: ${Command} will be run now from : "
pwd

${Command}

res=$?

echo "Returned code from TMMain.py script is : $res"

###  Check for SUCCESS or FAILURE of TMMain.py script
if [ $res -eq 0 ]
then
   echo "Executed ${TESTCASE}  succesfully"
   echo -e "\n\n ================================================= \n\n"
   exit 0
else
   echo "Failed to execute"

exit 1
