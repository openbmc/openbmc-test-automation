*** Settings ***
Documentation  Utilities for fan tests.

Library        ../lib/bmc_ssh_utils.py
Resource       ../lib/state_manager.robot
Resource       ../lib/openbmc_ffdc_utils.robot
Variables      ../data/variables.py

*** Variables ***

# Fan state values.
${fan_functional}      ${1}
${fan_nonfunctional}   ${0}

# Criteria for a fan at maximum speed.
${max_speed}=  ${10400}


*** Keywords ***

Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis  WaterCooled
    [Return]  ${water_cooled}


Get Fan Names
    [Documentation]  Get the names of the fans marked present in inventory.
    [Arguments]  ${fan_names}
    # This keyword populates the fan_names list with the names of
    # fans present in inventory e.g. fan0, fan2, fan3.

    # Description of Argument(s):
    # fan_names   The list of fan names to which new fan names are to be
    #             added to.  This list is returned to the caller.

    ${fan_uris}=  Get Endpoint Paths  ${HOST_INVENTORY_URI}system  fan
    FOR  ${fan_uri}  IN  @{fan_uris}
        ${fan_properties}=  Read Properties  ${fan_uri}
        ${fan_present}=  Get Variable Value  ${fan_properties['Present']}  0
        ${fan_functional}=  Get Variable Value
        ...  ${fan_properties['Functional']}  0
        Continue For Loop If  ${fan_present} == 0 or ${fan_functional} == 0
        ${remaining_uri}  ${fan_name}=  Split Path  ${fan_uri}
        Append To List  ${fan_names}  ${fan_name}
    END

    [Return]  ${fan_names}


Verify System Error Indication Due To Fans
    [Documentation]  Verify enclosure LEDs are on and there's an error log.

    # Both enclosure LEDs should now be On.
    Verify Front And Rear LED State  On

    # An error log should now exist.
    Error Logs Should Exist


Verify Front And Rear LED State
    [Documentation]  Check state of the front and rear enclsure fault LEDs.
    [Arguments]  ${state}
    # Both LEDs should be in the specified state.  If not fail the test case.

    # Description of Argument(s):
    # state    The state to check for, either 'Off' or 'On'.

    ${front_fault}=  Get System LED State  front_fault
    ${rear_fault}=  Get System LED State  rear_fault

    Run Keyword If
    ...  '${front_fault}' != '${state}' or '${rear_fault}' != '${state}'
    ...  Fail  msg=Expecting both enclosure LEDs to be ${state}.


Set Fan State
    [Documentation]  Set the fan state, either functional or non-functional.
    [Arguments]  ${fan_name}  ${fan_state}

    # Description of Argument(s):
    # fan_name     The name of the fan, e.g. "fan2".
    # fan_state    The state to set, 1 for functional, 2 for non-functional.

    ${valueDict}=  Create Dictionary  data=${fan_state}
    Write Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${fan_name}
    ...  Functional  data=${valueDict}


Set Fan Target Speed
    [Documentation]  Set the target speed of a fan.
    [Arguments]  ${fan_name}  ${fan_speed}

    # Description of argument(s):
    # fan_name    The name of the fan (e.g. "fan0").
    # fan_speed   The target speed to set (e.g. "9000").

    ${valueDict}=  Create Dictionary  data=${fan_speed}
    Write Attribute  ${SENSORS_URI}fan_tach/${fan_name}_0
    ...  Target  data=${valueDict}


Get Target Speed Of Fans
    [Documentation]  Return the maximum target speed of the system fans.

    ${max_target}=  Set Variable  0
    ${paths}=  Get Endpoint Paths  ${SENSORS_URI}fan_tach/  0
    FOR  ${path}  IN  @{paths}
        ${response}=  OpenBMC Get Request  ${path}
        ${json}=  To JSON  ${response.content}
        ${target_speed}=  Set Variable  ${json["data"]["Target"]}
        ${max_target}=  Run Keyword If  ${target_speed} > ${max_target}
        ...  Set Variable  ${target_speed}  ELSE  Set Variable  ${max_target}
    END
    [Return]  ${max_target}


Get Target And Blade Speeds
    [Documentation]  Return the fan target speed setting, the speed of the
    ...  fan's clockwise blade, and the speed of the counter-clockwise blade.
    # Each fan unit has two counter-rotating fan blades
    # One blade is expected to be moving but the other blade may not be
    # moving whenever the fan unit is transitioning to a new target speed.
    [Arguments]  ${fan_name}

    # Description of argument(s):
    # fan_name       The name of a fan (e.g. "fan0")

    # Get the fan target speed and the clockwise blade speed.
    ${path}=  Catenate  ${SENSORS_URI}fan_tach/${fan_name}_0
    ${response}=  OpenBMC Get Request  ${path}
    ${json}=  To JSON  ${response.content}
    ${fan_clockwise_speed}=  Set Variable  ${json["data"]["Value"]}
    ${target_speed}=  Set Variable  ${json["data"]["Target"]}

    # Get the counter-clockwise blade speed.
    ${path}=  Catenate  ${SENSORS_URI}fan_tach/${fan_name}_1
    ${response}=  OpenBMC Get Request  ${path}
    ${json}=  To JSON  ${response.content}
    ${fan_counterclockwise_speed}=  Set Variable  ${json["data"]["Value"]}

    [Return]  ${target_speed}  ${fan_clockwise_speed}
    ...  ${fan_counterclockwise_speed}


Get Fan Target And Speed
    [Documentation]  Return the fan target speed setting and the
    ...  speed of the fastest blade.
    [Arguments]  ${fan_name}

    # Description of argument(s):
    # fan_name       The name of a fan (e.g. "fan0")

    ${target_speed}  ${clockwise_speed}  ${counterclockwise_speed}=
    ...  Get Target And Blade Speeds  ${fan_name}
    ${blade_speed}=  Run Keyword If
    ...  ${clockwise_speed} > ${counterclockwise_speed}
    ...  Set Variable  ${clockwise_speed}  ELSE
    ...  Set Variable  ${counterclockwise_speed}
    [Return]  ${target_speed}  ${blade_speed}


Set Fan Daemon State
    [Documentation]  Set the state of the fan control service.
    [Arguments]  ${state}

    # Description of argument(s):
    # state     The desired state of the service, usually
    #           "start", "stop", or "restart".

    ${cmd}=  Catenate  systemctl  ${state}  phosphor-fan-control@0.service
    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}


Verify Minimum Number Of Fans With Cooling Type
    [Documentation]  Verify minimum number of fans.
    [Arguments]  ${num_fans}  ${water_cooled}

    # Description of argument(s):
    # num_fans       The number of fans present in the system.
    # water_cooled   The value 1 if the system is water cooled,
    #                0 if air cooled.

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    Printn
    Rpvars  num_fans  water_cooled

    # If water cooled must have at least min_fans_water fans, otherwise
    # issue Fatal Error and terminate testing.
    Run Keyword If  ${water_cooled} == 1 and ${num_fans} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword If  ${water_cooled} == 0 and ${num_fans} < ${min_fans_air}
    ...  Fatal Error
    ...  msg=Air cooled but less than ${min_fans_air} fans present.


Verify Fan Monitors With State
    [Documentation]  Verify fan monitor daemons in the system state.
    [Arguments]  ${power_state}
    # The number of monitoring daemons is dependent upon the system
    # power state.  If power is off there should be 0, if power
    # is on there should be several.

    # Description of argument(s):
    # power_state   Power staet of the system, either "On" or "Off"

    ${cmd}=  Catenate  systemctl list-units | grep phosphor-fan | wc -l
    ${num_fan_daemons}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}

    Rpvars  power_state  num_fan_daemons

    # Fail if system is On and there are no fan monitors.
    Run Keyword If  '${power_state}' == 'On' and ${num_fan_daemons} == 0
    ...  Fail  msg=No phosphor-fan monitors found at power on.

    # Fail if system is Off and the fan monitors are present.
    Run Keyword If  '${power_state}' == 'Off' and ${num_fan_daemons} != 0
    ...  Fail  msg=Phosphor-fan monitors found at power off.


Get Fan Count And Names
    [Documentation]  Return the number of fans and the fan names.

    # The @{fan_names} list holds the names of the fans in the system.
    @{fan_names}  Create List
    ${fan_names}=  Get Fan Names  ${fan_names}

    ${number_of_fans}=  Get Length  ${fan_names}

    [Return]  ${number_of_fans}  ${fan_names}



Reset Fans
    [Documentation]  Set the fans to functional state.
    # Set state of fans to functional by writing 1 to the Functional
    # attribute of each fan in the @{fan_names} list.  If @{fan_names}
    # is empty nothing is done.
    [Arguments]  ${fan_names}

    # Description of Argument(s):
    # fan_names    A list containing the names of the fans (e.g. fan0
    #              fan2 fan3).

    FOR  ${fan_name}  IN  @{fan_names}
        Set Fan State  ${fan_name}  ${fan_functional}
    END

Verify Fan Speed
    [Documentation]  Verify fans are running at or near target speed.
    [Arguments]  ${tolerance}  ${fan_names}

    # Description of argument(s):
    # tolerance   The speed tolerance criteria.
    #             A tolerance value of .15 means that the fan's speed
    #             should be within 15% of its set target speed.
    #             Fans may be accelerating to meet a new target, so
    #             allow .10 extra.
    # fan_names   A list containing the names of the fans (e.g. fan0 fan1).

    # Compare the fan's speed with its target speed.
    FOR  ${fan_name}  IN  @{fan_names}
        ${target_speed}  ${fan_speed}=  Get Fan Target And Speed  ${fan_name}
        Rpvars  fan_name  target_speed  fan_speed
        # Calculate tolerance, which is a % of the target speed.
        ${tolerance_value}=  Evaluate  ${tolerance}*${target_speed}
        # Calculate upper and lower speed limits.
        ${max_limit}=  Evaluate   ${target_speed}+${tolerance_value}
        ${min_limit}=  Evaluate   ${target_speed}-${tolerance_value}
        Run Keyword If
        ...  ${fan_speed} < ${min_limit} or ${fan_speed} > ${max_limit}
        ...  Fail  msg=${fan_name} speed of ${fan_speed} is out of range.
    END

Verify Direct Fan Control
    [Documentation]  Verify direct control of fans.
    [Arguments]  ${max_speed}  ${min_speed}
    ...  ${minutes_to_stabilize}  ${number_of_fans}  ${fan_names}

    # Overview:
    # Turn off BMC's fan control daemon, then test to confirm
    # that fans can be controlled manually.
    # The app that takes data from sysfs and updates dbus is named hwmon.
    # Verify hwmon functionality by comparing with what's on dbus
    # (/xyz/openbmc_project/sensors/fan_tach/fan0_0, fan0_1, etc.)
    # with what's in the BMC's file system at
    # /sys/class/hwmon/hwmon9/fan*_input.

    # Description of argument(s):
    # max_speed               Integer value of maximum fan speed.
    # min_speed               Integer value of minimum speed.
    # minutes_to_stabilize    Time to wait for fan daemons to
    #                         stabilize fan operation after
    #                         tests (e.g. "4").
    # number_of_fans          The number of fans in the system.
    # fan_names               A list containing the names of the
    #                         fans (e.g. fan0 fan1).

    # Login to BMC and disable the fan daemon. Disabling the daemon sets
    # manual mode.
    Open Connection And Log In
    Set Fan Daemon State  stop

    # For each fan, set a new target speed and wait for the fan to
    # accelerate.  Then check that the fan is running near that speed.
    FOR  ${fan_name}  IN  @{fan_names}
        Set Fan Target Speed  ${fan_name}  ${max_speed}
        Run Key U  Sleep \ 60s
        ${target_speed}  ${cw_speed}  ${ccw_speed}=
        ...  Get Target And Blade Speeds  ${fan_name}
        Rpvars  fan_name  target_speed  cw_speed  ccw_speed
        Run Keyword If
        ...  ${cw_speed} < ${min_speed} or ${ccw_speed} < ${min_speed}
        ...  Fail  msg=${fan_name} failed manual speed test.
    END

    # Check the fan speeds in the BMC file system.

    # Get the location of the fan hwmon.
    ${controller_path}  ${stderr}  ${rc}=  BMC Execute Command
    ...  grep -ir max31785a /sys/class/hwmon/hwmon* | grep name
    # E.g., controller_path=/sys/class/hwmon/hwmon10/name:max31785a.

    ${hwmon_path}  ${file_name}=  Split Path  ${controller_path}
    # E.g.,  /sys/class/hwmon/hwmon10  or  /sys/class/hwmon/hwmon9.

    Rpvars  controller_path  hwmon_path

    # Run the BMC command which gets fan speeds from the file system.
    ${cmd}=  Catenate  cat ${hwmon_path}/fan*_input
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}

    # Convert output to integer values.
    ${speeds}=  Evaluate  map(int, $stdout.split(${\n}))
    Rpvars  speeds
    # Count the number of speeds > ${min_speed}.
    ${count}=  Set Variable  ${0}
    FOR  ${speed}  IN  @{speeds}
        ${count}=  Run Keyword If  ${speed} > ${min_speed}
        ...  Evaluate  ${count}+1  ELSE  Set Variable  ${count}
        # Because each fan has two rotating fan blades, the count should be
        # equual to 2*${number_of_fans}.  On water-cooled systems some
        # speeds may be reported by hwmon as 0.  That is expected,
        # and the number_of_fans reported in the system will be less.
    END
    ${fail_test}=  Evaluate  (2*${number_of_fans})-${count}

    # Re-enable the fan daemon
    Set Fan Daemon State  restart

    Run Keyword If  ${fail_test} > ${0}  Fail
    ...  msg=hwmon did not properly report fan speeds.

    # Wait for the daemon to take control and gracefully set fan speeds
    # back to normal.
    ${msg}=  Catenate  Waiting ${minutes_to_stabilize} minutes
    ...  for fan daemon to stabilize fans.
    Print Timen  ${msg}
    Run Key U  Sleep \ ${minutes_to_stabilize}m


Verify Fan Speed Increase
    [Documentation]  Verify that the speed of working fans increase when
    ...  one fan is marked as disabled.
    #  A non-functional fan should cause an error log and
    #  an enclosure LED will light.  The other fans should speed up.
    [Arguments]  ${fan_names}

    # Description of argument(s):
    # fan_names   A list containing the names of the fans (e.g. fan0 fan1).

    # Allow system_response_time before checking if there was a
    # response by the system to an applied fault.
    ${system_response_time}=  Set Variable  60s

    # Choose a fan to test with, e.g., fan0.
    ${test_fan_name}=  Get From List  ${fan_names}  0

    ${initial_speed}=  Get Target Speed Of Fans
    Rpvars  test_fan_name  initial_speed

    # If initial speed is not already at maximum, set expect_increase.
    # This flag is used later to determine if speed checking is
    # to be done or not.
    ${expect_increase}=  Run Keyword If
    ...  ${initial_speed} < ${max_speed}
    ...  Set Variable  1  ELSE  Set Variable  0

    Set Fan State  ${test_fan_name}  ${fan_nonfunctional}

    Run Key U  Sleep \ ${system_response_time}

    # A heavily loaded system may have powered-off.
    ${host_state}=  Get Host State
    Rpvars  host_state
    Run Keyword If  'Running' != '${host_state}'  Pass Execution
    ...  msg=System shutdown so skipping remainder of test.

    ${new_fan_speed}=  Get Target Speed Of Fans
    Rpvars  expect_increase  initial_speed  new_fan_speed

    # Fail if current fan speed did not increase past the initial
    # speed, but do this check only if not at maximum speed to begin with.
    Run Keyword If
    ...  ${expect_increase} == 1 and ${new_fan_speed} < ${initial_speed}
    ...  Fail  msg=Remaining fans did not increase speed with loss of one fan.



Verify System Shutdown Due To Fans
    [Documentation]  Shut down when not enough fans.
    [Arguments]  ${fan_names}

    # Description of argument(s):
    # fan_names   A list containing the names of the fans (e.g. fan0 fan1).

    ${wait_after_poweroff}=  Set Variable  15s

    # Set fans to be non-functional.
    FOR  ${fan_name}  IN  @{fan_names}
        Set Fan State  ${fan_name}  ${fan_nonfunctional}
    END

    # System should notice the non-functional fans and power-off.
    # The Wait For PowerOff keyword will time-out and report
    # an error if power off does not happen within a reasonable time.
    Wait For PowerOff
