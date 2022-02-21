*** Settings ***

Documentation    Module to test IPMI watchdog functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/boot_utils.robot
Library          ../lib/ipmi_utils.py
Library          String
Library          Collections
Variables        ../data/ipmi_raw_cmd_table.py

*** Variables ***

${TIMER_DELAY}          3
${POWER_STATE_CHANGE}   20

*** Test Cases ***

Test IPMI Watchdog Timer Don't Log Bit
    [Documentation]  Execute out of band set/get don't log bit for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Don't_Log_Bit
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # don't log bit set_raw_cmd  get_raw_cmd  resp_expect
    ${IPMI_RAW_CMD['Watchdog']['Set'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][1]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][3]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][3]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][0]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][1]}

Test IPMI Watchdog Timer Stop Bit
    [Documentation]  Execute out of band set/get stop/resume timer stop bit for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Stop_Bit
    [Template]  Execute IPMI Raw Command And Verify Response Data After Watchdog Expires

    # set_raw_cmd  get_raw_cmd  resp_expect
    ${IPMI_RAW_CMD['Watchdog']['Set'][6]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][5]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][9]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][7]}

Test IPMI Watchdog Timer Use Bits
    [Documentation]  Execute out of band set/get timer use bits for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Use_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # set_raw_cmd  get_raw_cmd  resp_expect
    ${IPMI_RAW_CMD['Watchdog']['Set'][12]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][9]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][15]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][11]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][18]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][13]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][21]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][15]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][24]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][17]}

Test IPMI Watchdog Timer Pre-Timeout Interrupt Bits
    [Documentation]  Execute out of band set/get pre-timeout interrupt bits for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Pre-Timeout_Interrupt_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # set_raw_cmd  get_raw_cmd  resp_expect
    ${IPMI_RAW_CMD['Watchdog']['Set'][27]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][19]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][30]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][21]}

Test IPMI Watchdog Timer Timeout Action Bits
    [Documentation]  Execute out of band set/get timer timeout bits for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Timeout_Action_Bits
    [Template]  Execute IPMI Raw Command And Verify Response Data

    # set_raw_cmd  get_raw_cmd  resp_expect
    ${IPMI_RAW_CMD['Watchdog']['Set'][33]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][23]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][36]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][25]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][39]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][27]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][42]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][29]}

Test IPMI Watchdog Timer Timeout Flag Bits
    [Documentation]  Execute out of band set/get timer timeout flag bits for watchdog timer.
    [Tags]  Test_IPMI_Watchdog_Timer_Timeout_Flag_Bits
    [Template]  Execute IPMI Raw Command And Verify Timer Expiration Data

    # set_raw_cmd  get_raw_cmd  resp_expect
    ${IPMI_RAW_CMD['Watchdog']['Set'][45]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][31]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][48]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][33]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][51]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][35]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][54]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][37]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][57]}  ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    ...  ${IPMI_RAW_CMD['Watchdog']['Get'][39]}


Verify Timer Action For State Change
    [Documentation]  Set Watchdog via IPMI raw command and verify timer actions.
    [Tags]  Verify_Timer_Action_For_State_Change
    [Template]  Validate Watchdog Timer Actions And SEL Events

    # set action command                 power state  SEL event
    ${IPMI_RAW_CMD['Watchdog']['Set'][60]}  ['off']  Power down
    ${IPMI_RAW_CMD['Watchdog']['Set'][63]}  ['on']   Hard Reset
    ${IPMI_RAW_CMD['Watchdog']['Set'][66]}  ['on']   Power cycle
    ${IPMI_RAW_CMD['Watchdog']['Set'][69]}  ['on']   Timer expired


Verify Reset Timer
    [Documentation]  Set Watchdog via IPMI raw command and verify Reset Timer functions as expected.
    [Tags]  Verify_Reset_Timer

    # Check the chassis status.
    Power On Host And Verify

    # Set Watchdog Timer initCount(0x3530).
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][72]}

    # Get Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Watchdog']['Get'][41]}

    @{start_timer_value}=  Split String  ${resp}

    # Convert start value to integer.
    # Example: Get watchdog response is 0x06 0x24 0x05 0x00 0x64 0x00 0x64 0x00.
    # Start_timer_value is bits 6 - 7; set to 0x64 0x00 (100 ms decimal).
    # Reverse bits 6 - 7 due to BMC being little endian; new value is 0x00 0x64.
    # Convert hex value 0x00 0x64 to integer; start_timer_integer = 100.
    ${value}=  Get Slice From List  ${start_timer_value}   6
    Reverse List  ${value}
    ${start_timer_string}=  Evaluate  "".join(${value})
    ${start_timer_integer}=  Convert To Integer  ${start_timer_string}  16

    # Delay.
    Sleep  ${TIMER_DELAY}

    # Get Watchdog Timer before reset watchdog timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Watchdog']['Get'][41]}

    FOR    ${1}    IN    ${3}

        # Reset Watchdog Timer.
        Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}
        # Delay.
        Sleep  ${timer_delay}
        Get Watchdog Timer And Compare To Start Value  ${start_timer_integer}

    END


Verify Pre-timeout Values
    [Documentation]  Set Watchdog Pre-timeout via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Pre-timeout_Values
    [Template]  Validate Watchdog Pre-timeout

    # command                               response
    ${IPMI_RAW_CMD['Watchdog']['Set'][75]}  ${EMPTY}
    ${IPMI_RAW_CMD['Watchdog']['Set'][81]}  ${EMPTY}
    ${IPMI_RAW_CMD['Watchdog']['Get'][0]}   ${IPMI_RAW_CMD['Watchdog']['Get'][43]}

Verify Failure For Pre-Timeout Interval Greater Than Initial Count
    [Documentation]  Set Watchdog Pre-timeout greater than inital count via IPMI raw command.
    [Tags]  Verify_Failure_For_Pre-Timeout_Interval_Greater_Than_Initial_Count

    # Expected to fail: pre-timeout interval (4000) greater than initial count (1000).
    Run Keyword and Expect Error  *Invalid data field*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Set'][78]}

Verify Invalid Request Data Length
    [Documentation]  Set Watchdog Pre-Timeout invalid request data length via IPMI raw command.
    [Tags]  Verify_Invalid_Request_Data_Length
    [Template]  Watchdog Invalid Request Data Length

    # command
    ${IPMI_RAW_CMD['Watchdog']['Set'][84]}
    ${IPMI_RAW_CMD['Watchdog']['Set'][87]}
    ${IPMI_RAW_CMD['Watchdog']['Get'][45]}

Verify Invalid Reset Timer Request Data
    [Documentation]  Set Watchdog via IPMI raw command and verify via Get Watchdog Timer.
    [Tags]  Verify_Invalid_Reset_Timer_Request_Data

    # Reset Watchdog Timer with one extra byte.
    Run Keyword and Expect Error  *Request data length*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][3]}

    # Reset BMC.
    Run External IPMI Standard Command  mc reset cold -N 10 -R 1
    Check If BMC is Up

    # Reset Watchdog Timer without initializing watchdog.
    Run Keyword and Expect Error  *Unknown*
    ...  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][6]}

*** Keywords ***

Execute IPMI Raw Command And Verify Response Data After Watchdog Expires
    [Documentation]  Execute out of band IPMI raw command and verify response data after watchdog expires.
    [Arguments]  ${set_raw_cmd}  ${get_raw_cmd}  ${resp_expect}

    # Description of argument(s):
    # set_raw_cmd     The request bytes for the command.
    # get_raw_cmd     The response bytes for the command.
    # resp_expect     The expected response bytes for the command.

    Run IPMI Standard Command  raw ${set_raw_cmd}
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}
    Run IPMI Standard Command  raw ${set_raw_cmd}
    ${resp}=  Run IPMI Standard Command  raw ${get_raw_cmd}
    Should Contain  ${resp}  ${resp_expect}  msg=Expecting ${resp_expect} but got ${resp}.

Execute IPMI Raw Command And Verify Response Data
    [Documentation]  Execute out of band IPMI raw command and verify response data.
    [Arguments]  ${set_raw_cmd}  ${get_raw_cmd}  ${resp_expect}

    # Description of argument(s):
    # set_raw_cmd        The request bytes for the command.
    # get_raw_cmd        The response bytes for the command.
    # resp_expect        The expected response bytes for the command.

    Run IPMI Standard Command  raw ${set_raw_cmd}
    ${resp}=  Run IPMI Standard Command  raw ${get_raw_cmd}
    Should Contain  ${resp}  ${resp_expect}  msg=Expecting ${resp_expect} but got ${resp}.

Execute IPMI Raw Command And Verify Timer Expiration Data
    [Documentation]  Execute out of band IPMI raw command and verify timer expiration response data.
    [Arguments]  ${set_raw_cmd}  ${get_raw_cmd}  ${resp_expect}

    # Description of argument(s):
    # set_raw_cmd        The request bytes for the command.
    # get_raw_cmd        The response bytes for the command.
    # resp_expect        The expected response bytes for the command.

    Run IPMI Standard Command  raw ${set_raw_cmd}
    Run IPMI Standard Command  raw ${get_raw_cmd}
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}
    ${resp}=  Run IPMI Standard Command  raw ${get_raw_cmd}
    Should Contain  ${resp}  ${resp_expect}  msg=Expecting ${resp_expect} but got ${resp}.

Validate Watchdog Timer Actions And SEL Events
    [Documentation]  Verify the watchdog timer actions and the associated SEL events.
    [Arguments]  ${set_raw_cmd}  ${power_state}  ${sel_event}

    # Description of argument(s):
    # set_raw_cmd        The set timeout action request bytes for the command.
    # power_state        The expected power state of the host.
    # sel_event          The response bytes for the command.

    # Check the chassis status.
    Power On Host And Verify

    # Clear SEL.
    Run IPMI Standard Command  sel clear

    # Set watchdog timer action to perform action.
    Run IPMI Standard Command  raw ${set_raw_cmd}

    # Reset Watchdog Timer.
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Reset'][0]}

    # Delay for power state.
    Sleep  ${POWER_STATE_CHANGE}

    Verify Host Power State  ${power_state}
    Verify Watchdog Timer Action SEL Event  ${sel_event}


Verify Host Power State
    [Documentation]   Get host power state using external IPMI command and verify.
    [Arguments]  ${power_state}

    # Description of argument(s):
    # power_state     Value of Host power state: "on" or "off".

    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ${power_state}

Verify Watchdog Timer Action SEL Event
    [Documentation]   Verify watchdog timer action events are logged in SEL.
    [Arguments]  ${sel_event}

    # Description of argument(s):
    # sel_event       Text of SEL event after timer action.

    ${resp}=  Run IPMI Standard Command  sel elist
    ${power_status}=  Get Lines Containing String  ${resp}  Watchdog
    Should Contain  ${power_status}  ${sel_event}

Power On Host And Verify
    [Documentation]   Power the host on and verify.

    IPMI Power On  stack_mode=skip  quiet=1
    ${ipmi_state}=  Get Host State Via External IPMI
    Valid Value  ipmi_state  ['on']

Watchdog Invalid Request Data Length
    [Documentation]   Verify invalid request bytes for set watchdog returns correct error.
    [Arguments]  ${watchdog_command}

    # Description of argument(s):
    # watchdog_command     The raw watchdog IPMI command request bytes.

    Run Keyword and Expect Error  *Request data length*
    ...  Run IPMI Standard Command  raw ${watchdog_command}

Validate Watchdog Pre-timeout
    [Documentation]   Verify watchdog pre-timeout valid request bytes.
    [Arguments]  ${watchdog_command}  ${response}

    # Description of argument(s):
    # watchdog_command     The raw watchdog IPMI command request bytes.
    # response             The expected response bytes.

    ${resp}=  Run IPMI Standard Command  raw ${watchdog_command}
    Should Contain  ${resp}  ${response}

Get Watchdog Timer And Compare To Start Value
    [Documentation]   Get watchdog value, convert to integer, and compare to original start value.
    [Arguments]  ${start_timer_integer}

    # Description of argument(s):
    # start_timer_integer   The initial value for the watchdog timer.

    # Get Watchdog Timer.
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Watchdog']['Get'][0]}
    @{timer_value}=  Split String  ${resp}

    # Convert to integer and compare with start value.
    # Example: Get watchdog response is 0x06 0x24 0x05 0x00 0x64 0x00 0x64 0x00.
    # Start_timer_value is bits 6 - 7; set to 0x64 0x00 (100 ms decimal).
    # Reverse bits 6 - 7 due to BMC being little endian; new value is 0x00 0x64.
    # Convert hex value 0x00 0x64 to integer; start_timer_integer = 100.
    ${value}=   Get Slice From List  ${timer_value}   6
    Reverse List   ${value}
    ${timer_string}=   Evaluate   "".join(${value})
    ${current_timer_integer}=  Convert To Integer  ${timer_string}  16
    Should Be True   ${current_timer_integer} < ${start_timer_integer}