*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/boot_utils.robot
Resource            ../lib/bmc_redfish_resource.robot
Library             ../lib/ipmi_utils.py
Library             ../lib/pty_process.py  AS  PTY
Variables           ../data/ipmi_raw_cmd_table.py

Test Setup          Start SOL Console Logging
Test Teardown       Test Teardown Execution

Test Tags           IPMI_SOL

*** Variables ***

@{valid_bit_rates}    ${9.6}  ${19.2}  ${38.4}  ${57.6}  ${115.2}
@{setinprogress}      set-complete  set-in-progress  commit-write
${invalid_bit_rate}   7.5

# Expected strings in SOL session output.
${SOL_OPERATIONAL_MSG}       SOL Session operational
${SOL_ALREADY_ACTIVE_MSG}    SOL payload already active on another session
${SOL_DEACTIVATED_MSG}       SOL payload already de-activated
# Log file base paths for SOL session capture (timestamp appended at runtime).
${SOL_SESSION_LOG}           ${EXECDIR}${/}logs${/}sol_session_${OPENBMC_HOST}
${SOL_SESSION2_LOG}          ${EXECDIR}${/}logs${/}sol_session2_${OPENBMC_HOST}
# UART device on AST2600 EVB connected to RPI serial console.
${SOL_UART_DEVICE}           ttyS3
# systemd service name for obmc-console on the UART device.
${OBMC_CONSOLE_SERVICE}      obmc-console@${SOL_UART_DEVICE}.service
# SSH connection timeout in seconds for SOL SSH access.
${SOL_SSH_TIMEOUT}           15
${HOST_COMMAND_PROMPT}       ${OS_USERNAME}@${OS_HOST}:~$


*** Test Cases ***

Set SOL Enabled
    [Documentation]  Verify enabling SOL via IPMI.
    [Tags]  Set_SOL_Enabled

    ${msg}=  Run Keyword  Run External IPMI Standard Command
    ...  sol set enabled true

    # Verify SOL status from ipmitool sol info command.
    ${sol_info_dict}=  Get SOL Info
    ${sol_enable_status}=  Get From Dictionary
    ...  ${sol_info_dict}  Enabled

    Should Be Equal  '${sol_enable_status}'  'true'


Set SOL Disabled
    [Documentation]  Verify disabling SOL via IPMI.
    [Tags]  Set_SOL_Disabled

    ${msg}=  Run Keyword  Run External IPMI Standard Command
    ...  sol set enabled false

    # Verify SOL status from ipmitool sol info command.
    ${sol_info_dict}=  Get SOL Info
    ${sol_enable_status}=  Get From Dictionary
    ...  ${sol_info_dict}  Enabled
    Should Be Equal  '${sol_enable_status}'  'false'

    # Verify error while activating SOL with SOL disabled.
    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Standard Command
    ...  sol activate
    Should Contain  ${msg}  SOL payload disabled  ignore_case=True


Set Valid SOL Privilege Level
    [Documentation]  Verify valid SOL's privilege level via IPMI.
    [Tags]  Set_Valid_SOL_Privilege_Level

    ${privilege_level_list}=  Create List  user  operator  admin  oem

    FOR  ${item}  IN  @{privilege_level_list}
      Set SOL Setting  privilege-level  ${item}
      ${output}=  Get SOL Setting  Privilege Level
      Should Contain  ${output}  ${item}  ignore_case=True
    END


Set Invalid SOL Privilege Level
    [Documentation]  Verify invalid SOL's retry count via IPMI.
    [Tags]  Set_Invalid_SOL_Privilege_Level

    ${value}=  Generate Random String  ${8}
    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Standard Command
    ...  sol set privilege-level ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Retry Count
    [Documentation]  Verify invalid SOL's retry count via IPMI.
    [Tags]  Set_Invalid_SOL_Retry_Count

    # Any integer above 7 is invalid for SOL retry count.
    ${value}=  Evaluate  random.randint(8, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Standard Command
    ...  sol set retry-count ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Retry Interval
    [Documentation]  Verify invalid SOL's retry interval via IPMI.
    [Tags]  Set_Invalid_SOL_Retry_Interval

    # Any integer above 255 is invalid for SOL retry interval.
    ${value}=  Evaluate  random.randint(256, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Standard Command
    ...  sol set retry-interval ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Character Accumulate Level
    [Documentation]  Verify invalid SOL's character accumulate level via IPMI.
    [Tags]  Set_Invalid_SOL_Character_Accumulate_Level

    # Any integer above 255 is invalid for SOL character accumulate level.
    ${value}=  Evaluate  random.randint(256, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Standard Command
    ...  sol set character-accumulate-level ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Set Invalid SOL Character Send Threshold
    [Documentation]  Verify invalid SOL's character send threshold via IPMI.
    [Tags]  Set_Invalid_SOL_Character_Send_Threshold

    # Any integer above 255 is invalid for SOL character send threshold.
    ${value}=  Evaluate  random.randint(256, 10000)  modules=random

    ${msg}=  Run Keyword And Expect Error  *  Run External IPMI Standard Command
    ...  sol set character-send-threshold ${value}
    Should Contain  ${msg}  Invalid value  ignore_case=True


Verify SOL During Boot
    [Documentation]  Verify SOL activate console output during boot.
    [Tags]  Verify_SOL_During_Boot

    IPMI Power Off  stack_mode=skip
    Activate SOL Via IPMI
    Initiate Host Boot Via External IPMI  wait=${0}

    Should Not Be Empty  ${SOL_BIOS_OUTPUT}
    Should Not Be Empty  ${SOL_LOGIN_OUTPUT}

    # Content takes maximum of 10 minutes to display in SOL console
    # SOL_BIOS_OUTPUT - BIOS SOL console output
    ${status}=  Run Keyword And Return Status  Wait Until Keyword Succeeds  10 mins  15 secs
    ...  Check IPMI SOL Output Content  ${SOL_BIOS_OUTPUT}

    IF  '${status}' == 'False'
        IPMI Power Off
        FAIL  msg=BIOS not loaded.
    END

    # SOL_LOGIN_OUTPUT - SOL output login prompt
    # Once host reboot completes, SOL console may take maximum of 15 minutes to get the login prompt.
    ${status}=  Run Keyword And Return Status  Wait Until Keyword Succeeds  15 mins  15 secs
    ...  Check IPMI SOL Output Content  ${SOL_LOGIN_OUTPUT}

    IF  '${status}' == 'False'  IPMI Power Off


Verify Deactivate Non Existing SOL
    [Documentation]  Verify deactivate non existing SOL session.
    [Tags]  Verify_Deactivate_Non_Existing_SOL

    ${resp}=  Deactivate SOL Via IPMI
    Should Contain  ${resp}  SOL payload already de-activated
    ...  case_insensitive=True


Set Valid SOL Retry Count
    [Documentation]  Verify valid SOL's retry count via IPMI.
    [Tags]  Set_Valid_SOL_Retry_Count
    [Template]  Verify SOL Setting

    # Setting name    Min valid value    Max valid value
    retry-count       0                  7


Set Valid SOL Retry Interval
    [Documentation]  Verify valid SOL's retry interval via IPMI.
    [Tags]  Set_Valid_SOL_Retry_Interval
    [Template]  Verify SOL Setting

    # Setting name    Min valid value    Max valid value
    retry-interval    0                  255


Set Valid SOL Character Accumulate Level
    [Documentation]  Verify valid SOL's character accumulate level via IPMI.
    [Tags]  Set_Valid_SOL_Character_Accumulate_Level
    [Template]  Verify SOL Setting

    # Setting name              Min valid value    Max valid value
    character-accumulate-level  1                  255


Set Valid SOL Character Send Threshold
    [Documentation]  Verify valid SOL's character send threshold via IPMI.
    [Tags]  Set_Valid_SOL_Character_Send_Threshold
    [Template]  Verify SOL Setting

    # Setting name              Min valid value    Max valid value
    character-send-threshold    0                  255


Verify Continuous Activation And Deactivation Of SOL
    [Documentation]  Continuously on and off SOL.
    [Tags]  Verify_Continuous_Activation_And_Deactivation_Of_SOL

    ${iteration_count}=  Evaluate  random.randint(5,10)  modules=random
    FOR  ${iter}  IN RANGE  ${iteration_count}
        Activate SOL Via IPMI
        Deactivate SOL Via IPMI
    END


Verify SOL Payload Channel
    [Documentation]  Verify SOL payload channel from SOL info.
    [Tags]  Verify_SOL_Payload_Channel

    # Get channel number from SOL Info and verify it is not empty.
    ${payload_channel}=  Get SOL Setting  Payload Channel
    Should Not Be Empty  ${payload_channel}


Verify SOL Payload Port
    [Documentation]  Verify SOL payload port from SOL info.
    [Tags]  Verify_SOL_Payload_Port

    # Get Payload Port from SOL Info and verify it equal with ipmi port.
    ${payload_port}=  Get SOL Setting  Payload Port
    Should Be Equal  ${IPMI_PORT}  ${payload_port}


Set Valid SOL Non Volatile Bit Rate
    [Documentation]  Verify ability to set valid SOL non-volatile bit rate.
    [Tags]  Set_Valid_SOL_Non_Volatile_Bit_Rate

    FOR  ${bit_rate}  IN  @{valid_bit_rates}

      # Set valid non-volatile-bit-rate from SOL Info.
      Run Keyword And Expect Error  *Parameter not supported*
      ...  Run External IPMI Standard Command
      ...  sol set non-volatile-bit-rate ${bit_rate}

    END


Set Invalid SOL Non Volatile Bit Rate
    [Documentation]  Verify ability to set invalid SOL non-volatile bit rate.
    [Tags]  Set_Invalid_SOL_Non_Volatile_Bit_Rate

    # Set Invalid non-volatile-bit-rate from SOL Info.
    ${resp}=  Run Keyword And Expect Error  *${IPMI_RAW_CMD['SOL']['Set_SOL'][0]}*
    ...  Run External IPMI Standard Command  sol set non-volatile-bit-rate ${invalid_bit_rate}

    # Compares whether valid values are displayed.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['SOL']['Set_SOL'][1]}  ignore_case=True


Set Valid SOL Volatile Bit Rate
    [Documentation]  Verify ability to set valid SOL volatile bit rate.
    [Tags]  Set_Valid_SOL_Volatile_Bit_Rate

    FOR  ${bit_rate}  IN  @{valid_bit_rates}

      # Set valid volatile-bit-rate from SOL Info.
      Run Keyword And Expect Error  *Parameter not supported*
      ...  Run External IPMI Standard Command
      ...  sol set volatile-bit-rate ${bit_rate}

    END


Set Invalid SOL Volatile Bit Rate
    [Documentation]  Verify ability to set invalid SOL volatile bit rate.
    [Tags]  Set_Invalid_SOL_Volatile_Bit_Rate

    # Set invalid volatile-bit-rate from SOL Info.
    ${resp}=  Run Keyword And Expect Error  *${IPMI_RAW_CMD['SOL']['Set_SOL'][0]}*
    ...  Run External IPMI Standard Command  sol set volatile-bit-rate ${invalid_bit_rate}

    # Compares whether valid values are displayed.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['SOL']['Set_SOL'][1]}  ignore_case=True


Verify SOL Set In Progress
    [Documentation]  Verify ability to set the set in-progress data for SOL.
    [Tags]  Verify_SOL_Set_In_Progress
    [Teardown]  Run Keywords  Set SOL Setting  set-in-progress  set-complete
    ...         AND  Test Teardown Execution

    # Set the param 0 - set-in-progress from SOL Info.
    FOR  ${prog}  IN  @{setinprogress}
       Run Keyword  Run External IPMI Standard Command  sol set set-in-progress ${prog}
       # Get the param 0 - set-in-progress from SOL Info and verify.
       ${set_inprogress_state}=  Get SOL Setting  Set in progress
       Should Be Equal  ${prog}  ${set_inprogress_state}
    END


Verify Standalone SOL Output From DCSCM Using SBC Over IPMI
    [Documentation]  Verify SOL can be activated via IPMI and provides console output and Escape sequences.
    [Tags]  Verify_Standalone_SOL_Output_From_DCSCM_Using_SBC_Over_IPMI
    [Setup]  Test Setup
    [Teardown]  Test Teardown

    # Activate SOL in a real PTY and wait for the operational banner.
    # Start SOL PTY Session uses pexpect to spawn ipmitool in a pseudo-terminal.
    # so it behaves like a real terminal and prints "SOL Session operational".
    ${TS}=    Get Time    result_format=%Y%m%d_%H%M%S
    ${log_file}=    Set Variable    ${SOL_SESSION_LOG}_${TS}.log
    ${ipmi_cmd}=    Create IPMI Ext Command String    sol activate usesolkeepalive
    PTY.Start Sol Pty Session    ${ipmi_cmd}    ${log_file}
    ...    alias=sol_pty_tc01    startup_timeout=30

    # Verify obmc-console-client process is running on BMC.
    ${ps_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ps | grep obmc-console-client  ignore_err=${1}
    Should Contain  ${ps_output}  obmc-console-client
    ...  msg=obmc-console-client process not found on BMC

    # Check journalctl for obmc-console@ttyS3 entries.
    ${journal_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -u obmc-console@${SOL_UART_DEVICE} -n 50 --no-pager
    Should Not Be Empty  ${journal_output}
    ...  msg=No journalctl entries found for obmc-console@${SOL_UART_DEVICE}
    Log  journalctl output: ${journal_output}

    # Verify obmc-console service is active.
    ${svc_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  systemctl status ${OBMC_CONSOLE_SERVICE} --no-pager
    Log  obmc-console service status: ${svc_output}
    Should Contain  ${svc_output}  active
    ...  msg=${OBMC_CONSOLE_SERVICE} is not active while SOL session is running

    # Verify supported escape sequences via ~? help.
    # Note: ipmitool escape sequences are only recognized immediately after newline.
    # Send a newline first, then ~? to request the help message.
    PTY.Send To PTY Process    sol_pty_tc01    \n
    PTY.Send To PTY Process    sol_pty_tc01    ~?
    ${help_output}=    PTY.Read PTY Process Output    sol_pty_tc01    timeout=8
    Log    SOL escape sequence help output: ${help_output}

    # Verify all documented escape sequences are listed in the help output.
    Should Contain    ${help_output}    ~.
    ...    msg=Escape sequence '~.' (terminate connection) not found in ~? help output
    Should Contain    ${help_output}    ~^Z
    ...    msg=Escape sequence '~^Z' (suspend ipmitool) not found in ~? help output
    Should Contain    ${help_output}    ~^X
    ...    msg=Escape sequence '~^X' (suspend, no tty restore) not found in ~? help output
    Should Contain    ${help_output}    ~?
    ...    msg=Escape sequence '~?' (help) not found in ~? help output

    # Test ~^Z – suspend ipmitool, then resume via SIGCONT.
    # ipmitool recognises escape sequences only immediately after a newline.
    PTY.Send To PTY Process    sol_pty_tc01    \n
    PTY.Send To PTY Process    sol_pty_tc01    ~\x1a
    Sleep    1s
    PTY.Resume PTY Process    sol_pty_tc01
    ${z_output}=    PTY.Read PTY Process Output    sol_pty_tc01    timeout=3
    Log    ~^Z suspend/resume output: ${z_output}

    # Test ~^X – suspend ipmitool (no tty restore), then resume via SIGCONT.
    PTY.Send To PTY Process    sol_pty_tc01    \n
    PTY.Send To PTY Process    sol_pty_tc01    ~\x18
    Sleep    1s
    PTY.Resume PTY Process    sol_pty_tc01
    ${x_output}=    PTY.Read PTY Process Output    sol_pty_tc01    timeout=3
    Log    ~^X suspend/resume output: ${x_output}

    # Test ~~ – send a literal ~ character to the remote console.
    PTY.Send To PTY Process    sol_pty_tc01    \n
    PTY.Send To PTY Process    sol_pty_tc01    ~~
    PTY.Send To PTY Process    sol_pty_tc01    \n
    ${tilde_output}=    PTY.Read PTY Process Output    sol_pty_tc01    timeout=3
    Log    ~~ (literal tilde) output: ${tilde_output}

    # Deactivate SOL by sending ~. escape sequence via PTY.
    PTY.Send To PTY Process    sol_pty_tc01    \n
    PTY.Send To PTY Process    sol_pty_tc01    ~.
    ${tilde_output}=    PTY.Read PTY Process Output    sol_pty_tc01    timeout=3
    Log    ~. (literal tilde) output: ${tilde_output}
    PTY.Stop PTY Process    sol_pty_tc01    force=${True}
    Sleep    1s
    ${output}=    PTY.Get Pty Process Log    ${log_file}
    Should Contain    ${output}    ${SOL_OPERATIONAL_MSG}
    Should Contain    ${output}    ~^Z [suspend ipmitool]

    # Verify SOL info is accessible.
    ${sol_info}=  Get SOL Info
    Should Not Be Empty  ${sol_info}
    ...  msg=SOL info returned empty after deactivation


Verify SOL Serial Console Configuration Via Redfish
    [Documentation]  Verify SOL serial console configuration via Redfish API.
    [Tags]  Verify_SOL_Serial_Console_Configuration_Via_Redfish
    [Setup]  Test Setup
    [Teardown]  Test Teardown

    ${system_resp}=  Redfish.Get  /redfish/v1/Systems/${SYSTEM_ID}
    ${serial_console}=  Get From Dictionary  ${system_resp.dict}  SerialConsole

    # Verify IPMI ServiceEnabled.
    ${ipmi_config}=  Get From Dictionary  ${serial_console}  IPMI
    ${ipmi_enabled}=  Get From Dictionary  ${ipmi_config}  ServiceEnabled
    Should Be True  ${ipmi_enabled}
    ...  msg=SerialConsole.IPMI.ServiceEnabled is not true

    # Verify MaxConcurrentSessions.
    ${max_sessions}=  Get From Dictionary  ${serial_console}  MaxConcurrentSessions
    Should Be Equal As Integers  ${max_sessions}  15
    ...  msg=SerialConsole.MaxConcurrentSessions expected 15, got ${max_sessions}

    # Verify SSH Port.
    ${ssh_config}=  Get From Dictionary  ${serial_console}  SSH
    ${ssh_port}=  Get From Dictionary  ${ssh_config}  Port
    Should Be Equal As Integers  ${ssh_port}  ${HOST_SOL_PORT}
    ...  msg=SerialConsole.SSH.Port expected ${HOST_SOL_PORT}, got ${ssh_port}

    # Verify SSH ServiceEnabled.
    ${ssh_enabled}=  Get From Dictionary  ${ssh_config}  ServiceEnabled
    Should Be True  ${ssh_enabled}
    ...  msg=SerialConsole.SSH.ServiceEnabled is not true


Verify Standalone SOL Output From DCSCM Using SBC Over SSH
    [Documentation]  Verify SOL console (RPI/HOST) is accessible via SSH on port 2200.
    [Tags]  Verify_Standalone_SOL_Output_From_DCSCM_Using_SBC_Over_SSH
    [Setup]  Test Setup
    [Teardown]  Test Teardown
    ${TS}=    Get Time    result_format=%Y%m%d_%H%M%S
    ${log_file}=    Set Variable    ${SOL_SESSION_LOG}_ssh_${TS}.log
    # Build the ssh command – StrictHostKeyChecking=no avoids the interactive.
    # "Are you sure you want to continue connecting?" prompt.
    ${ssh_cmd}=    Catenate
    ...    ssh -p ${HOST_SOL_PORT}
    ...    -o StrictHostKeyChecking=no
    ...    -o UserKnownHostsFile=/dev/null
    ...    ${OPENBMC_USERNAME}@${OPENBMC_HOST}

    # Spawn SSH in a real PTY so the interactive console does not hang.
    PTY.Start PTY Process    ${ssh_cmd}    ${log_file}
    ...    alias=sol_ssh_tc04    timeout=30

    # Handle password prompt and authenticate.
    PTY.Wait For PTY Process Output    sol_ssh_tc04    [Pp]assword:    timeout=15
    PTY.Send Line To PTY Process    sol_ssh_tc04    ${OPENBMC_PASSWORD}

    # Verify connection is established – read output after login.
    # obmc-console drops the user directly into the serial console.
    # there may be no shell prompt, so we just verify non-empty output is received.
    ${conn_output}=    PTY.Read PTY Process Output    sol_ssh_tc04    timeout=10
    Log    SSH SOL connection output: ${conn_output}
    Should Not Be Empty    ${conn_output}
    ...    msg=No output received after SSH login on port ${HOST_SOL_PORT}

    # Send a newline to provoke a response from the RPI console.
    PTY.Send To PTY Process    sol_ssh_tc04    \n
    ${console_output}=    PTY.Read PTY Process Output    sol_ssh_tc04    timeout=5
    Log    SOL SSH console output after newline: ${console_output}

    # Exit the SSH session cleanly.
    PTY.Stop PTY Process    sol_ssh_tc04    force=${True}
    Sleep    1s
    ${output}=    PTY.Get Pty Process Log    ${log_file}
    Should Contain    ${output}    ${HOST_COMMAND_PROMPT}


Verify IPMI SOL Activate Function
    [Documentation]  Verify IPMI SOL activate function works correctly.
    [Tags]  Verify_IPMI_SOL_Activate_Function
    [Setup]  Test Setup
    [Teardown]  Test Teardown
    # Start SOL PTY Session spawns ipmitool in a real PTY, waits for the
    # "SOL Session operational" banner, confirming the session is active.
    ${TS}=    Get Time    result_format=%Y%m%d_%H%M%S
    ${log_file}=    Set Variable    ${SOL_SESSION_LOG}_${TS}.log
    ${ipmi_cmd}=    Create IPMI Ext Command String    sol activate usesolkeepalive
    PTY.Start Sol Pty Session    ${ipmi_cmd}    ${log_file}
    ...    alias=sol_pty_tc05    startup_timeout=30

    # Verify obmc-console-client is running on BMC.
    ${ps_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ps | grep obmc-console-client  ignore_err=${1}
    Should Contain  ${ps_output}  obmc-console-client
    ...  msg=obmc-console-client process not found on BMC during SOL session

    # Deactivate SOL via ipmitool sol deactivate, then close the PTY process.
    ${deactivate_cmd}=    Create IPMI Ext Command String    sol deactivate
    ${rc}    ${deactivate_output}=    Run And Return RC And Output    ${deactivate_cmd}
    Log    Deactivate output: ${deactivate_output}
    PTY.Stop PTY Process    sol_pty_tc05    force=${True}
    Sleep    1s
    ${output}=    PTY.Get Pty Process Log    ${log_file}
    Should Contain    ${output}    ${SOL_OPERATIONAL_MSG}


Verify IPMI SOL Terminate Function
    [Documentation]  Verify IPMI SOL deactivate function works correctly.
    [Tags]  Verify_IPMI_SOL_Terminate_Function
    [Setup]  Test Setup
    [Teardown]  Test Teardown
    # Activate SOL via PTY library so ipmitool runs in a real terminal.
    ${TS}=    Get Time    result_format=%Y%m%d_%H%M%S
    ${log_file}=    Set Variable    ${SOL_SESSION_LOG}_${TS}.log
    ${ipmi_cmd}=    Create IPMI Ext Command String    sol activate usesolkeepalive
    PTY.Start Sol Pty Session    ${ipmi_cmd}    ${log_file}
    ...    alias=sol_pty_tc06    startup_timeout=30

    # Deactivate SOL via ipmitool sol deactivate (synchronous).
    ${deactivate_cmd}=    Create IPMI Ext Command String    sol deactivate
    ${rc}    ${deactivate_output}=    Run And Return RC And Output    ${deactivate_cmd}
    Log    Deactivate output: ${deactivate_output}

    # Close the PTY process now that the session has been deactivated.
    PTY.Stop PTY Process    sol_pty_tc06    force=${True}
    Sleep    1s
    ${output}=    PTY.Get Pty Process Log    ${log_file}
    Should Contain    ${output}    ${SOL_OPERATIONAL_MSG}

    # Verify SOL is no longer active by deactivating again.
    ${deactivate_cmd}=    Create IPMI Ext Command String    sol deactivate
    ${rc2}    ${output2}=    Run And Return RC And Output    ${deactivate_cmd}
    Log    Second deactivate output: ${output2}
    Should Contain    ${output2}    ${SOL_DEACTIVATED_MSG}
    ...    msg=SOL session was not properly deactivated. Expected '${SOL_DEACTIVATED_MSG}'


Verify IPMI SOL Activate While Another Session Active
    [Documentation]  Verify behavior when activating SOL while another session is active.
    [Tags]  Verify_IPMI_SOL_Activate_While_Another_Session_Active
    [Setup]  Test Setup
    [Teardown]  Test Teardown

    # Client-1 activates SOL session via PTY library.
    ${TS}=    Get Time    result_format=%Y%m%d_%H%M%S
    ${log1}=    Set Variable    ${SOL_SESSION_LOG}_${TS}.log
    ${log2}=    Set Variable    ${SOL_SESSION2_LOG}_${TS}.log
    ${ipmi_cmd}=    Create IPMI Ext Command String    sol activate usesolkeepalive
    PTY.Start Sol Pty Session    ${ipmi_cmd}    ${log1}
    ...    alias=sol_pty_client1    startup_timeout=30

    # Client-2 attempts to activate SOL (should be rejected).
    # This is a synchronous call – ipmitool exits immediately with the error.
    ${client2_cmd}=    Create IPMI Ext Command String    sol activate
    ${rc}    ${client2_output}=    Run And Return RC And Output    ${client2_cmd}
    Log    Client-2 activation output: ${client2_output}
    Should Contain    ${client2_output}    ${SOL_ALREADY_ACTIVE_MSG}
    ...    msg=Expected '${SOL_ALREADY_ACTIVE_MSG}' but got: ${client2_output}

    # Verify no crash/hang - rc should not indicate a hang (-1).
    Should Not Be Equal As Integers    ${rc}    ${-1}
    ...    msg=Client-2 SOL activate command hung or crashed (rc=${rc})

    # Deactivate Client-1 via ipmitool sol deactivate, then close PTY.
    ${deactivate_cmd}=    Create IPMI Ext Command String    sol deactivate
    Run And Return RC And Output    ${deactivate_cmd}
    PTY.Stop PTY Process    sol_pty_client1    force=${True}
    Sleep    1s
    ${output}=    PTY.Get Pty Process Log    ${log1}
    Should Contain    ${output}    ${SOL_OPERATIONAL_MSG}

    # Client-2 retries SOL activate via PTY (should succeed now).
    ${ipmi_cmd2}=    Create IPMI Ext Command String    sol activate usesolkeepalive
    PTY.Start Sol Pty Session    ${ipmi_cmd2}    ${log2}
    ...    alias=sol_pty_client2    startup_timeout=30

    # Deactivate Client-2 via ipmitool sol deactivate, then close PTY.
    ${deactivate_cmd}=    Create IPMI Ext Command String    sol deactivate
    Run And Return RC And Output    ${deactivate_cmd}
    PTY.Stop PTY Process    sol_pty_client2    force=${True}
    Sleep    1s
    ${output}=    PTY.Get Pty Process Log    ${log2}
    Should Contain    ${output}    ${SOL_OPERATIONAL_MSG}


*** Keywords ***

Check IPMI SOL Output Content
    [Documentation]  Check if SOL has given content.
    [Arguments]  ${data}  ${file_path}=${IPMI_SOL_LOG_FILE}

    # Description of argument(s):
    # data       Content which need to be checked(e.g. Petitboot, ISTEP).
    # file_path  The file path on the local machine to check SOL content.
    #            By default it check SOL content from log/sol_<BMC_IP>.

    ${output}=  OperatingSystem.Get File  ${file_path}  encoding_errors=ignore
    Should Match Regexp  ${output}  ${data}  case_insensitive=True


Verify SOL Setting
    [Documentation]  Verify SOL Setting via IPMI.
    [Arguments]  ${setting_name}  ${min_value}  ${max_value}
    # Description of Arguments:
    # setting_name    Setting to verify (e.g. "retry-count").
    # min_value       min valid value for given setting.
    # max_value       max valid value for given setting.

    ${value}=
    ...  Evaluate  random.randint(${min_value}, ${max_value})  modules=random

    # Character accumulate level setting is set in multiples of 5.
    # Retry interval setting is set in multiples of 10.
    # Reference IPMI specification v2.0

    IF  '${setting_name}' == 'character-accumulate-level'
        ${expected_value}=  Evaluate  ${value}*5
    ELSE IF  '${setting_name}' == 'retry-interval'
        ${expected_value}=  Evaluate  ${value}*10
    ELSE
        ${expected_value}=  Set Variable  ${value}
    END

    Set SOL Setting  ${setting_name}  '${value}'

    # Replace "-" with space " " in setting name.
    # E.g. "retry-count" to "retry count"
    ${setting_name}=  Evaluate  $setting_name.replace('-',' ')

    ${sol_info_dict}=  Get SOL Info

    # Get exact SOL setting name from sol info output.
    ${list}=  Get Matches  ${sol_info_dict}  ${setting_name}*
    ...  case_insensitive=${True}
    ${setting_name_from_dict}=  Get From List  ${list}  0

    # Get SOL setting value from above setting name.
    ${setting_value}=  Get From Dictionary
    ...  ${sol_info_dict}  ${setting_name_from_dict}

    Should Be Equal  '${setting_value}'  '${expected_value}'

    IPMI Power Off  stack_mode=skip

    Initiate Host Boot Via External IPMI  wait=${0}

    Activate SOL Via IPMI
    # Content takes maximum of 10 minutes to display in SOL console
    # SOL_BIOS_OUTPUT - BIOS SOL console output
    ${status}=  Run Keyword And Return Status  Wait Until Keyword Succeeds  10 mins  15 secs
    ...  Check IPMI SOL Output Content  ${SOL_BIOS_OUTPUT}

    IF  '${status}' == 'False'
        IPMI Power Off
        FAIL  msg=BIOS not loaded.
    END

    # SOL_LOGIN_OUTPUT - SOL output login prompt
    # Once host reboot completes, SOL console may take maximum of 15 minutes to get the login prompt.
    ${status}=  Run Keyword And Return Status  Wait Until Keyword Succeeds  15 mins  15 secs
    ...  Check IPMI SOL Output Content  ${SOL_LOGIN_OUTPUT}

    IF  '${status}' == 'False'  IPMI Power Off


Get SOL Setting
    [Documentation]  Returns status for given SOL setting.
    [Arguments]  ${setting}
    # Description of argument(s):
    # setting  SOL setting which needs to be read(e.g. "Retry Count").

    ${sol_info_dict}=  Get SOL Info
    ${setting_status}=  Get From Dictionary  ${sol_info_dict}  ${setting}

    RETURN  ${setting_status}


Restore Default SOL Configuration
    [Documentation]  Restore default SOL configuration.

    Set SOL Setting  enabled  true
    Set SOL Setting  retry-count  7
    Set SOL Setting  retry-interval  10
    Set SOL Setting  character-accumulate-level  20
    Set SOL Setting  character-send-threshold  1
    Set SOL Setting  privilege-level  user


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Wait Until Keyword Succeeds  15 sec  5 sec  Restore Default SOL Configuration
    Deactivate SOL Via IPMI
    ${sol_log}=  Stop SOL Console Logging
    Log   ${sol_log}
    FFDC On Test Case Fail

Test Setup
    [Documentation]  Test setup - verify prerequisites and clean up stale SOL sessions.

    # Verify ipmitool is available on the test host.
    ${rc}  ${output}=  Run And Return RC And Output  which ipmitool
    Should Be Equal As Integers  ${rc}  ${0}
    ...  msg=ipmitool not found on test host. Please install ipmitool.

    # Create logs directory if it does not exist.
    Create Directory  ${EXECDIR}${/}logs

    # Ensure no stale SOL sessions exist before starting.
    Run External IPMI Standard Command  sol deactivate  ${0}

    # Login to Redfish.
    Redfish.Login


Test Teardown
    [Documentation]  Test teardown - stop any PTY sessions, collect FFDC on test failure, Redfish logout.

    Run External IPMI Standard Command  sol deactivate  ${0}
    Stop All PTY Processes
    FFDC On Test Case Fail
    Redfish.Logout
