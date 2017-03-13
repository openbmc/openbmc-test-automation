*** Settings ***
Documentation     System inventory related test.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/openbmc_ffdc.robot
Library           ../lib/utilities.py

Variables         ../data/variables.py
Variables         ../data/inventory.py

#Suite setup       Test Suite Setup
#Test Teardown     FFDC On Test Case Fail

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

Verify CPU Present
    [Tags]  Verify_CPU_Present
    # System inventory cpu list:
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1
    # Example:
    #    "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0": {
    #    "FieldReplaceable": 1,
    #    "BuildDate": "",
    #    "Cached": 0,
    #    "SerialNumber": "YA3933741574",
    #    "Version": "10",
    #    "Model": "",
    #    "PrettyName": "PROCESSOR MODULE",
    #    "PartNumber": "01HL322",
    #    "Present": 1,
    #    "Manufacturer": "IBM"
    # },
    # The CPU properties "Present" should be boolean 1.

    ${cpu_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  cpu
    :FOR  ${cpu_uri}  IN  @{cpu_list}
    \  ${present}=  Read Attribute  ${cpu_uri}  Present
    \  Should Be True  ${present}


Verify DIMM Present
    [Tags]  Verify_DIMM_Present
    # Example:
    #   "/xyz/openbmc_project/inventory/system/chassis/motherboard/dimm0": {
    #    "FieldReplaceable": 1,
    #    "BuildDate": "",
    #    "Cached": 0,
    #    "SerialNumber": "0x0300cf4f",
    #    "Version": "0x00",
    #    "Model": "M393A1G40EB1-CRC    ",
    #    "PrettyName": "0x0c",
    #    "PartNumber": "",
    #    "Present": 1,
    #    "Manufacturer": "0xce80"
    # },

    # The DIMM properties "Present" should be boolean 1.

    ${dimm_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  dimm
    :FOR  ${dimm_uri}  IN  @{dimm_list}
    \  ${present}=  Read Attribute  ${dimm_uri}  Present
    \  Should Be True  ${present}


Verify FRU Properties
    [Tags]  Verify_FRU_Properties
    # Example:
    # A FRU would have "FieldReplaceable" set to boolean 1 and should have
    # the following entries
    #  "fru": [
    #    "FieldReplaceable"
    #    "BuildDate",
    #    "Cached"
    #    "SerialNumber",
    #    "Version",
    #    "Model",
    #    "PrettyName",
    #    "PartNumber",
    #    "Present",
    #    "Manufacturer",
    # ]
    # and FRU which doesn't have one of this fields is an error.
    #   "/xyz/openbmc_project/inventory/system/chassis/motherboard/dimm0": {
    #    "FieldReplaceable": 1,
    #    "BuildDate": "",
    #    "Cached": 0,
    #    "SerialNumber": "0x0300cf4f",
    #    "Version": "0x00",
    #    "Model": "M393A1G40EB1-CRC    ",
    #    "PrettyName": "0x0c",
    #    "PartNumber": "",
    #    "Present": 1,
    #    "Manufacturer": "0xce80"
    # },

    ${system_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  *
    ${fru_list}=  Qualified FRU List  @{system_list}
    Validate FRU Properties Fields  @{fru_list}

*** Keywords ***

Test Suite Setup
    [Documentation]  Do the initial suite setup.
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is OS Starting


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


Qualified FRU List
    [Documentation]  Build the list of valid FRU's.
    [Arguments]  @{system_list}
    # Description of arguments:
    # system_list  List of system inventory url's.
    # Example:
    # /xyz/openbmc_project/inventory/system/chassis/motherboard
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm1
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm2
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm3
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm4
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm5
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm6
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm7

    ${fru_list}=  Create List
    :FOR  ${fru_uri}  IN  @{system_list}
    \  ${is_fru}=  OpenBMC Get Request  ${fru_uri}/attr/FieldReplaceable
    \  ${status}=  Run Keyword And Return Status  Should Be True  ${is_fru}
    \  Run Keyword If  '${status}' == '${True}'
    ...  Append To List  ${fru_list}  ${fru_uri}

    [Return]  ${fru_list}


Validate FRU Properties Fields
    [Documentation]  Compare valid FRU's from system vs expected FRU set.
    [Arguments]  @{fru_list}
    # Description of arguments:
    # fru_list  List of qualified FRU url's.

    # Build the pre-define set list from data/inventory.py derived from
    # a group of YAML files.
    # Example:
    # set(['Version', 'PartNumber', 'SerialNumber', 'FieldReplaceable',
    # 'BuildDate', 'Present', 'Manufacturer', 'PrettyName', 'Cached', 'Model'])
    ${fru_set}=  List To Set  ${inventory_dict['fru']}

    # Iterate through the FRU's url and compare the set dictionary keys
    # with the pre-define inventory data.
    :FOR  ${fru_path}  IN  @{fru_list}
    \  ${fru_field}=  Read Properties  ${fru_path}
    # ------------------------------------------------------------
    #  ${fru_field.viewkeys()} extracts the list of keys from the
    #  JSON dictionary as a set.
    # ------------------------------------------------------------
    \  Should Be Equal  ${fru_field.viewkeys()}  ${fru_set}

