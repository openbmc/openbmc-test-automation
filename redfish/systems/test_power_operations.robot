*** Settings ***
Documentation    This suite tests Redfish host power operations.
Resource         ../../lib/boot_utils.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Redfish Host PowerOff
    [Documentation]  Verify Redfish Host power off operation.
    [Tags]  Verify_Redfish_Host_PowerOff

    Redfish Hard Power Off  stack_mode=skip

Verify Redfish Host PowerOn
    [Documentation]  Verify Redfish Host power on operation.
    [Tags]  Verify_Redfish_Host_PowerOn

    Redfish Power On  stack_mode=skip

Verify Redfish Host GracefulRestart
    [Documentation]  Verify Redfish Host gracefulrestart operation.
    [Tags]  Verify_Redfish_Host_GracefulRestart

    Redfish Host Reboot  stack_mode=skip

Verify Redfish Host GracefulShutdown
    [Documentation]  Verify Redfish Host gracefulshutdown operation.
    [Tags]  Verify_Redfish_Host_GracefulShutdown

    Redfish Power Off  stack_mode=skip

