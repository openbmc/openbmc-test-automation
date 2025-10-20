*** Settings ***
Documentation  Do random repeated boots based on the state of the BMC machine.

Resource  obmc_boot_test_resource.robot

Test Tags  Obmc_Boot

*** Test Cases ***

General Boot Testing
    [Documentation]  Performs repeated boot tests.
    [Tags]  General_Boot_Testing
    [Teardown]  Test Teardown

    OBMC Boot Test
