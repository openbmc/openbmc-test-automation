*** Settings ***
Documentation       Do random repeated boots based on the state of the BMC machine.

Resource            obmc_boot_test_resource.robot


*** Test Cases ***
General Boot Testing
    [Documentation]    Performs repeated boot tests.
    [Tags]    general_boot_testing

    OBMC Boot Test
    [Teardown]    Test Teardown
