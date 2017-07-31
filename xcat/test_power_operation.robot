*** Settings ***
Documentation   Module for testing BMC via XCAT.

Resource        ../lib/xcat/resource.txt
Resource        ../lib/xcat/xcat_utils.robot
Resource        ../lib/state_manager.robot

Library         OperatingSystem
Library         String

Suite Setup     XCAT Suite Setup
#Test Setup      Open Connection And Log In
#Test Teardown   Close All Connections

*** Variables ***

*** Test Cases ***

Verify Power On Via XCAT
    [Documentation]  Power on system via XCAT and verify using REST.
    [Tags]  Verify_Power_On_Via_XCAT

    Power On Via XCAT  ${OPENBMC_HOST}
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Running


Verify Power Off Via XCAT
    [Documentation]  Power off system via XCAT and verify using REST.
    [Tags]  Verify_Power_Off_Via_XCAT

    Power Off Via XCAT  ${OPENBMC_HOST}
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off


*** Keywords ***

XCAT Suite Setup
    [Documentation]  XCAT suite setup.

    Open Connection And Login To XCAT

    # Check if XCAT is installed.
    ${cmd_output}=  Execute Command  ${XCAT_DIR_PATH}/lsxcatd -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Add Nodes To XCAT  ${OPENBMC_HOST}
