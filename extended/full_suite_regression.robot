*** Settings ***
Documentation      This suite is for testing Open BMC full test suite.
...                Maintains log.html output.xml  for each iteration and
...                generate combined report

Library           OperatingSystem

*** Variables ***
 ${ITERATION}  10
 ${RESULT_PATH}        logsdir

*** Test Cases ***
Run Entire Test Suite Multiple Time
   [Documentation]  Multiple iterations of Full Suite

   Should Be True  0<${ITERATION}
   Create Directory   ${RESULT_PATH}
   : FOR    ${INDEX}    IN RANGE    0    ${ITERATION}
    \    Log To Console     \n Iteration:   no_newline=True
    \    Log To Console    ${INDEX}
    \    Run  OPENBMC_HOST=${OPENBMC_HOST} tox -e ${OPENBMC_SYSTEMMODEL} -- tests
    \    Copy File    output.xml   ${RESULT_PATH}/output${INDEX}.xml
    \    Copy File    log.html   ${RESULT_PATH}/log${INDEX}.html

Create Combined Report
   [Documentation]   Using output[?].xml and create combined log.html

   Run  rebot --name ${OPENBMC_SYSTEMMODEL}CombinedReport ${RESULT_PATH}/output*.xml
   Move File   log.html     ${RESULT_PATH}/log${OPENBMC_SYSTEMMODEL}CombinedIterations${ITERATION}Report.html

