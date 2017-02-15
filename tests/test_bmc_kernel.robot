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

${TEST_BOOT_COUNT}  ${1}

*** Test Cases ***

Kernel Reboot Test
    [Documentation]  Reboot BMC and validate proc btime.
    [Tags]  Kernel_Reboot_Test

    Set BMC Reset Reference Time
    Initiate BMC Reboot
    Set BMC Reset Reference Time
    Should Be Equal  ${BOOT_COUNT}  ${TEST_BOOT_COUNT}
    ...  msg=Kernel proc boot time is persistent.

