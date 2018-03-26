*** Settings ***
Documentation   This suite is for disable field mode if enabled.

Resource        ../lib/code_update_utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/dump_utils.robot

Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Verify Field Mode Is Disable
    [Documentation]  Disable software manager field mode.

    # Field mode is enabled before running CT.
    # It is to ensure that the setting is not changed during CT
    Field Mode Should Be Enabled
    Disable Field Mode And Verify Unmount


Delete BMC Dumps And Verify
    [Documentation]  Delete BMC dumps and verify.
    [Tags]  Delete_BMC_Dumps_And_Verify

    Delete All BMC Dump
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=BMC dump(s) were not deleted as expected.
