*** Settings ***

Documentation    Module to test PLDM BIOS commands.

Library           Collections
Library           String
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail
Suite Teardown   PLDM BIOS Suite Cleanup

*** Test Cases ***

Verify GetDateTime

    [Documentation]  Verify Date & Time.
    [Tags]  Verify_GetDateTime

    ${pldm_output}=  Pldmtool  ${CMD_GETDATETIME}
    @{result}=  Split String  ${pldm_output['yyyy-mm-dd_hh']}  ${SPACE}
    @{time}=  Split String  ${result}[3]  :

    # verify date & time.
    ${current_date_time}=  Get Current Date  UTC  exclude_millis=True
    Should Contain  ${current_date_time}  ${result}[2]
    Should contain  ${current_date_time}  ${time}[0]


Verify SetDateTime

    [Documentation]  Verify set date time.
    [Tags]  Verify_SetDateTime

    ${current_date_time}=  Get Current Date  UTC  exclude_millis=True

    ${date}=  Add Time To Date  ${current_date_time}  400 days  exclude_millis=True
    ${upgrade_date}=  Evaluate  re.sub(r'-* *:*', "", '${date}')  modules=re

    ${time}=  Add Time To Date  ${current_date_time}  01:01:00  exclude_millis=True
    ${upgrade_time}=  Evaluate  re.sub(r'-* *:*', "", '${time}')  modules=re

    # Set date.
    ${cmd_set_date}=  Evaluate  $CMD_SETDATETIME % '${upgrade_date}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date}
    Should contain  ${pldm_output['setdatetime']}  SUCCESS

    # Set time.
    ${cmd_set_time}=  Evaluate  $CMD_SETDATETIME % '${upgrade_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_time}
    Should contain  ${pldm_output['setdatetime']}  SUCCESS

*** Keywords ***

PLDM BIOS Suite Cleanup

    [Documentation]  Perform pldm BIOS suite cleanup.

    ${result}=  Get Current Date  UTC  exclude_millis=True
    ${current_date_time}=  Evaluate  re.sub(r'-* *:*', "", '${result}')  modules=re
    ${cmd_set_date_time}=  Evaluate  $CMD_SETDATETIME % '${current_date_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date_time}
    Should contain  ${pldm_output['setdatetime']}  SUCCESS
