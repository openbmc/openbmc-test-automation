*** Settings ***
Documentation      Utility keywords for FFDC

Library            String
Library            DateTime
Library            openbmc_ffdc_list.py
Resource           resource.txt
Resource           connection_client.robot

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


Write Data to File
    [Documentation]     Write data to the ffdc report document
    [Arguments]         ${data}=      ${filepath}=${FFDC_FILE_PATH}
    Append To File      ${filepath}   ${data}


Get Current Time Stamp
    [Documentation]     Get the current time stamp data
    ${cur_time}=    Get Current Date   result_format=%Y-%m-%d %H:%M:%S:%f
    ${cur_time}=    Get strip string   ${cur_time}
    [Return]   ${cur_time}


Header Message
    [Documentation]     Write header message to the report document manifest.
    ...                 TEST_NAME, TEST_MESSAGE,SUITE_SOURCE,TEST_DOCUMENTATION
    ...                 are auto variables and are populated dynamically by the
    ...                 robot framework during execution
    ...                 1. Writes opening statement headers msg
    ...                 2. Add Test setup and config information
    ...                 3. Types of data collection

    Write Data to File    ${HEADER_MSG}
    Write Data to File    ${FOOTER_MSG}
    Write Data to File    Test Suite File\t\t: ${SUITE_NAME} ${\n}
    Write Data to File    Test Case Name\t\t: ${TEST_NAME}${\n}
    Write Data to File    Test Source File\t: ${SUITE_SOURCE}${\n}
    Write Data to File    Failure Time Stamp\t: ${FFDC_TIME}${\n}
    Write Data to File    Test Error Message\t: ${TEST_MESSAGE}${\n}
    Write Data to File    Test Documentation\t:${\n}${TEST_DOCUMENTATION}${\n}
    Write Data to File    ${FOOTER_MSG}

    Test Setup Info

    Write Data to File    ${\n}${MSG_INTRO}${\n}

    # --- FFDC header notes ---
    @{entries}=     Get ffdc cmd index
    :FOR  ${index}  IN   @{entries}
    \   Write Data to File   * ${index.upper()}
    \   Write Data to File   ${\n}

    Write Data to File    ${MSG_DETAIL}
    #   Rename OPENBMC_HOST IP address from given file to DUMMY
    Run  sed -i 's/'${OPENBMC_HOST}'/DUMMYIP/g' ${FFDC_FILE_PATH}


Write Cmd Output to FFDC File
    [Documentation]      Write cmd output data to the report document
    [Arguments]          ${name_str}   ${cmd}

    Write Data to File   ${FOOTER_MSG}
    Write Data to File   ${ENTRY_INDEX.upper()} : ${name_str}\t
    Write Data to File   Executed : ${cmd}
    Write Data to File   ${FOOTER_MSG}


Test Setup Info
    [Documentation]      BMC IP, Model and other information

    Write Data to File   ${\n}-----------------------${\n}
    Write Data to File   Test Setup Information:
    Write Data to File   ${\n}-----------------------${\n}
    Write Data to File   OPENBMC HOST \t: ${OPENBMC_HOST}${\n}
    Write Data to File
    ...   SYSTEM TYPE \t: ${OPENBMC_MODEL.replace('./data/','').replace('.py','')}${\n}${\n}
