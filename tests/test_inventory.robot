*** Settings ***
Documentation     System inventory related test.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/openbmc_ffdc.robot

Variables         ../data/variables.py
Variables         ../data/inventory.py

Suite setup       Do Suite Setup
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify System Inventory Path
    [Documentation]  Check if system inventory path exist.
    [Tags]  Verify_System_Inventory_Path
    # When the host is booted, system inventory path should exist.
    # Example: /xyz/openbmc_project/inventory/system
    Get Inventory  system


*** Keywords ***

Do Suite Setup
    [Documentation]  Initial suite setup state.
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot


Get Inventory
    [Documentation]  Get the properties of an endpoint.
    [Arguments]  ${endpoint}
    # Description of arguments:
    # endpoint  string for which url path ending.
    #           Example: "system" is the endpoint for url
    #           /xyz/openbmc_project/inventory/system
    ${resp}=  OpenBMC Get Request  ${BMC_INVENTORY_URI}${endpoint}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata}
