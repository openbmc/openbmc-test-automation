*** Settings ***
Documentation    Test suite for Serial Over LAN (SOL) on AST2600 EVB + RPI setup.
...
...              Hardware Setup:
...              - AST2600 EVB board running OpenBMC (BMC)
...              - Raspberry Pi (RPI) connected to AST2600 EVB via UART (ttyS3)
...              - SOL on EVB provides console access to RPI over IPMI / SSH / Redfish


Resource         ../../../lib/ipmi_client.robot
Resource         ../../../lib/openbmc_ffdc.robot
Resource         ../../../lib/bmc_redfish_resource.robot
Resource         ../resource.robot
Library          ../../../lib/ipmi_utils.py
Library          ../../../lib/pty_process.py  AS  PTY


Suite Setup      Suite Setup Execution
Suite Teardown   Suite Teardown Execution
Test Teardown    Test Teardown Execution

Test Tags        SOL

*** Variables ***
# UART device on AST2600 EVB connected to RPI serial console.
${SOL_UART_DEVICE}           ttyS3
# Expected strings in SOL session output.
${SOL_OPERATIONAL_MSG}       SOL Session operational
${SOL_ALREADY_ACTIVE_MSG}    SOL payload already active on another session
${SOL_DEACTIVATED_MSG}       SOL payload already de-activated
# Log file base paths for SOL session capture (timestamp appended at runtime).
${SOL_SESSION_LOG}           ${EXECDIR}${/}logs${/}sol_session_${OPENBMC_HOST}
${SOL_SESSION2_LOG}          ${EXECDIR}${/}logs${/}sol_session2_${OPENBMC_HOST}
# systemd service name for obmc-console on the UART device.
${OBMC_CONSOLE_SERVICE}      obmc-console@${SOL_UART_DEVICE}.service
# SSH connection timeout in seconds for SOL SSH access.
${SOL_SSH_TIMEOUT}           15
${HOST_COMMAND_PROMPT}       ${HOST_USERNAME}@${HOST_IP}:~$

*** Test Cases ***

Verify Standalone SOL Output From DCSCM Using SBC Over IPMI
    [Documentation]  Verify SOL can be activated via IPMI and provides console output and Escape sequences.
    [Tags]  Verify_Standalone_SOL_Output_From_DCSCM_Using_SBC_Over_IPMI  EVB+RPI

    # Activate SOL in a real PTY and wait for the operational banner.
    # Start SOL PTY Session uses pexpect to spawn ipmitool in a pseudo-terminal
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
    [Tags]  Verify_SOL_Serial_Console_Configuration_Via_Redfish  EVB+RPI

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
    [Tags]  Verify_Standalone_SOL_Output_From_DCSCM_Using_SBC_Over_SSH  EVB+RPI

    ${TS}=    Get Time    result_format=%Y%m%d_%H%M%S
    ${log_file}=    Set Variable    ${SOL_SESSION_LOG}_ssh_${TS}.log
    # Build the ssh command – StrictHostKeyChecking=no avoids the interactive
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
    # obmc-console drops the user directly into the serial console; there may
    # be no shell prompt, so we just verify non-empty output is received.
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
    [Tags]  Verify_IPMI_SOL_Activate_Function  EVB+RPI

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
    [Tags]  Verify_IPMI_SOL_Terminate_Function  EVB+RPI

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
    [Tags]  Verify_IPMI_SOL_Activate_While_Another_Session_Active  EVB+RPI

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

Suite Setup Execution
    [Documentation]  Suite setup - verify prerequisites and clean up stale SOL sessions.

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


Suite Teardown Execution
    [Documentation]  Suite teardown - Redfish logout.

    Redfish.Logout


Test Teardown Execution
    [Documentation]  Test teardown - stop any PTY sessions and collect FFDC on test failure.

    Run External IPMI Standard Command  sol deactivate  ${0}
    Stop All PTY Processes
    FFDC On Test Case Fail