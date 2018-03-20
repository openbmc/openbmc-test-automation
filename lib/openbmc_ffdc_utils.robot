*** Settings ***
Documentation      Utility keywords for FFDC

Library            String
Library            DateTime
Library            openbmc_ffdc_list.py
####Resource           logging_utils.robot
Resource           resource.txt
Resource           connection_client.robot
Resource           utils.robot

*** Variables ***

${PRINT_LINE}      ------------------------------------------------------------------------

${MSG_INTRO}       This report contains the following information:
${MSG_DETAIL}      ${\n}\t\t[ Detailed Logs Captured Section ]
${HEADER_MSG}      ${\n}\t\t---------------------------
...                ${\n}\t\t FIRST FAILURE DATA CAPTURE
...                ${\n}\t\t---------------------------
${FOOTER_MSG}      ${\n}${PRINT_LINE} ${\n}

${FFDC_LOG_PATH}   ${EXECDIR}${/}logs${/}
${TEST_HISTORY}    ${FFDC_LOG_PATH}${/}test_history.txt

*** Keywords ***

Get Test Dir and Name
    [Documentation]    SUITE_NAME and TEST_NAME are automatic variables
    ...                and is populated dynamically by the robot framework
    ...                during execution
    ${suite_name}=     Get strip string   ${SUITE_NAME}
    ${suite_name}=     Catenate  SEPARATOR=    ${FFDC_TIME}_   ${suite_name}
    ${test_name}=      Get strip string   ${TEST_NAME}
    ${test_name}=   Catenate  SEPARATOR=  ${FFDC_TIME}_   ${test_name}
    [Return]  ${suite_name}   ${test_name}


Create FFDC Directory
    [Documentation]    Creates directory and report file
    Create Directory   ${FFDC_DIR_PATH}
    Create FFDC Report File


Create FFDC Report File
    [Documentation]     Create a generic file name for ffdc
    Set Suite Variable
    ...  ${FFDC_FILE_PATH}   ${FFDC_DIR_PATH}${/}${FFDC_TIME}_BMC_general.txt
    Create File         ${FFDC_FILE_PATH}


Write Data To File
    [Documentation]     Write data to the ffdc report document
    [Arguments]         ${data}=      ${filepath}=${FFDC_FILE_PATH}
    Append To File      ${filepath}   ${data}


Get Current Time Stamp
    [Documentation]     Get the current time stamp data
    ${cur_time}=    Get Current Date   result_format=%Y-%m-%d %H:%M:%S:%f
    ${cur_time}=    Get strip string   ${cur_time}
    [Return]   ${cur_time}


Header Message
    [Documentation]     Write header message to the report document manifest
    ...                 and return a list of generated files.
    ...                 TEST_NAME, TEST_MESSAGE,SUITE_SOURCE,TEST_DOCUMENTATION
    ...                 are auto variables and are populated dynamically by the
    ...                 robot framework during execution
    ...                 1. Writes opening statement headers msg
    ...                 2. Add Test setup and config information
    ...                 3. Types of data collection

    Write Data To File    ${HEADER_MSG}
    Write Data To File    ${FOOTER_MSG}
    Write Data To File    Test Suite File\t\t: ${SUITE_NAME} ${\n}
    Write Data To File    Test Case Name\t\t: ${TEST_NAME}${\n}
    Write Data To File    Test Source File\t: ${SUITE_SOURCE}${\n}
    Write Data To File    Failure Time Stamp\t: ${FFDC_TIME}${\n}
    Write Data To File    Test Error Message\t: ${TEST_MESSAGE}${\n}
    Write Data To File    Test Documentation\t:${\n}${TEST_DOCUMENTATION}${\n}
    Write Data To File    ${FOOTER_MSG}

    Test Setup Info

    Write Data To File    ${\n}${MSG_INTRO}${\n}

    # --- FFDC header notes ---
    @{entries}=     Get ffdc cmd index
    :FOR  ${index}  IN   @{entries}
    \   Write Data To File   * ${index.upper()}
    \   Write Data To File   ${\n}

    Write Data To File    ${MSG_DETAIL}
    ${ffdc_file_list}=  Create List  ${FFDC_FILE_PATH}
    [Return]  ${ffdc_file_list}


Write Cmd Output to FFDC File
    [Documentation]      Write cmd output data to the report document
    [Arguments]          ${name_str}   ${cmd}

    Write Data To File   ${FOOTER_MSG}
    Write Data To File   ${ENTRY_INDEX.upper()} : ${name_str}\t
    Write Data To File   Executed : ${cmd}
    Write Data To File   ${FOOTER_MSG}


Test Setup Info
    [Documentation]      BMC IP, Model and other information

    Write Data To File  ${\n}-----------------------${\n}
    Write Data To File  Test Setup Information:
    Write Data To File  ${\n}-----------------------${\n}
    Write Data To File  OPENBMC HOST \t: ${OPENBMC_HOST}${\n}
    ${model_name}=  Get BMC System Model
    Write Data To File  SYSTEM TYPE \t: ${model_name}


Error Logs Should Not Exist
    [Documentation]  Verify that error logs do not exist.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=Unexpected BMC error log(s) present.


Error Logs Should Exist
    [Documentation]  Verify that error logs exist.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Run Keyword If  ${resp.status_code} != ${HTTP_OK}  Fail
    ...  msg=Expected BMC error log(s) are not present.
