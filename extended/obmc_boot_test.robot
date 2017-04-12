*** Settings ***
Documentation  Do random repeated boots based on the state of the BMC machine.

Resource  obmc_boot_test_resource.robot

*** Variables ***
*** Test Cases ***
General Boot Testing
    [Documentation]  Performs repeated boot tests.
    [Tags]  General_boot_testing
    [Teardown]  Test Teardown

    # Call the Main keyword to prevent any dots from appearing in the console
    # due to top level keywords.
    Main

*** Keywords ***
###############################################################################
Main
    [Teardown]  Main Keyword Teardown

    # This is the "Main" keyword.  The advantages of having this keyword vs
    # just putting the code in the *** Test Cases *** table are:
    # 1) You won't get a green dot in the output every time you run a keyword.

    OBMC Boot Test

###############################################################################
