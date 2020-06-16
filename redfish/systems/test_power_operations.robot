*** Settings ***
Documentation    This suite tests Redfish Host power operations.

Resource         ../../lib/boot_utils.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/open_power_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Test Cases ***

Verify Redfish Host GracefulShutdown
    [Documentation]  Verify Redfish host graceful shutdown operation.
    [Tags]  Verify_Redfish_Host_GracefulShutdown

    Redfish Power Off


Verify Redfish BMC PowerOn With OCC State
    [Documentation]  Verify Redfish host power on operation.
    [Tags]  Verify_Redfish_BMC_PowerOn_With_OCC_State

    Redfish Power On

    # TODO: Replace OCC state check with redfish property when available.
    Verify OCC State


Verify Redfish BMC PowerOn
    [Documentation]  Verify Redfish host power on operation.
    [Tags]  Verify_Redfish_Host_PowerOn

    Redfish Power On

    # TODO: Replace OCC state check with redfish property when available.
    Verify OCC State

    Redfish.Login
    ${power_control}=  Redfish.Get Attribute  ${REDFISH_CHASSIS_POWER_URI}  PowerControl
    Rprint Vars   power_control
    Valid Dict  power_control[${0}]  ['PowerConsumedWatts']


Verify Redfish BMC GracefulRestart
    [Documentation]  Verify Redfish host graceful restart operation.
    [Tags]  Verify_Redfish_Host_GracefulRestart

    RF SYS GracefulRestart


Verify Redfish BMC PowerOff
    [Documentation]  Verify Redfish host power off operation.
    [Tags]  Verify_Redfish_Host_PowerOff

    Redfish Hard Power Off

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Start SOL Console Logging


Test Teardown Execution
    [Documentation]  Collect FFDC and SOL log.

    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}

    Redfish.Login
    Run Keyword If  ${REDFISH_SUPPORTED}
    ...    Redfish Set Auto Reboot  RetryAttempts
    ...  ELSE
    ...    Set Auto Reboot  ${1}
    Redfish.Logout
