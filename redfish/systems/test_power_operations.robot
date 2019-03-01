*** Settings ***
Documentation    This suite tests Redfish Host power operations.

Resource         ../../lib/boot_utils.robot
Resource         ../../lib/common_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Test Cases ***

Verify Redfish Host GracefulShutdown
    [Documentation]  Verify Redfish host graceful shutdown operation.
    [Tags]  Verify_Redfish_Host_GracefulShutdown

    Redfish Power Off

Verify Redfish BMC PowerOn
    [Documentation]  Verify Redfish host power on operation.
    [Tags]  Verify_Redfish_Host_PowerOn

    Redfish Power On

Verify Redfish BMC GracefulRestart
    [Documentation]  Verify Redfish host graceful restart operation.
    [Tags]  Verify_Redfish_Host_GracefulRestart

    Redfish Host Reboot

Verify Redfish BMC PowerOff
    [Documentation]  Verify Redfish host power off operation.
    [Tags]  Verify_Redfish_Host_PowerOff

    Redfish Hard Power Off

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Start SOL Console Logging


Test Teardown Execution
    [Documentation]  Collect FFDC and SOL log.

    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}
    Set Auto Reboot  ${1}
