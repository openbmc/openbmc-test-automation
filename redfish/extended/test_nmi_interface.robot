*** Settings ***
Documentation   Test Host crash dump collection via Non Mask Interupter - NMI interface.

Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/boot_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail
Suite Teardown  Suite Teardown Execution

*** Test Cases ***

Test NMI Interface When Host Is Off
    [Documentation]  Trigger NMI request and verify response.
    [Tags]  Test_NMI_Interface_When_Host_Is_Off

    Redfish Power Off  stack_mode=skip
    Redfish.Login
    Redfish.Post  /redfish/v1/Systems/system/Actions/ComputerSystem.Reset  body={"ResetType": "Nmi"}  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR}]

*** Keywords ***

Suite Teardown Execution
    [Documentation]  Do the suite teardown.

    Redfish.Logout
