*** Settings ***
Documentation       BMC collect VPD and hardware status.

# Test Parameters:
# OPENBMC_HOST      The BMC host name or IP address.

Resource            ../lib/bmc_redfish_resource.robot
Resource            ../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Test Setup          Printn

*** Variables ***
${QUIET}  ${1}

*** Test Cases ***

Collect VPD And Hardware Status
    [Documentation]  Collect VPD and hardware status using Redfish.
    [Tags]  collect_vpd
    [Setup]  Redfish.Login
    [Teardown]  Redfish Test Teardown Execution

    ${system_properties}=  Redfish_Utils.Get Properties  ${SYSTEM_BASE_URI}
    ${system_memory_info}=  Redfish_Utils.Enumerate Request  ${SYSTEM_BASE_URI}/Memory
    ${system_processors_info}=  Redfish_Utils.Enumerate Request  ${SYSTEM_BASE_URI}/Processors
    ${system_fans_info}=  Redfish_Utils.Get Attribute  ${REDFISH_CHASSIS_THERMAL_URI}  Fans
    ${collected_values}=  gen_robot_print.Sprint Vars
    ...  system_properties  system_memory_info  system_processors_info  system_fans_info
    Log To Console  ${\n}${collected_values}${\n}

Run VPD Tool
    [Documentation]  Run vpd-tool -i.
    [Tags]  run_vpd_tool

    BMC Execute Command  vpd-tool -i  print_out=${1}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Set Log Level  DEBUG
    Log To Console  ${OPENBMC_HOST}


Redfish Test Teardown Execution
    [Documentation]  Do the post test teardown for redfish.

    Redfish.Logout
    FFDC On Test Case Fail  clean_up=${FALSE}
