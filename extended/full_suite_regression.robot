*** Settings ***
Documentation      This suite is for testing Open BMC full test suite.
...                Maintains log.html output.xml  for each iteration and
...                generate combined report

Library           OperatingSystem
Library           SSHLibrary

Suite Teardown    Close All Connections

*** Variables ***
 ${ITERATION}  10

*** Test Cases ***
Run Tests Multiple Time
   [Documentation]  Multiple iterations of Full Suite

   Should Be True  0<${ITERATION}
   Create Directory   ../logsdir
   : FOR    ${INDEX}    IN RANGE    0    ${ITERATION}
    \    Log To Console     \n Iteration:   no_newline=True
    \    Log To Console    ${INDEX}
    \    Run  OPENBMC_HOST=${OPENBMC_HOST} tox -e ${OPENBMC_SYSTEMMODEL} -- ../tests/test_fw_version.robot
    \    Copy File    ../output.xml   ../logsdir/output${INDEX}.xml
    \    Copy File    ../log.html   ../logsdir/log${INDEX}.html

Create Combined Report
   [Documentation]   Using output[?].xml and create combined log.html

   Run  rebot --name ${OPENBMC_SYSTEMMODEL}CombinedReport ../logsdir/output*.xml
   Move File   log.html     ../logsdir/log${OPENBMC_SYSTEMMODEL}CombinedIterations${ITERATION}Report.html

