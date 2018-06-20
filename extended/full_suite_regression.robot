*** Settings ***
Documentation      This suite is for testing Open BMC full test suite.
...                Maintains log.html output.xml  for each iteration and
...                generate combined report

Resource  ../lib/utils.robot
Resource  ../lib/connection_client.robot
Library  OperatingSystem
Library  DateTime

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections

Force Tags  Full_Suite_Regression

*** Variables ***
${ITERATION}          10
${RESULT_DIR_NAME}    logsdir
${LOOP_TEST_COMMAND}  tests

*** Test Cases ***
Validate BMC Model
   [Documentation]  Check that OPENBMC_MODEL is correct.
   [Tags]  Validate_BMC_Model
   ${bmc_model}=  Get BMC System Model
   ${status}=  Verify BMC System Model  ${bmc_model}
   Run Keyword If  '${status}'=='False'  Fatal Error  Wrong System

Run Entire Test Suite Multiple Time
   [Documentation]  Multiple iterations of Full Suite

   Should Be True  0<${ITERATION}

   ${timestamp}=  Get Current Date  result_format=%Y%m%d%H%M%S
   ${tmp_result_dir_path}=  Catenate  ${RESULT_DIR_NAME}${timestamp}
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
   [Tags]  Create_Combined_Report

   Run  rebot --name ${OPENBMC_SYSTEMMODEL}CombinedReport ${RESULT_DIR_PATH}/output*.xml

   ${current_time}=  Get Current Date  result_format=%Y%m%d%H%M%S
   ${combined_report_file}=  Catenate  SEPARATOR=  ${EXECDIR}
   ...  /logs/CombinedLogReport${current_time}.html

   Copy File  log.html  ${combined_report_file}

   Run Keyword And Ignore Error  Convert HTML To PDF  ${combined_report_file}

*** Keywords ***

Convert HTML To PDF
   [Documentation]  Convert HTML to PDF in order to support GitHub
   ...  attachment.
   [Arguments]  ${combined_report_html_file_path}
   # Description of arguments:
   # combined_report_html_file_path  Combined report file in HTML format.

   Log To Console  \n ${combined_report_html_file_path}
   ${combined_report_pdf_file_path}=
   ...  Fetch From Left  ${combined_report_html_file_path}  .
   # Compose combined_report_pdf_file_path.
   ${combined_report_pdf_file_path}=  Catenate  SEPARATOR=
   ...  ${combined_report_pdf_file_path}  .pdf
   # wkhtmltopdf tool is to convert HTML to PDF
   ${output}=  Run  which wkhtmltopdf
   Should Not Be Empty  ${output}
   ...  msg=wkhtmltopdf not installed, Install from http://wkhtmltopdf.org
   ${output}=
   ...  Run  wkhtmltopdf ./${combined_report_html_file_path} ./${combined_report_pdf_file_path}
   Should Not Be Empty  ${output}
   OperatingSystem.File Should Exist  ${combined_report_pdf_file_path}