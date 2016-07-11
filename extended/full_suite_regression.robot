*** Settings ***
Documentation      This suite is for testing Open BMC full test suite. 
...                Maintains log.html output.xml  for each iteration and
...                generate combined report

Library           OperatingSystem
Library           SSHLibrary

Suite Teardown    Close All Connections

*** Variables ***
 ${ITERATION}  10
 ${SYSTEMTYPE}

*** Test Cases ***
Run Tests Multiple Time
   [Documentation]  Multiple iterations of Full Suite

   Should Be True  0<${ITERATION}
   ${SYSTEMTYPE}=   Get System Type
   Create Directory   ../logsdir
   : FOR    ${INDEX}    IN RANGE    0    ${ITERATION}
    \    Log To Console     \n Iteration:   no_newline=True
    \    Log To Console    ${INDEX}
    \    Run  OPENBMC_HOST=${OPENBMC_HOST} tox -e ${SYSTEMTYPE} -- ../tests
    \    Copy File    output.xml   ../logsdir/output${INDEX}.xml
    \    Copy File    log.html   ../logsdir/log${INDEX}.html

Create Combined Report
   [Documentation]   Using output[?].xml and create combined log.html

   Run  rebot --name ${SYSTEMTYPE}CombinedReport ../logsdir/output*.xml
   Move File  log.html ../logsdir/log${SYSTEMTYPE}CombinedIterations${ITERATION}Report.html

*** Keywords ***
Get System Type
    [Documentation]   Returns  the system type

    Open connection    ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${output}  ${stderr}=   Execute Command  hostname   return_stderr=True
    Should Be Empty     ${stderr}
    set test variable   ${l_SYSTEMTYPE}     ${output}
    Log to Console   \n ${l_SYSTEMTYPE}
    [return]   ${l_SYSTEMTYPE}
