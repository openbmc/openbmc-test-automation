*** Settings ***
Documentation  Cleanup user patches from BMC.

Resource   ../lib/bmc_cleanup.robot

*** Test Cases ***

Cleanup User Patches
    [Documentation]  Do the cleanup in cleanup directory path.
    [Tags]  Cleanup_User_Patches

    Cleanup Dir
