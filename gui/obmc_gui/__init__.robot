*** Settings ***
Documentation  Main initialization file for the test cases contained in this
...            directory and setting up the test environment variables.

Resource          lib/resource.robot
Suite Setup       Initializing Setup
Suite Teardown    Init Teardown Steps

*** Keywords ***
Initializing Setup
    [Documentation]  Initialize test environment.
    Get OpenBMC System Info
    Launch OpenBMC GUI Browser
    Login OpenBMC GUI
    Initial Message
    LogOut OpenBMC GUI

Initial Message
    [Documentation]  Display initial info about the test cases.
    Rpvars  EXECDIR
    Rprint Timen  OBMC_GUI Testing ==> [IN PROGRESS]
    Print Dashes  0  100  1  =

Get OpenBMC System Info
    [Documentation]  Display open BMC system info like system name and IP.
    ${OPENBMC_HOST_NAME}=  Get Hostname From IP Address  ${OPENBMC_HOST}
    Rpvars  OPENBMC_HOST  OPENBMC_HOST_NAME
    ${build_info}  ${stderr}  ${rc}=  BMC Execute Command  cat /etc/os-release
    ...  print_output=1
    Print Dashes  0  100  1  =

Init Teardown Steps
    [Documentation]  End the test execution by closing browser.
    Print Timen  OBMC_GUI Testing ==> [Finished]
    Print Dashes  0  100  1  =
    Close Browser
