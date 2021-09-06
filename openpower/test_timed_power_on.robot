*** Settings ***
Documentation   This suite tests timed power On feature of OpenBMC.

Resource        ../lib/state_manager.robot

Test Setup      Test Setup Execution
Test Teardown   Run keywords  Close All Connections  AND  FFDC On Test Case Fail


*** Variables ****

${CMD_SCHEDULE_TIME}    busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime t

${CMD_TPO_TIME}         busctl get-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime

${TIMER_POWER_ON}       100


*** Test Cases ***

Set Time For Power ON
    [Documentation]  Set time for power ON using busctl command and verify.
    [Tags]  Set_Time_For_Power_ON

    Set Timer For Power ON  ${TIMER_POWER_ON}

    ${tpo_value}=  Get Time Power ON Value
    Should Not Be Equal  ${tpo_value}  0


Verify System Power On After TPO
    [Documentation]  Verify system power on after TPO.
    [Tags]  Verify_System_Power_On_After_TPO

    Set Timer For Power ON  ${TIMER_POWER_ON}

    # Verify that chassis does not power ON during time power on time.
    ${random_time}=  Evaluate  random.randint(1, ${TIMER_POWER_ON})  modules=random
    Sleep  ${random_time}

    ${status}=  Run Keyword And Return status  Is Chassis On
    Should Be Equal  ${status}  ${False}

    # Verify that chassis becomes ON after some time.
    Wait Until Keyword Succeeds  2 min  15 sec  Is Chassis On


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Open Connection And Login
    BMC Execute Command  /usr/bin/obmcutil poweroff
    Wait Until Keyword Succeeds  3 min  15 sec  Is Host Off


Set Timer For Power ON
    [Documentation]  Set the time for power ON with given value .
    [Arguments]  ${time}
    # Description of argument(s):
    # time  Time duration for setting TPO.

    ${current_bmc_time}=  BMC Execute Command  date +%s
    ${time_set}=  Evaluate  ${current_bmc_time[0]} + ${time}
    BMC Execute Command  ${CMD_SCHEDULE_TIME} ${time_set}


Get Time Power ON Value
    [Documentation]  Returns time power ON value.

    ${timer_value}=  BMC Execute Command  ${CMD_TPO_TIME}
    # BMC command returns two parameters splitting it and returning the integer value.

    [Return]  ${timer_value[1]}
