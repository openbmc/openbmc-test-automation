*** Settings ***
Documentation      This suite is for testing Open BMC full test suite.
...                Maintains log.html output.xml  for each iteration and
...                generate combined report

Library  OperatingSystem
Library  DateTime

*** Variables ***
 ${ITERATION}  10
 ${RESULT_DIR_NAME}  logsdir
 ${LOOP_TEST_COMMAND}  tests

*** Test Cases ***
Run Entire Test Suite Multiple Time
   [Documentation]  Multiple iterations of Full Suite

   Should Be True  0<${ITERATION}

   ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
   ${tmp_result_dir_path}=  Catenate   ${RESULT_DIR_NAME}${timestamp}
   Set Suite Variable  ${RESULT_DIR_PATH}  ${tmp_result_dir_path}
   Log To Console  ${RESULT_DIR_PATH}
   Create Directory  ${RESULT_DIR_PATH}

   : FOR    ${INDEX}    IN RANGE    0    ${ITERATION}
    \    Log To Console  \n Iteration:   no_newline=True
    \    Log To Console  ${INDEX}
    \    Run  OPENBMC_HOST=${OPENBMC_HOST} tox -e ${OPENBMC_SYSTEMMODEL} -- ${LOOP_TEST_COMMAND}
    \    Run  sed -i 's/'${OPENBMC_HOST}'/DUMMYIP/g' output.xml
    \    Copy File  output.xml   ${RESULT_DIR_PATH}/output${INDEX}.xml
    \    Copy File  log.html   ${RESULT_DIR_PATH}/log${INDEX}.html

Create Combined Report
   [Documentation]  Using output[?].xml and create combined log.html

   Run  rebot --name ${OPENBMC_SYSTEMMODEL}CombinedReport ${RESULT_DIR_PATH}/output*.xml
   Move File  log.html  ${RESULT_DIR_PATH}/log${OPENBMC_SYSTEMMODEL}CombinedIterations${ITERATION}Report.html
