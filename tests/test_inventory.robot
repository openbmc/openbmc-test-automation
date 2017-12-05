*** Settings ***
Documentation     System inventory related test.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/state_manager.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/list_utils.robot
Resource          ../lib/boot_utils.robot
Library           ../lib/utilities.py

Variables         ../data/variables.py
Variables         ../data/inventory.py

Suite Setup       Suite Setup Execution
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
    Should Not Be Equal As Strings
    ...  ${json_data["data"]["SerialNumber"]}  000000000000
    ...  msg=BMC planar serial number invalid.


Verify UUID Entry
    [Documentation]  UUID entry should exist in BMC planar property.
    [Tags]  Verify_UUID_Entry
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
    #     "UUID": ""
    # },
    ${json_data}=  Get Inventory  system/chassis/motherboard/boxelder/bmc
    Should Not Be Empty  ${json_data["data"]["UUID"]}


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
    Should Be Equal As Strings  ${json_data["data"]["MACAddress"]}
    ...  ${mac_addr.strip()}  msg=MAC address configured incorrectly.
    ...  ignore_case=True


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
    Validate FRU Properties Fields  fru  @{fru_list}


Verify GPU Properties
    [Documentation]  Verify the gpu properties fields.
    [Tags]  Verify_GPU_Properties
    # Example:

    ${system_list}=  Get Endpoint Paths
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard  gv*
    Validate FRU Properties Fields  gpu  @{system_list}


Verify Core Properties
    [Documentation]  Verify the cores properties fields.
    [Tags]  Verify_Core_Properties
    # Example:

    ${system_list}=  Get Endpoint Paths
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard  core*
    Validate FRU Properties Fields  core  @{system_list}



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

Verify CPU Functional State
    [Documentation]  Verify that "Present" CPU property is set if "Functional"
    ...              CPU property is set.
    [Tags]  Verify_CPU_Functional_State

    # Example of cpu* endpoint data:
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0": {
    #     "Functional": 1,
    #     "Present": 1,
    #     "PrettyName": "cpu0"
    # },

    ${cpu_list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  cpu*
    Should Not Be Empty  ${cpu_list}
    :FOR  ${cpu_uri}  IN  @{cpu_list}
    \  ${status}=  Run Keyword And Return Status
    ...  Check URL Property If Functional  ${cpu_uri}
    \  Continue For Loop If  '${status}' == '${False}'
    \  ${present}=  Read Attribute  ${cpu_uri}  Present
    \  Should Be True  ${present}
    ...  msg=${cpu_uri} is functional but "Present" is not set.


Verify GPU Functional State
    [Documentation]  Verify that "Functional" GPU property is set if "Present"
    ...              GPU property is set
    [Tags]  Verify_GPU_Functional_State

    # Example of gv* endpoint data:
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/gv100card4": {
    #     "Functional": 1,
    #     "Present": 1,
    #     "PrettyName": ""
    # },


    ${gpu_list}=  Get Endpoint Paths
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard  gv*
    Should Not Be Empty  ${gpu_list}
    :FOR  ${gpu_uri}  IN  @{gpu_list}
    \  ${status}=  Run Keyword And Return Status
    ...  Check URL Property If Functional  ${gpu_uri}
    \  Continue For Loop If  '${status}' == '${False}'
    \  ${present}=  Read Attribute  ${gpu_uri}  Present
    \  Should Be True  ${present}
    ...  msg=${gpu_uri} is functional but "Present" is not set.


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

Verify Minimal CPU Inventory
    [Documentation]  Verify minimal CPU inventory.
    [Tags]  Verify_Minimal_CPU_Inventory

    # item         minimum_count
    cpu            1
    [Template]     Minimum Inventory

Verify Minimal DIMM Inventory
    [Documentation]  Verify minimal DIMM inventory.
    [Tags]  Verify_Minimal_DIMM_Inventory

    # item         minimum_count
    dimm           2
    [Template]     Minimum Inventory

Verify Minimal Core Inventory
    [Documentation]  Verify minimal core inventory.
    [Tags]  Verify_Minimal_Core_Inventory

    # item         minimum_count
    core           1
    [Template]     Minimum Inventory

Verify Minimal Memory Buffer Inventory
    [Documentation]  Verify minimal memory buffer inventory.
    [Tags]  Verify_Minimal_Memory_Buffer_Inventory

    # item         minimum_count
    memory_buffer  1
    [Template]     Minimum Inventory

Verify Minimal Fan Inventory
    [Documentation]  Verify minimal fan inventory.
    [Tags]  Verify_Minimal_Fan_Inventory

    # item         minimum_count
    fan            2
    [Template]     Minimum Inventory

Verify Minimal Main Planar Inventory
    [Documentation]  Verify minimal main planar inventory.
    [Tags]  Verify_Minimal_Main_Planar_Inventory

    # item         minimum_count
    main_planar    1
    [Template]     Minimum Inventory

Verify Minimal System Inventory
    [Documentation]  Verify minimal system inventory.
    [Tags]  Verify_Minimal_System_Inventory

    # item         minimum_count
    system         1
    [Template]     Minimum Inventory

Verify Minimal Power Supply Inventory
    [Documentation]  Verify minimal power supply inventory.
    [Tags]  Verify_Minimal_Power_Supply_Inventory
    # Example:
    # "/xyz/openbmc_project/inventory/system/chassis/powersupply0",
    # "/xyz/openbmc_project/inventory/system/chassis/powersupply1",

    # item         minimum_count
    powersupply    1
    [Template]     Minimum Inventory


Verify Inventory List After Reboot
    [Documentation]  Verify inventory list after reboot.
    [Tags]  Verify_Inventory_List_After_Reboot

    Repeat Keyword  ${LOOP_COUNT} times  Choose Boot Option  reboot


Verify Inventory List After Reset
    [Documentation]  Verify inventory list after reset.
    [Tags]  Verify_Inventory_List_After_Reset

    Repeat Keyword  ${LOOP_COUNT} times  Choose Boot Option  reset

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the initial suite setup.

    # Boot Host.
    REST Power On  stack_mode=skip  quiet=1

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
    ...  quiet=${1}
    \  ${jsondata}=  To JSON  ${resp.content}
    \  ${status}=  Run Keyword And Return Status
    ...  Should Be True  ${jsondata['data']} == ${1}
    \  Run Keyword If  '${status}' == '${True}'
    ...  Append To List  ${fru_list}  ${fru_uri}

    [Return]  ${fru_list}


Validate FRU Properties Fields
    [Documentation]  Compare valid FRUs from system vs expected FRU set.
    [Arguments]  ${type}  @{fru_list}
    # Description of arguments:
    # fru_list  List of qualified FRU URLs.

    # Build the pre-defined set list from data/inventory.py derived from
    # a group of YAML files.
    # Example:
    # set(['Version', 'PartNumber', 'SerialNumber', 'FieldReplaceable',
    # 'BuildDate', 'Present', 'Manufacturer', 'PrettyName', 'Cached', 'Model'])
    ${fru_set}=  List To Set  ${inventory_dict['${type}']}

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

Choose Boot Option
    [Documentation]  Choose BMC reset or host reboot.
    [Arguments]  ${option}

    Run Keyword If  '${option}' == 'reboot'
    ...    Verify Inventory List Before And After Reboot
    ...  ELSE
    ...    Verify Inventory List Before And After Reset


Verify Inventory List Before And After Reboot
    [Documentation]  Verify inventory list before and after reboot.

    REST Power On  stack_mode=skip  quiet=1
    Delete Error Logs
    ${inventory_before}=  Get URL List  ${HOST_INVENTORY_URI}
    Initiate Host Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Booted
    Delete Error Logs
    ${inventory_after}=  Get URL List  ${HOST_INVENTORY_URI}
    Lists Should Be Equal  ${inventory_before}  ${inventory_after}


Verify Inventory List Before And After Reset
    [Documentation]  Verify inventory list before and after BMC reset.

    REST Power On  stack_mode=skip  quiet=1
    Delete Error Logs
    ${inventory_before}=  Get URL List  ${HOST_INVENTORY_URI}
    OBMC Reboot (run)
    Delete Error Logs
    ${inventory_after}=  Get URL List  ${HOST_INVENTORY_URI}
    Lists Should Be Equal  ${inventory_before}  ${inventory_after}


Minimum Inventory
    [Documentation]  Check for minimum inventory.
    [Arguments]  ${item}  ${minimum_count}

    # Description of argument(s):
    # item  Inventory name (example: "fan/cpu/dimm/etc").
    # minimum_count  The minimum number of the given item.

    ${count}=  Get Number Hardware Items  ${item}
    Should Be True  ${count}>=${minimum_count}

Get Number Hardware Items
    [Documentation]  Get the count of the total present currently on inventory.
    [Arguments]  ${item}

    # Description of argument(s):
    # item  Inventory name (example: "fan/cpu/dimm/etc").

    ${count_inventory}  Set Variable  ${0}
    ${list}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}/system/
    ...  ${item}

    : FOR  ${element}  IN  @{list}
    \  ${present}=  Read Properties  ${element}
    \  ${count_inventory}=  Set Variable if  ${present['Present']} == 1
    \  ...  ${count_inventory+1}  ${count_inventory}
    [return]  ${count_inventory}
