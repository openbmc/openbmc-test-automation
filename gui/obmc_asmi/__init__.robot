*** Settings ***
Documentation  Main file for the test case It contains
...  initalizing steps.

Resource  ${PATH_TEST_RESOURCES}${/}${RESOURCE_FILE}
Suite Setup  Initializing Setup
Suite Teardown  Init Teardown Steps

*** Variables ***
${PATH_TEST_RESOURCES}  ${EXECDIR}${/}obmc_asmi/lib/
${RESOURCE_FILE}  resource.robot
${OBMC_ASMi_BLUEMiX_URL}  https://openbmc-test.mybluemix.net/#/login
${OBMC_ROOT_ID}  root
${OBMC_ROOT_PASSWORD}  0penBmc
${BROWSER}  chrome
${PRINT_DOUBLE_LINE}  ===================================================================================================

*** Keywords ***
Initializing Setup
    Set Global Variable  ${OBMC_ASMi_BLUEMIX_URL}
    Set Global Variable  ${OBMC_ROOT_ID}
    Set Global Variable  ${OBMC_ROOT_PASSWORD}
    Set Global Variable  ${BROWSER}
    Set Global Variable  ${PRINT_DOUBLE_LINE}

    Set Paths
    Initial Message
    Launch OpenBMC ASMi Browser
    Login OpenBMC GUI
    Get OpenBMC System Parameters
    LogOut OpenBMC GUI

Set Paths
    [Documentation]  This function keyword set the path for all
    ...  environment variables.
    Set Global Variable  ${PATH_TEST_RESOURCES}
    Set Global Variable  ${RESOURCE_FILE}
    Log To Console  Execution Dir: ${EXECDIR}

Initial Message
    [Documentation]  Initial Message for displaying on Console.
    ${OBMC_ASMi_START_TIME}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    Set Global Variable  ${OBMC_ASMI_START_TIME}
    Log To Console  ${OBMC_ASMI_START_TIME} OBMC_ASMi Testing ==> [IN PROGRESS]
    Log To Console  ${PRINT_DOUBLE_LINE}

Launch OpenBMC ASMi Browser
    [Documentation]  launches the OpenBMC ASMi url on browser.
    Open Browser With mybluemix.net URL

Get OpenBMC System Parameters
    [Documentation]  Get Open BMC system parameters like
    ...  system name and its IP address.
    ${l_Text_OutPut}=  Get Text    ${xpath_DISPLAY_TXT_OBMC_IP}
    ${OBMC_IP_ADDRESS}=  Fetch From Right
    ...  ${l_Text_OutPut}  marker=${SPACE}
    Log To Console  Open BMC System Details are as Follows:
    Log To Console  IP Address is: ${OBMC_IP_ADDRESS}
    Set Global Variable  ${OBMC_IP_ADDRESS}
    ${OBMC_HOST_NAME}=  Get Hostname From IP Address
    ...  ${OBMC_IP_ADDRESS}
    Log To Console  Host Name is: ${OBMC_HOST_NAME}
    Set Global Variable  ${OBMC_HOST_NAME}
    Get SSH Connection
    ${l_OutPut}  ${l_stderr}=  SSHLibrary.Execute Command
    ...  cat /etc/os-release  return_stderr=True
    Should Be Empty  ${l_stderr}
    Log To Console  Current Build Image Detail is: ${l_OutPut}
    Log To Console  ${PRINT_DOUBLE_LINE}

Init Teardown Steps
    [Documentation]  Will do the end the test execution.
    ${OBMC_ASMi_END_TIME}=  Get Current Date
    ...  result_format=%Y-%m-%d %H:%M:%S,%f
    Log To Console  Test Case Execution End Time: ${OBMC_ASMi_END_TIME}
    Log To Console  ${PRINT_DOUBLE_LINE}
    Close Browser

