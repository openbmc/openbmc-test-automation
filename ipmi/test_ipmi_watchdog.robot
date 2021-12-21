*** Settings ***

Documentation    Module to test IPMI watchdog functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/boot_utils.robot
Library          ../lib/ipmi_utils.py
Library          String
Library          Collections
Variables        ../data/ipmi_raw_cmd_table.py

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout

*** Variables ***

${timer_delay}          3
${power_state_change}   20

*** Test Cases ***

Test IPMI Watchdog Timer Don't Log Bit
    [Documentation]  Execute out of band IPMI raw set command for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Don't_Log_Bit
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # Test action        set_raw_cmd                          get_raw_cmd                              resp_expect
    Enable       ${IPMI_RAW_CMD['Watchdog']['Set'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][1]}
    Disabled     ${IPMI_RAW_CMD['Watchdog']['Set'][3]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][3]}

Test IPMI Watchdog Timer Stop Bit
    [Documentation]  Execute out of band IPMI raw set command for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Stop_Bit
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # Stop_Bit           set_raw_cmd                          get_raw_cmd                              resp_expect
    Stop         ${IPMI_RAW_CMD['Watchdog']['Set'][6]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][5]}
    Resume       ${IPMI_RAW_CMD['Watchdog']['Set'][9]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][7]}

Test IPMI Watchdog Timer Use Bits
    [Documentation]  Execute out of band IPMI raw set command for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Use_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # Timer Use          set_raw_cmd                          get_raw_cmd                              resp_expect
    FRB2         ${IPMI_RAW_CMD['Watchdog']['Set'][12]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][9]}
    POST         ${IPMI_RAW_CMD['Watchdog']['Set'][15]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][11]}
    OS           ${IPMI_RAW_CMD['Watchdog']['Set'][18]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][13]}
    SMS          ${IPMI_RAW_CMD['Watchdog']['Set'][21]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][15]}
    OEM          ${IPMI_RAW_CMD['Watchdog']['Set'][24]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][17]}

Test IPMI Watchdog Timer Pre-Timeout Interrupt Bits
    [Documentation]  Execute out of band IPMI raw set command for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Pre-Timeout_Interrupt_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # Interrupt          set_raw_cmd                          get_raw_cmd                              resp_expect
    None         ${IPMI_RAW_CMD['Watchdog']['Set'][27]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][19]}
    NMI          ${IPMI_RAW_CMD['Watchdog']['Set'][30]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][21]}

Test IPMI Watchdog Timer Timeout Action Bits
    [Documentation]  Execute out of band IPMI raw set command for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Timeout_Action_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # Timer Action       set_raw_cmd                          get_raw_cmd                              resp_expect
    None         ${IPMI_RAW_CMD['Watchdog']['Set'][33]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][23]}
    Reset        ${IPMI_RAW_CMD['Watchdog']['Set'][36]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][25]}
    Power Down   ${IPMI_RAW_CMD['Watchdog']['Set'][39]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][27]}
    Power Cycle  ${IPMI_RAW_CMD['Watchdog']['Set'][42]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][29]}

Test IPMI Watchdog Timer Timeout Flag Bits
    [Documentation]  Execute out of band IPMI raw set command for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Timeout_Flag_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # Timeout Flag       set_raw_cmd                          get_raw_cmd                              resp_expect
    FRB2         ${IPMI_RAW_CMD['Watchdog']['Set'][45]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][31]}
    POST         ${IPMI_RAW_CMD['Watchdog']['Set'][48]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][33]}
    OS           ${IPMI_RAW_CMD['Watchdog']['Set'][51]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][35]}
    SMS          ${IPMI_RAW_CMD['Watchdog']['Set'][54]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][37]}
    OEM          ${IPMI_RAW_CMD['Watchdog']['Set'][57]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][39]}


Verify Timer Action Power Down
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Timer_Action_Power_Down

    # Check the chassis status.
    Verify Host Is On

    # Clear SEL.
    ${resp}=  Run IPMI Standard Command  sel clear

    # Set watchdog timer action to power down.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][60]}

    # Reset Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay for power state.
    Sleep   ${power_state_change}

    Get Host Power State  ['off']  Power down


Verify Timer Action Hard Reset
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Timer_Action_Hard_Reset

    # Check the chassis status.
    Verify Host Is On

    # Clear SEL.
    ${resp}=  Run IPMI Standard Command  sel clear

    # Set watchdog timer action to hard reset.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][63]}

    # Reset Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay for power state.
    Sleep   ${power_state_change}

    Get Host Power State  ['on']  Hard Reset


Verify Timer Action Power Cycle
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Timer_Action_Power_Cycle

    # Check the chassis status.
    Verify Host Is On

    # Clear SEL.
    ${resp}=  Run IPMI Standard Command  sel clear

    # Set watchdog timer action to power cycle.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][66]}

    # Reset Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay for power_state.
    Sleep   ${power_state_change}

    Get Host Power State  ['on']  Power cycle


Verify Timer Action No Action
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Timer_Action_No_Action

    # Check the chassis status.
    Verify Host Is On

    # Clear SEL.
    ${resp}=  Run IPMI Standard Command  sel clear

    # Set watchdog timer action to no action.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][69]}

    # Reset Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay for power state.
    Sleep   ${power_state_change}

    Get Host Power State  ['on']  Timer expired


Verify Reset Timer
    [Documentation]  Set Watchdog via IPMI raw command and verify Reset Timer functions as expected.
    [Tags]  Verify_Reset_Timer

    # Check the chassis status.
    Verify Host Is On

    # Set Watchdog Timer initCount(0x3530).
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][72]}

    # Get Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Watchdog']['Get'][41]}

    @{start_timer_value}=  Split String  ${resp}
    FOR    ${value}    IN    @{start_timer_value}
        Log    ${value}
    END

    # Convert start value to integer.
    ${value}=   Get Slice From List  ${start_timer_value}   6
    Reverse List   ${value}
    ${start_timer_string}=  Evaluate   "".join(${value})
    ${start_timer_integer} =  Convert To Integer 	${start_timer_string}  16

    # Delay.
    Sleep   ${timer_delay}

    # Get Watchdog Timer before reset watchdog timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Watchdog']['Get'][41]}

    # Reset Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay.
    Sleep   ${timer_delay}

    Get Watchdog Timer And Compare To Start Value  ${start_timer_integer}

    # Reset Watchdog Timer when the timer is counting down.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay.
    Sleep   ${timer_delay}

    Get Watchdog Timer And Compare To Start Value  ${start_timer_integer}

    # Delay.
    Sleep   ${timer_delay}

    Get Watchdog Timer And Compare To Start Value  ${start_timer_integer}


Verify Pre-timeout Values
    [Documentation]  Set Watchdog Pre-timeout via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Pre-timeout_Values

    # Expected to pass: pre-timeout interval (7000) <= initial count (8000).
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][75]}
    Should Contain   ${resp}   ${EMPTY}

    # Expected to fail: pre-timeout interval (4000) > initial count (1000).
    Run Keyword and Expect Error  *Invalid data field*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][78]}

    # Verify the watchdog sets the initial count to its maximum properly.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][81]}
    Should Contain   ${resp}   ${EMPTY}

    # Verify Watchdog Timer bit6 is not set when timer is stopped.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    Should Contain   ${resp}   ${IPMI_RAW_CMD['Watchdog']['Get'][43]}

Verify Invalid Request Data Length
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Invalid_Request_Data_Length

    #Set Watchdog Timer with one less byte.
    Run Keyword and Expect Error  *Request data length*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][84]}

    #Set Watchdog Timer with one extra byte.
    Run Keyword and Expect Error  *Request data length*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][87]}

    #Get Watchdog Timer with one extra byte.
    Run Keyword and Expect Error  *Request data length*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][45]}

Verify Invalid Reset Timer Request Data
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Invalid_Request_Data_Length

    # Reset Watchdog Timer with one extra byte.
    Run Keyword and Expect Error  *Request data length*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][3]}

    # Reset BMC.
    Redfish BMC Reset Operation
    Check If BMC is Up

    # Reset Watchdog Timer without initialized watchdog.
    Run Keyword and Expect Error  *Unknown*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][6]}

*** Keywords ***

Execute IPMI Raw Command And Verify Response Data
    [Documentation]  Execute out of band IPMI raw command and verify response data.
    [Arguments]   ${bit_purpose}  ${set_raw_cmd}  ${get_raw_cmd}  ${resp_expect}

    # Description of argument(s):
    # bit_purpose     Purpose of the associated bit(s).
    # set_raw_cmd     The request bytes for the command.
    # get_raw_cmd     The response bytes for the command.
    # resp_expect     The expected response bytes for the command.

    ${resp}=  Run IPMI Standard Command  raw ${set_raw_cmd}
    ${resp}=  Run IPMI Standard Command  raw ${get_raw_cmd}
    Should Contain  ${resp}  ${resp_expect}   msg=Expecting ${resp_expect} but got ${resp}.

Get Host Power State
    [Documentation]   Get host power state using external IPMI command and verify SEL entry.
    [Tags]  Get_Host_Power_State
    [Arguments]  ${ipmi_value}  ${state_string}

    # Description of argument(s):
    # ipmi_value     Value of Host power state: "on" or "off".
    # state_string   Text of SEL event after timer action.

    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ${ipmi_value}
    ${resp}=  Run IPMI Standard Command  sel elist
    ${power_status}=  Get Lines Containing String  ${resp}  Watchdog
    Should Contain  ${power_status}  ${state_string}

Verify Host Is On
    [Documentation]   Verify host is powered on.
    [Tags]  Verify_Host_Is_On

    IPMI Power On  stack_mode=skip  quiet=1
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['on']

Get Watchdog Timer And Compare To Start Value
    [Documentation]   Get watchdog value, convert to integer, and compare to original start value.
    [Tags]  Get_Watchdog_Timer_And_Compare_To_Start_Value
    [Arguments]  ${start_timer_integer}

    # Description of argument(s):
    # start_timer_integer     The initial value for the watchdog timer.

    # Get Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    @{timer_value}=   Split String  ${resp}

    FOR    ${value}    IN    @{timer_value}
        Log    ${value}
    END

    # Convert to integer and compare with start value.
    ${value}=   Get Slice From List  ${timer_value}   6
    Reverse List   ${value}
    ${timer_string}=   Evaluate   "".join(${value})
    ${current_timer_integer} = 	Convert To Integer 	${timer_string}  16
    Should Be True   ${current_timer_integer} < ${start_timer_integer}