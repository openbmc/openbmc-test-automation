*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/state_manager.robot

Test Teardown       Post Test Case Execution

*** Variables ***
${WAIT_TIME_HOST_BOOT}=  5min

*** Test Cases ***

Verify Activate SOL
    [Documentation]  Verify activate SOL session.
    [Tags]  Verify_Activate_SOL

    Activate SOL Via IPMI
    ${sol_log}=  Stop SOL session
    Should Contain  ${sol_log}  SOL Session operational


Verify Deactivate Existing SOL
    [Documentation]  Verify deactivate existing SOL session.
    [Tags]  Verify_Deactivate_Existing_SOL

    Activate SOL Via IPMI
    Deactivate SOL Via IPMI
    ${resp}=  Stop SOL session
    Should Contain  ${resp}  No SOL running

Verify Deactivate Non Existing SOL
    [Documentation]  Verify deactivate non existing SOL session.
    [Tags]  Verify_Deactivate_Non_Existing_SOL

    ${resp}=  Deactivate SOL Via IPMI
    Should Contain  ${resp}  SOL payload already de-activated


Verify SOL During Boot
    [Documentation]  Verify SOL during boot.
    [Tags]  Verify_SOL_During_Boot

    Initiate Host PowerOff
    Activate SOL Via IPMI
    Initiate Host Boot
    Sleep  ${WAIT_TIME_HOST_BOOT}

    ${sol_log}=  Stop SOL session
    Should Contain  ${sol_log}  Petitboot


*** Keywords ***

Post Test Case Execution
   [Documentation]  Do the post test teardown.

   Terminate All Processes  kill=true
   FFDC On Test Case Fail
