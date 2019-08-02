*** Settings ***
Documentation  Do random repeated boots based on the state of the BMC machine.

Resource  obmc_boot_test_resource.robot

Suite Setup     Run Keyword If  ${REDFISH_SUPPORTED}  Redfish.Login
Suite Teardown  Run Keyword If  ${REDFISH_SUPPORTED}  Redfish.Logout

*** Variables ***

*** Test Cases ***
General Boot Testing
    [Documentation]  Performs repeated boot tests.
    [Tags]  General_boot_testing
    [Teardown]  Test Teardown

    OBMC Boot Test
