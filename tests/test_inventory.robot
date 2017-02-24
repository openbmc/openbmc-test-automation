*** Settings ***
Documentation     System inventory related test.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/openbmc_ffdc.robot

Variables         ../data/variables.py
Variables         ../data/inventory.py

Suite setup       Inventory Suite Setup
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify System Inventory
    [Documentation]  Check If system FRU endpoints are loaded.
    [Tags]  Verify_System_Inventory
    Get Inventory  system


*** Keywords ***

Inventory Suite Setup
    [Documentation]  Initial suite setup state.
    ${currentState}=  Get Host State
    Run Keyword If  '${currentState}' == 'Off'
    ...  Initiate Host Boot


Get Inventory
    [Documentation]  Get property of an endpoint.
    [Arguments]  ${endpoint}
    ${resp}=  OpenBMC Get Request  ${BMC_INVENTORY_URI}${endpoint}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata}
