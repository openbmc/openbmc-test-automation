*** Settings ***

Documentation  Verify that both the air and water cooled systems are
...  operating in the desired ranges for Fans, Power and Temperature
...  during Idle and stress up at the OS.


# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_USERNAME            The BMC user name.
#   OPENBMC_PASSWORD            The BMC password.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS Host password.
#
#   The parameters below should be comma-seperated lists
#   (e.g [500,800]):
#      FAN_RANGE_IDLE           The desired range for fans during idle
#                               state.
#      FAN_RANGE_STRESS         The desired range for fans during
#                               stress state.
#      TEMPRATURE_RANGE_IDLE    The desired range for temperature
#                               during idle state.
#      TEMPERATURE_RANGE_STRESS The desired range for temperature
#                               during stress state.
#      POWER_RANGE_IDLE         The desired range for power during idle
#                               state.
#      POWER_RANGE_STRESS       The desired range for power during
#                               stress state.
#      HTX_DURATION             Duration of the HTX run (e.g 1h, 20m).
#      HTX_INTERVAL             The delay between consecutive checks for
#                               temperature, fan and power ranges.
#      HTX_MDT_PROFILE          The MDT Profile to run.


Resource           ../syslib/utils_os.robot
Resource           ../lib/fan_utils.robot
Test Teardown      FFDC On Test Case Fail
Suite Teardown     Shutdown HTX Exerciser

*** Variables ***


*** Test Cases ***

Verify Ranges During Idle State
    [Documentation]  Verify ranges while the system is idle.
    [Tags]  Verify_Ranges_During_Idle_State

    # System needs to be Idle at the beginning of the test.
    Check Fan Speeds  ${FAN_RANGE_IDLE}
    Check Temperature Values  ${TEMPRATURE_RANGE_IDLE}
    Check Power Values  ${POWER_RANGE_IDLE}


Verify Ranges During Stress
    [Documentation]  Verify ranges while the OS is at stress up.
    [Tags]  Verify_Ranges_During_Stress

    # Run HTX and verify, within intervals, that the hardware ranges
    # are within the desired ranges.
    Run MDT Profile
    Repeat Keyword  ${HTX_DURATION}  Run Keywords
    ...  Check Fan Speeds  ${FAN_RANGE_STRESS}
    ...  AND  Check Temperature Values  ${TEMPRATURE_RANGE_STRESS}
    ...  AND  Check Power Values  ${POWER_RANGE_STRESS}
    ...  AND  Sleep  ${HTX_INTERVAL}


*** Keywords ***

Verify Range
    [Documentation]  Verify that the sensor values are within the
    ...  required range. Fail if not.
    [Arguments]  ${value}  ${required_range}  ${sensor_type}
    # Description of argument(s):
    # required_range            The required range for the value to be
    #                           within. Fails if the value is not
    #                           within the interval.
    # value                     The value to be used for interval
    #                           comparison.
    # sensor_type               The name of the sensor being checked
    #                           (e.g power, temperature or fan).

    # Fail unless the value is within the range.
    Run Keyword Unless
    ...  ${required_range[0]} <= ${value} <= ${required_range[1]}  FAIL
    ...  msg=the ${sensor_type} value is not within the required range.


Check Fan Speeds
    [Documentation]  Verify that the fan speeds is within the required
    ...  range.
    [Arguments]  ${required_range}
    # Description of argument(s):
    # required_range            The required range for the fan speeds.
    #                           (e.g [500,800]).

    # Get the fans with the lowest and highest fan speeds. Verify that
    # the speeds are within the proper range.
    ${fan_speeds}=  Read Properties  ${SENSORS_URI}fan_tach/enumerate
    ${fan_speeds_list}=  Evaluate
    ...  [ x['Value'] for x in $fan_speeds.values() ]
    ${max_fan_speed}  Evaluate  max(map(int, $fan_speeds_list))
    ${min_fan_speed}  Evaluate  min(map(int, $fan_speeds_list))
    Verify Range  ${max_fan_speed}  ${required_range}  fan
    Verify Range  ${min_fan_speed}  ${required_range}  fan


Check Temperature Values
    [Documentation]  Verify that the temperature is within the required
    ...  range.
    [Arguments]  ${required_range}
    # Description of argument(s):
    # required_range            The required range for the temperature
    #                           values (e.g [20,60]).

    # Get the lowest and highest temperatures for GPUs, verify
    # that it is within the proper range.
    # nvidia-smi --query-gpu=temperature.gpu --format=csv | tail -n 3
    # returns:
    # 34
    # 38
    # 37
    ${gpu_temps}  ${stderr}  ${rc}=  OS Execute Command
    ...  nvidia-smi --query-gpu=temperature.gpu --format=csv | tail -n 3
    ${gpu_temps}=  Split String  ${gpu_temps}
    ${gpu_max}=  Evaluate  max(${gpu_temps})
    ${gpu_min}=  Evaluate  min(${gpu_temps})
    Verify Range  ${gpu_max}  ${required_range}  temperature
    Verify Range  ${gpu_min}  ${required_range}  temperature
    # Verify for CPUs.
    ${cpu_highest_temp}=  Get CPU Highest Temperature
    ${cpu_lowest_temp}=  Get CPU Lowest Temperature
    Verify Range  ${cpu_highest_temp}  ${required_range}  temperature
    Verify Range  ${cpu_lowest_temp}  ${required_range}  temperature


Check Power Values
    [Documentation]  Verify that the power values for GPUs and CPUs
    ...  are within the required range.
    [Arguments]  ${required_range}
    # Description of argument(s):
    # required_range            The required range for power values
    #                           (e.g [15,30]).

    ${cmd}=  Catenate  nvidia-smi  --query-gpu=power.draw
    ...  --format=csv | cut -f 1 -d ' ' | tail -n +2
    ${powers}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    ${powers}=  Split String  ${powers}
    ${gpu_power_list}=  Evaluate  map(int,map(float,${powers}))
    ${p0}=  Read Properties  ${SENSORS_URI}power/p0_power
    ${p1}=  Read Properties  ${SENSORS_URI}power/p1_power
    # The scaling factor for fans is -6.
    ${p0_value}=  Evaluate  ${p0}['Value']/1000000
    ${p1_value}=  Evaluate  ${p1}['Value']/1000000
    Verify Range  ${p0_value}  ${required_range}  power
    Verify Range  ${p1_value}  ${required_range}  power