*** Settings ***
Documentation       BMC server health, collect VPD and hardware status.

# Test Parameters:
# OPENBMC_HOST      The BMC host name or IP address.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn

*** Variables ***
${QUIET}  ${1}
${rest_collected_values}  Rest collection excluded
${redfish_collected_values}  Redfish collection excluded

*** Test Cases ***

Rest Collect VPD And Hardware Status
    [Documentation]  Collect VPD and hardware status using the OpenBMC Rest API.
    [Tags]  Rest_Collect_VPD_And_Hardware_Status  rest
    [Teardown]  FFDC On Test Case Fail  clean_up=${FALSE}

    ${system_properties}=  OpenBMC Get Request  ${HOST_INVENTORY_URI}system
    ${system_properties}=  Evaluate  $system_properties.json()
    ${Type}=  Read Attribute  ${CHASSIS_INVENTORY_URI}  Type
    ${WaterCooled}=  Read Attribute  ${CHASSIS_INVENTORY_URI}  WaterCooled
    ${AirCooled}=  Read Attribute  ${CHASSIS_INVENTORY_URI}  AirCooled
    ${system_chassis}=  OpenBMC Get Request  ${MOTHERBOARD_INVENTORY_URI}enumerate
    ${system_chassis}=  Evaluate  $system_chassis.json()
    Rprint Vars  system_properties  Type  WaterCooled  AirCooled  system_chassis
    ${rest_collected_values}=  gen_robot_print.Sprint Vars
    ...  system_properties  Type  WaterCooled  AirCooled  system_chassis
    Set Global Variable  ${rest_collected_values}


Redfish Collect VPD And Hardware Status
    [Documentation]  Collect VPD and hardware status using Redfish.
    [Tags]  Redfish_Collect_VPD_And_Hardware_Status  redfish
    [Setup]  Redfish.Login
    [Teardown]  Redfish Test Teardown Execution

    ${system_properties}=  Redfish_Utils.Get Properties  ${SYSTEM_BASE_URI}
    ${system_memory_info}=  Redfish_Utils.Enumerate Request  ${SYSTEM_BASE_URI}/Memory
    ${system_processors_info}=  Redfish_Utils.Enumerate Request  ${SYSTEM_BASE_URI}/Processors
    ${system_fans_info}=  Redfish_Utils.Get Attribute  ${REDFISH_CHASSIS_THERMAL_URI}  Fans
    Rprint Vars  system_properties  system_memory_info  system_processors_info  system_fans_info
    ${redfish_collected_values}=  gen_robot_print.Sprint Vars
    ...  system_properties  system_memory_info  system_processors_info  system_fans_info
    Set Global Variable  ${redfish_collected_values}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Set Log Level  DEBUG
    REST Power On  stack_mode=skip


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks. Log values and data collected.

    Log  Rest collected values:${\n}${rest_collected_values}
    Log  Redfish collected values:${\n}${redfish_collected_values}


Redfish Test Teardown Execution
    [Documentation]  Do the post test teardown for redfish.

    Redfish.Logout
    FFDC On Test Case Fail  clean_up=${FALSE}
