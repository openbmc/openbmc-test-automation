*** Settings ***

Documentation  Operational check of fans with OS booted.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID to login to the BMC as.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
#
# Approximate run time:   18 minutes.

Resource        ../../lib/utils.robot
Resource        ../../lib/fan_utils.robot
Resource        ../../lib/dump_utils.robot


Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution


*** Test Cases ***


Check Number Of Fans With Power On
    [Documentation]  Verify system has the minimum number of fans.
    [Tags]  Check_Number_Of_Fans_With_Power_On

    # Determine if system is water cooled.
    ${water_cooled}=  Is Water Cooled
    Rprint Vars  water_cooled

    Verify Minimum Number Of Fans With Cooling Type  ${number_of_fans}
    ...  ${water_cooled}


Check Number Of Fan Monitors With Power On
    [Documentation]  Verify monitors are present when power on.
    [Tags]  Check_Number_Of_Fan_Monitors_With_Power_On

    Verify Fan Monitors With State  On


Check Fans Running At Target Speed
    [Documentation]  Verify fans are running at or near target speed.
    [Tags]  Check_Fans_Running_At_Target_Speed

    # Set the speed tolerance criteria.
    # A tolerance value of .30 means that the fan's speed should be
    # within 30% of its set target speed.   Fans may be accelerating
    # or decelerating to meet a new target, so allow .20 extra.
    ${tolerance}=  Set Variable  .50
    Rprint Vars  tolerance

    Verify Fan Speed  ${tolerance}  ${fan_names}


Check Fan Manual Control
    [Documentation]  Check direct control of fans.
    [Tags]  Check_Fan_Manual_Control

    # The maximum target speed.
    ${max_speed}=  Set Variable  ${10500}

    # Speed criteria for passing, which is 85% of max_speed.
    ${min_speed}=  Set Variable  ${8925}

    # Time allowed for the fan daemon to take control and then return
    # the fans to normal speed.
    ${minutes_to_stabilize}=  Set Variable  4

    Verify Direct Fan Control
    ...  ${max_speed}  ${min_speed}  ${minutes_to_stabilize}
    ...  ${number_of_fans}  ${fan_names}


Check Fan Speed Increase When One Disabled
    [Documentation]  Verify that the speed of working fans increase when
    ...  one fan is disabled.
    [Tags]  Check_Fan_Speed_Increase_When_One_Disabled
    #  A non-functional fan should cause an error log and
    #  an enclosure LED will light.  The other fans should speed up.

    Verify Fan Speed Increase  ${fan_names}


Check System Shutdown Due To Fans
    [Documentation]  Shut down when not enough fans.
    [Tags]  Check_System_Shutdown_Due_To_Fans

    # Previous test may have shut down the OS.
    Redfish Power On  stack_mode=skip

    Verify System Shutdown Due To Fans  ${fan_names}


*** Keywords ***

Reset Fans And Error Logs
    [Documentation]  Reset Fans, Error Logs, and LEDs

    Reset Fans  ${fan_names}
    Run Key U  Sleep \ 15s
    Delete All Error Logs
    Redfish Delete All BMC Dumps
    Set System LED State  front_fault  Off
    Set System LED State  rear_fault  Off


Suite Setup Execution
    [Documentation]  Do the pre-suite setup.

    Redfish Power On  stack_mode=skip

    ${number_of_fans}  ${fan_names}=  Get Fan Count And Names
    Printn
    Rprint Vars  number_of_fans  fan_names
    Set Suite Variable  ${fan_names}  children=true
    Set Suite Variable  ${number_of_fans}  children=true

    Reset Fans And Error Logs


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    FFDC On Test Case Fail
    Reset Fans And Error Logs
