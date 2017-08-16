*** Settings ***
Documentation  Main initialization file for the test cases
...  contained in this directory and setting up the
...  test environment variables.

Resource  ${PATH_TEST_RESOURCES_1}${/}${RESOURCE_FILE_1}
Resource  ${PATH_TEST_RESOURCES_2}${/}${RESOURCE_FILE_2}
Suite Setup  Initializing Setup
Suite Teardown  Init Teardown Steps

*** Variables ***
${PATH_TEST_RESOURCES_1}  ${EXECDIR}${/}obmc_asmi/lib/
${PATH_TEST_RESOURCES_2}  ${EXECDIR}${/}..${/}lib/
${RESOURCE_FILE_1}  resource.robot
${RESOURCE_FILE_2}  resource.txt
${OBMC_ASMi_BLUEMiX_URL}  https://openbmc-test.mybluemix.net/#/login
# TO Do: Need to change the varilabe once the code finally switches to the BMC.
${BROWSER}  chrome

*** Keywords ***
Initializing Setup
    Set Paths
    Launch OpenBMC ASMi Browser
    Login OpenBMC GUI
    Get OpenBMC System Parameters
    Initial Message
    LogOut OpenBMC GUI

Set Paths
    [Documentation]  Set the path for all environment variables.
    Set Global Variable  ${OBMC_ASMi_BLUEMIX_URL}
    Set Global Variable  ${BROWSER}
    Set Global Variable  ${PATH_TEST_RESOURCES_1}
    Set Global Variable  ${RESOURCE_FILE_1}
    Set Global Variable  ${PATH_TEST_RESOURCES_2}
    Set Global Variable  ${RESOURCE_FILE_2}

Initial Message
    [Documentation]  Displaying of intial info about the test cases.
    Rpvars  0  0  9  EXECDIR
    Rprint Timen  OBMC_ASMi Testing ==> [IN PROGRESS]
    Print Dashes  0  100  1  =

Get OpenBMC System Parameters
    [Documentation]  Get Open BMC system parameters like
    ...  system name and its IP address.
    ${l_text_outPut}=  Get Text  ${xpath_DISPLAY_TXT_OBMC_IP}
    ${OBMC_IP_ADDRESS}=  Fetch From Right
    ...  ${l_text_outPut}  marker=${SPACE}
    Log To Console  Open BMC system details are as Follows:
    Set Global Variable  ${OBMC_IP_ADDRESS}
    ${OBMC_HOST_NAME}=  Get Hostname From IP Address
    ...  ${OBMC_IP_ADDRESS}
    Rpvars  0  0  17  OBMC_IP_ADDRESS  OBMC_HOST_NAME
    Set Global Variable  ${OBMC_HOST_NAME}
    Get SSH Connection
    ${l_OutPut}  ${l_stderr}=  SSHLibrary.Execute Command
    ...  cat /etc/os-release  return_stderr=True
    Should Be Empty  ${l_stderr}
    Log To Console  Current Build Image Detail is: ${l_OutPut}
    Print Dashes  0  100  1  =

Init Teardown Steps
    [Documentation]  End the test execution by closing browser.
    Print Timen  OBMC_ASMi Testing ==> [Finished]
    Print Dashes  0  100  1  =
    Close Browser
