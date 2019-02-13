*** Settings ***
Documentation    This suite tests Redfish BMC power operations.
Resource         ../../lib/boot_utils.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Redfish BMC GracefulShutdown
    [Documentation]  Verify Redfish BMC gracefulshutdown operation.
    [Tags]  Verify_Redfish_BMC_GracefulShutdown

    Redfish Power Off

Verify Redfish BMC PowerOn
    [Documentation]  Verify Redfish BMC power on operation.
    [Tags]  Verify_Redfish_BMC_PowerOn

    Redfish Power On

Verify Redfish BMC GracefulRestart
    [Documentation]  Verify Redfish BMC gracefulrestart operation.
    [Tags]  Verify_Redfish_BMC_GracefulRestart

    Redfish Host Reboot

Verify Redfish BMC PowerOff
    [Documentation]  Verify Redfish BMC power off operation.
    [Tags]  Verify_Redfish_BMC_PowerOff

    Redfish Hard Power Off
