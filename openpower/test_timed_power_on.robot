*** Settings ***
Documentation   Power ON the BMC using timed power ON function.

Resource        ../lib/utils.robot
Resource        ../lib/state_manager.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Connections

*** Variables ****

${CMD_SCHEDULE_TIME}    busctl set-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime t

${CMD_VERIFY_TIME}      busctl get-property xyz.openbmc_project.State.ScheduledHostTransition
...  /xyz/openbmc_project/state/host0 xyz.openbmc_project.State.ScheduledHostTransition ScheduledTime

# User defined Timer.
${TIMER_POWER_ON}       100

*** Test Cases ***

Set The Time For Power ON
    [Documentation]  Set the time for power ON and verify the time set via busctl command.
    [Tags]  Set_The_Time_For_Power_ON

    Set The Timer
    ${TPO_Value}=  Verify the TPO is set
    Should Not Be Equal  ${TPO_Value}  0


Verify The System Powered ON
    [Documentation]  Verify the system gets powered ON after certain time.
    [Tags]  Verify_The_System_Powered_ON

    ${TPO_Value}=  Verify the TPO is set
    Run Keyword if  '${TPO_Value}' == '${0}'   Set The Timer

    Sleep  ${TIMER_POWER_ON}
    Wait Until Keyword Succeeds  2 min  15 sec  Is Chassis On


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Open Connection And Login
    BMC Execute Command  /usr/bin/obmcutil poweroff
    Wait Until Keyword Succeeds  3 min  15 sec  Is Host Off


Set The Timer
    [Documentation]  Set the time for power ON

    ${current_time_bmc}=  BMC Execute Command  date +%s
    ${time_set}=  Evaluate  ${current_time_bmc[0]} + ${TIMER_POWER_ON}
    BMC Execute Command  ${CMD_SCHEDULE_TIME} ${time_set}


Verify the TPO is set
    [Documentation]  Verify the TPO is set and return the TPO value

    ${timer_value}=  BMC Execute Command  ${CMD_VERIFY_TIME}
    # BMC command returns two parameters spliting it and returning the integer value 
    ${return_value}=  Split String  ${timer_value[0]}
    
    [return]  ${return_value[1]}
