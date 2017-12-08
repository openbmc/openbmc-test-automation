*** Settings ***
Documentation   This suite is for disable field mode if enabled.

Resource        ../lib/code_update_utils.robot
Resource        ../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Verify Field Mode Is Disable
    [Documentation]  Disable software manager field mode.

    # Field mode is enabled before running CT.
    # It is to ensure that the setting is not changed during CT
    Field Mode Should Be Enabled
    Disable Field Mode And Verify Unmount
