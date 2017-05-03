*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/state_manager.robot

Test Teardown       Post Test Case Execution

*** Variables ***

*** Test Cases ***

Verify SOL During Boot
    [Documentation]  Verify SOL during boot.
    [Tags]  Verify_SOL_During_Boot

    Initiate Host PowerOff
    Initiate Host Boot
    Activate SOL Via IPMI
    Sleep  5min

    ${sol_log}=  Deactivate SOL Via IPMI
    Should Contain  ${sol_log}  Petitboot  case_insensitive=True


Verify Deactivate Non Existing SOL
    [Documentation]  Verify deactivate non existing SOL session.
    [Tags]  Verify_Deactivate_Non_Existing_SOL

    ${resp}=  Deactivate SOL Via IPMI
    Should Contain  ${resp}  SOL payload already de-activated
    ...  case_insensitive=True


*** Keywords ***

Post Test Case Execution
   [Documentation]  Do the post test teardown.

   Deactivate SOL Via IPMI
   FFDC On Test Case Fail
