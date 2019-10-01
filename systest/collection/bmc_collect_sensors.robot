*** Settings ***
Documentation       BMC server health, collect sensors.

# Test Parameters:
# OPENBMC_HOST      The BMC host name or IP address.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             Collections
Library             ../syslib/utils_keywords.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn

*** Variables ***
${QUIET}                     ${1}
${sensors_values_rest}       Rest sensors collection excluded
${sensors_values_redfish}    Redfish sensors collection excluded
${sensors_flagged_rest}      Rest sensors collection excluded
${sensors_flagged_redfish}   Redfish sensors collection excluded


*** Test Cases ***

Rest Collect Sensors
    [Documentation]  Collect the sensors values using the OpenBMC Rest API.
    [Tags]  Rest_Collect_Sensors  rest
    [Teardown]  FFDC On Test Case Fail  clean_up=${FALSE}

    ${sensors}=  OpenBMC Get Request  ${SENSORS_URI}enumerate
    ${sensors}=  Evaluate  $sensors.json()['data']
    ${sensors_collected_via_rest}=  gen_robot_print.Sprint Vars  sensors
    Log To Console  ${sensors_collected_via_rest}
    ${fans}=  Filter Struct  ${sensors}  [('Unit', '\.RPMS$')]  regex=1
    ${no_fans}=  Filter Struct  ${sensors}  [('WarningAlarmHigh', None),('WarningAlarmLow', None)]
    ...  invert=${True}
    Log  sensor values raw:${\n}${sensors}${\n}sensors no fans:${\n}${no_fans}${\n}fans:${\n}${fans}
    ...  level=DEBUG

    ${fans_flagged}=  Filter Struct  ${fans}
    ...  [('CriticalAlarmHigh', False),('CriticalAlarmLow', False)]  invert=${True}
    ${filter_str}=  Catenate  [('CriticalAlarmHigh', False),('CriticalAlarmLow', False),
    ...  ('WarningAlarmHigh', False),('WarningAlarmLow', False)]
    ${other_sensors_flagged}=  Filter Struct  ${no_fans}  ${filter_str}  invert=${True}
    ${sensors_flagged_rest}=  gen_robot_print.Sprint Vars  fans_flagged  other_sensors_flagged
    Set Suite Variable  ${sensors_flagged_rest}


Redfish Collect Sensors
    [Documentation]  Collect the sensor values using Redfish.
    [Tags]  Redfish_Collect_Sensors  redfish
    [Setup]  Redfish.Login
    [Teardown]  Redfish Test Teardown Execution

    ${redfish_chassis_power}=  Redfish_Utils.Enumerate Request  ${REDFISH_CHASSIS_POWER_URI}  ${0}
    ${redfish_chassis_thermal}=  Redfish_Utils.Enumerate Request  ${REDFISH_CHASSIS_THERMAL_URI}  ${0}
    ${redfish_chassis_sensors}=  Redfish_Utils.Enumerate Request  ${REDFISH_CHASSIS_SENSORS_URI}  ${0}
    ${sensors_values_redfish}=  gen_robot_print.Sprint Vars
    ...  redfish_chassis_power  redfish_chassis_thermal  redfish_chassis_sensors
    Set Suite Variable  ${sensors_values_redfish}
    Log To Console  ${sensors_values_redfish}

    ${health_check_filter_dict}=  Create Dictionary  Health=OK
    ${merged_dicts}=  Evaluate  {**$redfish_chassis_power, **$redfish_chassis_thermal}
    Log  ${merged_dicts}  level=DEBUG
    ${sensors_flagged_redfish}=  Filter Struct  ${merged_dicts}  ${health_check_filter_dict}  invert=${TRUE}
    ${sensors_flagged_redfish}=  gen_robot_print.Sprint Vars  sensors_flagged_redfish
    Set Suite Variable  ${sensors_flagged_redfish}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Set Log Level  DEBUG
    REST Power On  stack_mode=skip


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks. Log sensor values collected.

    Log Many  ${sensors_values_rest}  ${sensors_values_redfish}
    Log  Sensors detected out of bounds via Rest:${\n}${sensors_flagged_rest}  console=true
    Log  Sensors detected out of bounds via Redfish:${\n}${sensors_flagged_redfish}  console=true


Redfish Test Teardown Execution
    [Documentation]  Do the post test teardown for redfish.

    Redfish.Logout
    FFDC On Test Case Fail  clean_up=${FALSE}
