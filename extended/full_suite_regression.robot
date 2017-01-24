*** Settings ***
Documentation      This suite is for testing Open BMC full test suite.
...                Maintains log.html output.xml  for each iteration and
...                generate combined report

Library           OperatingSystem

*** Variables ***
 ${ITERATION}  10
 ${RESULT_PATH}        logsdir
 ${LOOP_TEST_COMMAND}       tests

*** Test Cases ***
Run Entire Test Suite Multiple Time
   [Documentation]  Multiple iterations of Full Suite

   Should Be True  0<${ITERATION}

   ${status}=  Run Keyword And Return Status
   ...  Directory Should Exist  ${RESULT_PATH}
   Run Keyword If   ${status} == True
   ...  Remove File  ${RESULT_PATH}/*

   Create Directory  ${RESULT_PATH}

   : FOR    ${INDEX}    IN RANGE    0    ${ITERATION}
    \    Log To Console     \n Iteration:   no_newline=True
    \    Log To Console    ${INDEX}
    \    Run  OPENBMC_HOST=${OPENBMC_HOST} tox -e ${OPENBMC_SYSTEMMODEL} -- ${LOOP_TEST_COMMAND}
    \    Run  sed -i 's/'${OPENBMC_HOST}'/DUMMYIP/g' output.xml
    \    Copy File    output.xml   ${RESULT_PATH}/output${INDEX}.xml
    \    Copy File    log.html   ${RESULT_PATH}/log${INDEX}.html

Create Combined Report
   [Documentation]   Using output[?].xml and create combined log.html

   Run  rebot --name ${OPENBMC_SYSTEMMODEL}CombinedReport ${RESULT_PATH}/output*.xml
   Move File   log.html     ${RESULT_PATH}/log${OPENBMC_SYSTEMMODEL}CombinedIterations${ITERATION}Report.html

