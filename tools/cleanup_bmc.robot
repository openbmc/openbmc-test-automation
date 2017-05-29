*** Settings ***
Documentation  Cleanup user patches from BMC.

Resource   ../lib/utils.robot

*** Test Cases ***

Cleanup User Patches
    [Documentation]  Do the cleanup in cleanup directory path.

    Remove Files
