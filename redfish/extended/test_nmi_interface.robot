*** Settings ***
Documentation   Test Non-maskable interrupt functionality.

Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/boot_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout

*** Test Cases ***

Trigger NMI When OPAL/Host OS Is Not Up
    [Documentation]  Verify error while injecting NMI when HOST OS is not up.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Not_Up

    Redfish Power Off  stack_mode=skip
    Redfish.Login
    Redfish.Post  ${SYSTEM_BASE_URI}Actions/ComputerSystem.Reset
    ...  body={"ResetType": "Nmi"}  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR}]
