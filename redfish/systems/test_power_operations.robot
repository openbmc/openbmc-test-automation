*** Settings ***
[Documentation]  This suite tests Redfish BMC power operations.
Resource         ../../lib/bmc_redfish_utils.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Redfish BMC PowerOn
    [Documentation]  Verify Redfish BMC power on operation.
    [Tags]  Verify_Redfish_BMC_PowerOn

    Redfish Power Operation  On
    # TODO: Add logic to verify Redfish BMC power on operation.

Verify Redfish BMC PowerOff
    [Documentation]  Verify Redfish BMC power off operation.
    [Tags]  Verify_Redfish_BMC_PowerOff

    Redfish Power Operation  ForceOff
    # TODO: Add logic to verify BMC power off operation.

Verify Redfish BMC GracefulRestart
    [Documentation]  Verify Redfish BMC gracefulrestart operation.
    [Tags]  Verify_Redfish_BMC_GracefulRestart

    Redfish Power Operation  GracefulRestart
    # TODO: Add logic to verify Redfish BMC gracefulrestart operation.

Verify Redfish BMC GracefulShutdown
    [Documentation]  Verify Redfish BMC gracefulshutdown operation.
    [Tags]  Verify_Redfish_BMC_GracefulShutdown

    Redfish Power Operation  GracefulShutdown
    # TODO: Add logic to verify Redfish BMC gracefulshutdown operation.
