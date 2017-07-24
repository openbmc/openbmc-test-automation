*** Settings ***
Documentation     System inventory related test.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/list_utils.robot
Library           ../lib/utilities.py

Variables         ../data/variables.py
Variables         ../data/inventory.py

Suite setup       Test Suite Setup
Test Teardown     FFDC On Test Case Fail

Force Tags        Inventory

***Variables***

${LOOP_COUNT}  ${1}

*** Test Cases ***

Verify System Inventory Path
    [Documentation]  Check if system inventory path exist.
    [Tags]  Verify_System_Inventory_Path
    # When the host is booted, system inventory path should exist.
    # Example: /xyz/openbmc_project/inventory/system
    Get Inventory  system


Verify Boxelder Present Property
    [Documentation]  Boxelder should be present by default.
    [Tags]  Verify_Boxelder_Present_Property
    # Example:
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/boxelder/bmc":
    # {
    #     "BuildDate": "",
    #     "FieldReplaceable": 0,
    #     "Manufacturer": "IBM",
    #     "Model": "",
    #     "PartNumber": "01DH051",
    #     "Present": 1,
    #     "PrettyName": "BMC PLANAR  ",
    #     "SerialNumber": "000000000000"
    # },
    ${json_data}=  Get Inventory  system/chassis/motherboard/boxelder/bmc
    Should Be True  ${json_data["data"]["Present"]}


Verify Boxelder MAC Address Property Is Populated
    [Documentation]  Boxelder should be present by default.
    [Tags]  Verify_Boxelder_MAC_Address_Property_Is_Populated
    # Example:
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/boxelder/bmc/ethernet
    # {
    #     "FieldReplaceable": 0,
    #     "MACAddress": "00:00:00:00:00:00",
    #     "Present": 1,
    #     "PrettyName": ""
    # }

    ${json_data}=  Get Inventory
    ...  system/chassis/motherboard/boxelder/bmc/ethernet
    Should Be True  ${json_data["data"]["Present"]}
    Should Not Be Equal As Strings
    ...  ${json_data["data"]["MACAddress"]}  00:00:00:00:00:00

    # eth0      Link encap:Ethernet  HWaddr 70:E2:84:14:23:F9
    ${mac_addr}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ifconfig -a | grep HWaddr | awk -F'HWaddr ' '{print $2}'
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Should Be Equal As Strings  ${json_data["data"]["MACAddress"]}  ${mac_addr}
    ...  msg=MAC address configured incorrectly.


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
    [Documentation]  Check if the FRU "Present" is set for CPU's.
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
    [Documentation]  Check if the FRU "Present" is set for DIMM's.
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
    [Documentation]  Verify the FRU properties fields.
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


Verify Core Functional State
    [Documentation]  Verify that "Present" core property is set if "Functional"
    ...              core property is set.
    [Tags]  Verify_Core_Functional_State
    # Example:
    #  "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core5":{
    #    "Functional": 1,
    #    "Present": 1,
    #    "PrettyName": ""
    # },
    ${core_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  core
    :FOR  ${core_uri}  IN  @{core_list}
    \  ${status}=  Run Keyword And Return Status
    ...  Check URL Property If Functional  ${core_uri}
    \  Continue For Loop If  '${status}' == '${False}'
    \  ${present}=  Read Attribute  ${core_uri}  Present
    \  Should Be True  ${present}
    ...  msg=${core_uri} is functional but not present.


Verify DIMM Functional State
    [Documentation]  Verify that "Present" DIMM property is set if "Functional"
    ...              DIMM property is set.
    [Tags]  Verify_DIMM_Functional_State
    # Example:
    #   "/xyz/openbmc_project/inventory/system/chassis/motherboard/dimm0": {
    #    "BuildDate": "",
    #    "Cached": 0,
    #    "FieldReplaceable": 1,
    #    "Functional": 1,
    #    "Manufacturer": "0xce80",
    #    "Model": "M393A1G40EB1-CRC    ",
    #    "PartNumber": "",
    #    "Present": 1,
    #    "PrettyName": "0x0c",
    #    "SerialNumber": "0x0300cf4f",
    #    "Version": "0x00"
    # },

    ${dimm_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  dimm
    :FOR  ${dimm_uri}  IN  @{dimm_list}
    \  ${status}=  Run Keyword And Return Status
    ...  Check URL Property If Functional  ${dimm_uri}
    \  Continue For Loop If  '${status}' == '${False}'
    \  ${present}=  Read Attribute  ${dimm_uri}  Present
    \  Should Be True  ${present}
    ...  msg=${dimm_uri} is functional but not present.


Verify Fan Functional State
    [Documentation]  Verify that "Present" fan property is set if "Functional"
    ...              fan property is set.
    [Tags]  Verify_Fan_Functional_State
    # Example:
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/fan0": {
    #     "Functional": 1,
    #     "Present": 1,
    #     "PrettyName": "fan0"
    # },

    ${fan_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  fan*
    Should Not Be Empty  ${fan_list}
    :FOR  ${fan_uri}  IN  @{fan_list}
    \  ${status}=  Run Keyword And Return Status
    ...  Check URL Property If Functional  ${fan_uri}
    \  Continue For Loop If  '${status}' == '${False}'
    \  ${present}=  Read Attribute  ${fan_uri}  Present
    \  Should Be True  ${present}
    ...  msg=${fan_uri} is functional but "Present" is not set.

Verify Inventory List After Reboot
    [Documentation]  Verify Inventory List After Reboot
    [Tags]  Verify_Inventory_List_After_Reboot

    Repeat Keyword  ${LOOP_COUNT} times  Verify Inventory List Before And After Reboot

Check Air Or Water Cooled
    [Documentation]  Check if this system is Air or water cooled.
    [Tags]  Check_Air_Or_Water_Cooled
    # Example:
    # "/xyz/openbmc_project/inventory/system/chassis": {
    #    "AirCooled": 1,
    #    "WaterCooled": 0
    # },

    ${air_cooled}=  Read Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis  AirCooled
    Log  AirCooled:${air_cooled}

    ${water_cooled}=  Read Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis  WaterCooled
    Log  WaterCooled:${water_cooled}

    Run Keyword If  ${air_cooled}==${0} and ${water_cooled}==${0}
    ...  Fail  Neither AirCooled or WaterCooled.


*** Keywords ***

Test Suite Setup
    [Documentation]  Do the initial suite setup.

    # Reboot host to re-power on clean if host is not "off".
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot
    ...  ELSE  Initiate Host Reboot

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
    [Documentation]  Build the list of valid FRUs.
    [Arguments]  @{system_list}
    # Description of arguments:
    # system_list  List of system inventory URLs.
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
    \  ${resp}=  OpenBMC Get Request  ${fru_uri}/attr/FieldReplaceable
    \  ${jsondata}=  To JSON  ${resp.content}
    \  ${status}=  Run Keyword And Return Status
    ...  Should Be True  ${jsondata['data']} == ${1}
    \  Run Keyword If  '${status}' == '${True}'
    ...  Append To List  ${fru_list}  ${fru_uri}

    [Return]  ${fru_list}


Validate FRU Properties Fields
    [Documentation]  Compare valid FRUs from system vs expected FRU set.
    [Arguments]  @{fru_list}
    # Description of arguments:
    # fru_list  List of qualified FRU URLs.

    # Build the pre-defined set list from data/inventory.py derived from
    # a group of YAML files.
    # Example:
    # set(['Version', 'PartNumber', 'SerialNumber', 'FieldReplaceable',
    # 'BuildDate', 'Present', 'Manufacturer', 'PrettyName', 'Cached', 'Model'])
    ${fru_set}=  List To Set  ${inventory_dict['fru']}

    # Iterate through the FRU's url and compare the set dictionary keys
    # with the pre-define inventory data.
    :FOR  ${fru_url_path}  IN  @{fru_list}
    \  ${fru_field}=  Read Properties  ${fru_url_path}
    # ------------------------------------------------------------
    #  ${fru_field.viewkeys()} extracts the list of keys from the
    #  JSON dictionary as a set.
    # ------------------------------------------------------------
    \  Should Be Equal  ${fru_field.viewkeys()}  ${fru_set}


Check URL Property If Functional
    [Arguments]  ${url_path}
    # Description of arguments:
    # url_path  Full url path of the inventory object.
    #           Example: DIMM / core property url's
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/dimm0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core0
    ${state}=  Read Attribute  ${url_path}  Functional
    Should Be True  ${state}

Verify Inventory List Before And After Reboot
    [Documentation]  Verify Inventory list before and after reboot.

    Initiate Host Boot
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Starting
    ${inv_before}=  Get URL List  ${HOST_INVENTORY_URI}
    Initiate Host Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Starting
    ${inv_after}=  Get URL List  ${HOST_INVENTORY_URI}
    Lists Should Be Equal  ${inv_before}  ${inv_after}
