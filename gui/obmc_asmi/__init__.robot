*** Settings ***
Documentation  Main initialization file for the test cases contained
...  in this directory and setting up the test environment variables.

Resource          lib/resource.robot
Suite Setup       Initializing Setup
Suite Teardown    Init Teardown Steps

*** Keywords ***
Initializing Setup
    [Documentation]  Initialize test environment.
    Launch OpenBMC ASMi Browser
    Login OpenBMC GUI
    Get OpenBMC System Info
    Initial Message
    LogOut OpenBMC GUI

Initial Message
    [Documentation]  Display of intial info about the test cases.
    Rpvars  0  0  9  EXECDIR
    Rprint Timen  OBMC_ASMi Testing ==> [IN PROGRESS]
    Print Dashes  0  100  1  =

Get OpenBMC System Info
    [Documentation]  Disply of OpenBMC system
    ...  Info like system name and its IP.
    Log To Console  Open BMC system details are as follows:
    ${OPENBMC_HOST_NAME}=  Get Hostname From IP Address
    ...  ${OPENBMC_HOST}
    Rpvars  0  0  20  OPENBMC_HOST  OPENBMC_HOST_NAME
    ${build_info}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/os-release
    Should Be Empty  ${stderr}
    Log To Console  Current Build Image Detail is: ${build_info}
    Print Dashes  0  100  1  =

Init Teardown Steps
    [Documentation]  End the test execution by closing browser.
    Print Timen  OBMC_ASMi Testing ==> [Finished]
    Print Dashes  0  100  1  =
    Close Browser
