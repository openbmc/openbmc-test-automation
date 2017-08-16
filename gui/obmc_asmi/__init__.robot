*** Settings ***
Documentation  Main initialization file for the test cases
...  contained in this directory and setting up the
...  test environment variables.

Resource  ${TEST_RESOURCES_DIR_PATH_1}${/}${RESOURCE_FILE_1}
Resource  ${TEST_RESOURCES_DIR_PATH_2}${/}${RESOURCE_FILE_2}
Suite Setup  Initializing Setup
Suite Teardown  Init Teardown Steps

*** Variables ***
${TEST_RESOURCES_DIR_PATH_1}  ${EXECDIR}${/}obmc_asmi/lib
${TEST_RESOURCES_DIR_PATH_2}  ${EXECDIR}${/}..${/}lib
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
    Set Global Variable  ${TEST_RESOURCES_DIR_PATH_1}
    Set Global Variable  ${RESOURCE_FILE_1}
    Set Global Variable  ${TEST_RESOURCES_DIR_PATH_2}
    Set Global Variable  ${RESOURCE_FILE_2}

Initial Message
    [Documentation]  Displaying of intial info about the test cases.
    Log To Console  Test execution dir path: ${EXECDIR}
    Rprint Timen  OBMC_ASMi Testing ==> [IN PROGRESS]
    Print Dashes  0  100  1  =

Get OpenBMC System Parameters
    [Documentation]  Get Open BMC system parameters like
    ...  system name and its IP address.
    ${l_text_output}=  Get Text  ${xpath_DISPLAY_TXT_OBMC_IP}
    ${OPENBMC_IP}=  Fetch From Right
    ...  ${l_text_output}  marker=${SPACE}
    Log To Console  Open BMC system details are as follows:
    Set Global Variable  ${OPENBMC_IP}
    ${OPENBMC_HOST_NAME}=  Get Hostname From IP Address
    ...  ${OPENBMC_IP}
    Rpvars  0  0  17  OPENBMC_IP  OPENBMC_HOST_NAME
    Set Global Variable  ${OPENBMC_HOST_NAME}
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
