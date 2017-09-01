*** Settings ***
Documentation  Basic BMC Linux kernel stability test.

Resource           ../lib/utils.robot
Resource           ../lib/connection_client.robot
Resource           ../lib/openbmc_ffdc.robot
Resource           ../lib/state_manager.robot

Suite Setup        Open Connection And Log In
Suite Teardown     Close All Connections

# TODO: Collect proc data from system as part of FFDC
# Refer openbmc/openbmc-test-automation#353
Test Teardown      FFDC On Test Case Fail

*** Variables ***


*** Test Cases ***

File System Read Only
    [Documentation]  Read access read-only.
    [Tags]  File_System_Read_Only
    Open Connection And Log In
    ${stdout}  ${stderr}=
    ...  Execute Command  touch cold-play.txt  return_stderr=True
    Should Contain  ${stderr}  Read-only file system


Verify Boot Count After BMC Reboot
    [Documentation]  Verify boot count increments on BMC reboot.
    [Tags]  Verify_Boot_Count_After_BMC_Reboot

    Set BMC Boot Count  ${0}
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready

    ${boot_count}=  Get BMC Boot Count
    Should Be Equal  ${boot_count}  ${1}
    ...  msg=Boot count is not incremented.
