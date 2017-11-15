*** Settings ***
Documentation   This suite is for disable field mode if enabled.

Resource        ../lib/code_update_utils.robot


*** Test Cases ***

Verify Field Mode Is Disable
    [Documentation]  Disable software manager field mode.

    Disable Field Mode And Verify Unmount
