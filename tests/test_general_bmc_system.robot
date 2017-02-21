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

Verify Boot Count After BMC Reboot
    [Documentation]  Verify boot count increments on BMC reboot.
    [Tags]  Verify_Boot_Count_After_BMC_Reboot

    Set BMC Boot Count  ${0}
    Initiate BMC Reboot
    ${boot_count}=  Get BMC Boot Count
    Should Be Equal  ${boot_count}  ${1}
    ...  msg=Reboot did not happen.
