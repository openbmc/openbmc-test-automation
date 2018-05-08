*** Settings ***

Documentation  Verify that both the air and water cooled systems are
...  operating in the allowable ranges for fans, power and temperature
...  during idle and stress up at the OS.


# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_USERNAME            The BMC user name.
#   OPENBMC_PASSWORD            The BMC password.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS Host password.
#   HTX_DURATION                Duration of the HTX run (e.g 1h, 20m).
#   HTX_INTERVAL                The time delay between consecutive
#                               checks for temperature, fan and power
#                               ranges.
#   HTX_MDT_PROFILE             The MDT Profile to run.
#
#   The parameters below should be comma-separated lists,
#   (e.g "500,800"). See default ranges below.
#   These ranges can vary based on the type of system under test.
#
#      FAN_SPEED_RANGE_IDLE     The allowable range of fan speeds,
#                               expressed as RPMs, when the machine is
#                               at an idle state.
#      FAN_SPEED_RANGE_STRESS   The allowable range of fan speeds,
#                               expressed as RPMs, when the machine is
#                               at a stressed state.
#      TEMPERATURE_RANGE_IDLE   The allowed range for temperature,
#                               expressed as Celsius degrees, when
#                               the machine is at an idle state.
#      TEMPERATURE_RANGE_STRESS The allowable range for temperature,
#                               expressed as Celsius degrees, when
#                               the machine is at a stressed state.
#      POWER_RANGE_IDLE         The allowable range for power, expressed
#                               in Watts, while the machine is at an
#                               idle state.
#      POWER_RANGE_STRESS       The allowable range for power, expressed
#                               in Watts, while the machine is at a
#                               stressed state.


Resource           ../syslib/utils_os.robot
Resource           ../lib/fan_utils.robot
Library            ../lib/gen_robot_valid.py
Suite Setup         Suite Setup Execution
Test Teardown      FFDC On Test Case Fail
Suite Teardown     Shutdown HTX Exerciser

*** Variables ***
# Default Ranges.
@{FAN_SPEED_RANGE_IDLE}=        0  6000
@{FAN_SPEED_RANGE_STRESS}=      3000  8000
@{TEMPERATURE_RANGE_IDLE}=      30  45
@{TEMPERATURE_RANGE_STRESS}=    35  100
@{POWER_RANGE_IDLE}=            15  60
@{POWER_RANGE_STRESS}=          30  350


*** Test Cases ***

Verify Fan Speeds During Idle State
    [Documentation]  Verify the fan speeds are within acceptable range
    ...  while the system is idle.
    [Tags]  Verify_Fan_Speeds_During_Idle_State

    Verify Fan Speeds  ${FAN_SPEED_RANGE_IDLE}


Verify Temperature During Idle State
    [Documentation]  Verify the temperature values are within acceptable
    ...  range while the system is idle.
    [Tags]  Verify_Temperature_During_Idle_State

    Verify Temperatures  ${TEMPERATURE_RANGE_IDLE}


Verify Power During Idle State
    [Documentation]  Verify the power values are within acceptable range
    ...  while the system is idle.
    [Tags]  Verify_Power_During_Idle_State

    Verify Power Values  ${POWER_RANGE_IDLE}


Test Hardware Limits During Stress
    [Documentation]  Verify the hardware under stress is within
    ...  acceptable range.
    [Tags]  Test_Hardware_Limits_During_Stress

    # Run HTX and verify, within intervals, that the hardware ranges
    # are within the allowable ranges.
    Run MDT Profile
    Repeat Keyword  ${HTX_DURATION}  Run Keywords
    ...  Verify Fan Speeds  ${FAN_SPEED_RANGE_STRESS}
    ...  AND  Verify Temperatures  ${TEMPERATURE_RANGE_STRESS}
    ...  AND  Verify Power Values  ${POWER_RANGE_STRESS}
    ...  AND  Run Key  Sleep \ ${HTX_INTERVAL}


*** Keywords ***

Verify Fan Speeds
    [Documentation]  Verify that the fan speeds are within the required
    ...  range.
    [Arguments]  ${range}

    # Description of argument(s):
    # range                     A 2-element list comprised of the lower
    #                           and upper values which constitute the
    #                           valid range for the fan speeds.
    #                           (e.g [500,800]).

    # Get the fans with the lowest and highest fan speeds. Verify that
    # the speeds are within the proper range.
    ${fan_objects}=  Read Properties  ${SENSORS_URI}fan_tach/enumerate
    ${fan_speeds}=  Evaluate
    ...  [ x['Value'] for x in $fan_objects.values() ]
    ${max_fan_speed}  Evaluate  max(map(int, $fan_speeds))
    ${min_fan_speed}  Evaluate  min(map(int, $fan_speeds))
    Rvalid Range  max_fan_speed  ${range}
    Rvalid Range  min_fan_speed  ${range}


Verify Temperatures
    [Documentation]  Verify that the temperature values are within the
    ...  required range.
    [Arguments]  ${range}

    # Description of argument(s):
    # range                     The allowable range for the temperature,
    #                           values (e.g [20,60]).

    # Get the lowest and highest temperatures for GPUs, verify
    # that it is within the proper range.
    ${gpu_max_temperature}=  Get GPU Max Temperature
    ${gpu_min_temperature}=  Get GPU Min Temperature
    Rvalid Range  gpu_max_temperature  ${range}
    Rvalid Range  gpu_min_temperature  ${range}
    # Verify for CPUs.
    ${cpu_highest_temp}=  Get CPU Max Temperature
    ${cpu_lowest_temp}=  Get CPU Min Temperature
    Rvalid Range  cpu_highest_temp  ${range}
    Rvalid Range  cpu_lowest_temp  ${range}


Verify Power Values
    [Documentation]  Verify that the power values for GPUs and CPUs
    ...  are within the required range.
    [Arguments]  ${range}

    # Description of argument(s):
    # range                     The allowable range for power values,
    #                           (e.g [15,30]).

    ${gpu_max}=  Get GPU Max Power
    ${gpu_min}=  Get GPU Min Power
    ${gpu_max_power}=  Evaluate  int(round(${gpu_max}))
    ${gpu_min_power}=  Evaluate  int(round(${gpu_min}))
    Rvalid Range  gpu_max_power  ${range}
    Rvalid Range  gpu_min_power  ${range}

    ${p0}=  Read Properties  ${SENSORS_URI}power/p0_power
    ${p1}=  Read Properties  ${SENSORS_URI}power/p1_power
    # The scaling factor for fans is -6 for CPU power values.
    ${p0_value}=  Evaluate  ${p0}['Value']/1000000
    ${p1_value}=  Evaluate  ${p1}['Value']/1000000
    Rvalid Range  p0_value  ${range}
    Rvalid Range  p1_value  ${range}


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    REST Power On  stack_mode=skip
    ${htx_running}=  Is HTX Running
    Should Not Be True  ${htx_running}  msg=HTX needs to be shutdown.