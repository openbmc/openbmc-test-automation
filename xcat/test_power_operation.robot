*** Settings ***
Documentation   Module for testing BMC via XCAT.

Resource        ../lib/xcat/resource.robot
Resource        ../lib/xcat/xcat_utils.robot
Resource        ../lib/state_manager.robot

Library         OperatingSystem
Library         String

Suite Setup     Test Suite Setup

*** Variables ***

*** Test Cases ***

Verify Power On Via XCAT
    [Documentation]  Power on system via XCAT and verify using REST.
    [Tags]  Verify_Power_On_Via_XCAT

    Execute Command On XCAT  rpower  on
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running


Verify Power Off Via XCAT
    [Documentation]  Power off system via XCAT and verify using REST.
    [Tags]  Verify_Power_Off_Via_XCAT

    Execute Command On XCAT  rpower  off
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off


Verify BMC State via XCAT
    [Documentation]  Verify BMC state using REST and XCAT.
    [Tags]  Verify_BMC_State_Via_XCAT

    ${xcat_resp}=  Execute Command On XCAT  rpower  bmcstate
    ${rest_resp}=  Get BMC State
    Should contain  ${xcat_resp}  ${rest_resp}


Verify Soft Power Off Followed With Power On
    [Documentation]  Verify soft power off system followed with power on.
    [Tags]  Verify_Soft_Power_Off_Followed_With_Power_On
    [Setup]  Initiate Host Boot

    Execute Command On XCAT  rpower  softoff
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off

    Execute Command On XCAT  rpower  on
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running


Verify Hard Power Off Followed With Power On
    [Documentation]  Verify hard power off system followed with power on.
    [Tags]  Verify_Hard_Power_Off_Followed_With_Power_On
    [Setup]  Initiate Host Boot

    Execute Command On XCAT  rpower  off
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off

    Execute Command On XCAT  rpower  on
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running


*** Keywords ***

Test Suite Setup
    [Documentation]  Do the initial suite setup.

    Open Connection And Login To XCAT

    # Check if XCAT is installed.
    ${cmd_output}=  Execute Command  ${XCAT_DIR_PATH}/lsxcatd -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Add Nodes To XCAT  ${OPENBMC_HOST}
