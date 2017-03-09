*** Settings ***
Documentation     System inventory related test.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/openbmc_ffdc.robot

Variables         ../data/variables.py
Variables         ../data/inventory.py

Suite setup       Test Suite Setup
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify System Inventory Path
    [Documentation]  Check if system inventory path exist.
    [Tags]  Verify_System_Inventory_Path
    # When the host is booted, system inventory path should exist.
    # Example: /xyz/openbmc_project/inventory/system
    Get Inventory  system


Verify Chassis Motherboard Properties
    [Documentation]  Check if chassis motherboard properties are
    ...              populated valid.
    [Tags]  Verify_Chassis_Motherboard_Properties
    # When the host is booted, the following properties should
    # be populated Manufacturer, PartNumber, SerialNumber and
    # it should not be zero's.
    # Example:
    #   "data": {
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard": {
    #  "BuildDate": "",
    #  "Manufacturer": "0000000000000000",
    #  "Model": "",
    #  "PartNumber": "0000000",
    #  "Present": 0,
    #  "PrettyName": "SYSTEM PLANAR   ",
    #  "SerialNumber": "000000000000"
    # }
    ${properties}=  Get Inventory  system/chassis/motherboard
    Should Not Be Equal As Strings
    ...  ${properties["data"]["Manufacturer"]}  0000000000000000
    ...  msg=motherboard field invalid.
    Should Not Be Equal As Strings
    ...  ${properties["data"]["PartNumber"]}  0000000
    ...  msg=motherboard part number invalid.
    Should Not Be Equal As Strings
    ...  ${properties["data"]["SerialNumber"]}  000000000000
    ...  msg=motherboard serial number invalid.

*** Keywords ***

Test Suite Setup
    [Documentation]  Do the initial suite setup.
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is Host OS Started


Get Inventory
    [Documentation]  Get the properties of an endpoint.
    [Arguments]  ${endpoint}
    # Description of arguments:
    # endpoint  string for which url path ending.
    #           Example: "system" is the endpoint for url
    #           /xyz/openbmc_project/inventory/system
    ${resp}=  OpenBMC Get Request  ${HOST_INVENTORY_URI}${endpoint}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata}
