Documentation  Utility for SNMP configurations via Redfish.

*** Settings ***

Resource                ../../../../lib/utils.robot
Resource                ../../../../lib/connection_client.robot
Library                 ../../../../lib/gen_misc.py
Library                 ../../../../lib/utils.py


*** Keywords ***

Configure SNMP Manager Via Redfish
    [Documentation]  Configure SNMP manager on BMC via Redfish.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}  ${snmp_id}=${snmp_manager_id}  ${valid_status_codes}=${HTTP_NO_CONTENT}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP address
    # snmp_port  SNMP manager port
    # valid_status_code  expected code

    ${snmp_mgr_data}=  Create Dictionary  Id=${snmp_id}  Enabled=${true}
    ...  Port=${snmp_port}  Destination=${snmp_mgr_ip}

    ${snmp_trap_manager}=  Create List  ${snmp_mgr_data}
    ${trap_server}=  Create Dictionary  TrapServer=${snmp_trap_manager}
    ${snmp_mgr_data}=  Create Dictionary  SnmpTrapNotification=${trap_server}

    Redfish.Patch  ${subscription_uri}  body=&{snmp_mgr_data}
    ...  valid_status_codes=[${valid_status_codes}]


Verify SNMP Manager Configured On BMC
    [Documentation]  Verify SNMP manager configured on BMC.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}  ${snmp_id}=${0}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP address
    # snmp_port  SNMP manager port
    # snmp_id  SNMP manager id, default value is 0

    # Get the list of SNMP managers that are configured on BMC.
    @{snmp_mgr_list}=  Get SNMP Manager Config  TrapServer

    FOR  ${member}  IN  @{snmp_mgr_list}
        ${id}=  Get From Dictionary  ${member}  Id
        IF  ${id} == ${snmp_id}
            ${ip}=  Get From Dictionary  ${member}  Destination
            ${port}=  Get From Dictionary  ${member}  Port
            Should Be Equal  ${ip}  ${snmp_mgr_ip}
            ...  msg=SNMP manager is not configured.
            Should Be Equal  ${port}  ${snmp_port}
            ...  msg=SNMP manager is not configured.
            Exit For Loop
        END
    END


Get SNMP Manager Config
    [Documentation]  Get SNMP manager configured on BMC.
    [Arguments]  ${snmp_config}

    ${snmp_mgr_config}=  Redfish.Get Attribute  ${subscription_uri}  SnmpTrapNotification
    ${ret_config}=  Get From Dictionary  ${snmp_mgr_config}  ${snmp_config}

    RETURN  ${ret_config}


Reset SNMP Manager Config Via Redfish
    [Documentation]  Delete SNMP manager.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}  ${snmp_id}=${0}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP.
    # snmp_port    Network port where SNMP manager is listening.
    # snmp_id      SNMP manager id, default value is 0
    ${status}=  Run Keyword And Return Status
    ...  Configure SNMP Manager Via Redfish  ${snmp_mgr_ip}  ${snmp_port}  ${snmp_id}
    Should Be Equal  ${status}  ${True}
    ...  msg=SNMP manager is not reseted to default in the backend.


Create Error On BMC And Verify Trap
    [Documentation]  Generate error on BMC and verify if trap is sent.
    [Arguments]  ${event_log}=${CMD_SEL_LOG_CLEAR}  ${expected_error}=${SEL_LOG_CLEAR_EVENT}

    # Description of argument(s):
    # event_log       Event logs to be created.
    # expected_error  Expected error on SNMP.

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Start SNMP Manager

    # Generate error log.
    BMC Execute Command  ${event_log}

    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=15s

    Reset SNMP Manager Config Via Redfish  ${SNMP_DEFAULT_IP}  ${SNMP_DEFAULT_PORT}

    # Stop SNMP manager process.
    SSHLibrary.Execute Command  sudo pkill -9 snmptrapd

    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}

    ${trap_info_line_one}=  Get From List  ${lines}  -2
    ${trap_info_line_two}=  Get From List  ${lines}  -1

    ${snmp_trap_one}=  Split String  ${trap_info_line_one}  \t
    Remove Values From List  ${snmp_trap_one}  ${EMPTY}

    ${snmp_trap_two}=  Split String  ${trap_info_line_two}  \t
    Remove Values From List  ${snmp_trap_two}  ${EMPTY}

    ${snmp_trap}=  Combine Lists  ${snmp_trap_one}  ${snmp_trap_two}

    Log Many  ${snmp_trap}

    Verify SNMP Trap  ${snmp_trap}  ${expected_error}

    RETURN  ${snmp_trap}


Verify SNMP Trap
    [Documentation]  Verify SNMP trap.
    [Arguments]  ${snmp_trap}  ${expected_error}=${SEL_LOG_CLEAR_EVENT}

    # Description of argument(s):
    # snmp_trap       SNMP trap collected on SNMP manager.
    # expected_error  Expected error on SNMP.

    # Verify all the mandatory fields of trap.
    Should Contain  ${snmp_trap}[0]  SNMPv2-SMI::enterprises.37945.1.1 Enterprise Specific Trap
    Should Contain  ${snmp_trap}[1]  SNMPv2-SMI::enterprises.37945.1.1.1.1 = STRING:
    Should Contain  ${snmp_trap}[2]  SNMPv2-SMI::enterprises.37945.1.1.1.26 = STRING:
    Should Contain  ${snmp_trap}[3]  SNMPv2-SMI::enterprises.37945.1.1.1.37 = STRING:
    Should Contain  ${snmp_trap}[4]  SNMPv2-SMI::enterprises.37945.1.1.1.38 = STRING: ${expected_error}
    Should Contain  ${snmp_trap}[5]  SNMPv2-SMI::enterprises.37945.1.1.1.32 =
    Should Contain  ${snmp_trap}[6]  SNMPv2-SMI::enterprises.37945.1.1.1.42 = STRING:
    Should Contain  ${snmp_trap}[7]  SNMPv2-SMI::enterprises.37945.1.1.1.6 = STRING:
    Should Contain  ${snmp_trap}[8]  SNMPv2-SMI::enterprises.37945.1.1.1.41 = STRING:


Start SNMP Manager
    [Documentation]  Start SNMP listener on the remote SNMP manager.

    Open Connection And Log In  ${SNMP_MGR1_USERNAME}  ${SNMP_MGR1_PASSWORD}
    ...  alias=snmp_server  host=${SNMP_MGR1_IP}

    # Clean SNMP managers running in the background.
    SSHLibrary.Execute Command  sudo pkill -9 snmptrapd

    # The execution of the SNMP_TRAPD_CMD is necessary to cause SNMP to begin
    # listening to SNMP messages.
    SSHLibrary.write  ${SNMP_TRAPD_CMD} &


Create Error On BMC And Verify Trap On Non Default Port
    [Documentation]  Generate error on BMC and verify if trap is sent to non default port.
    [Arguments]  ${event_log}=$${CMD_SEL_LOG_CLEAR}  ${expected_error}=${SEL_LOG_CLEAR_EVENT}

    # Description of argument(s):
    # event_log       Event logs to be created.
    # expected_error  Expected error on SNMP.

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Start SNMP Manager On Specific Port  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    # Generate error log.
    BMC Execute Command  ${event_log}

    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=15s

    Reset SNMP Manager Config Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    # Stop SNMP manager process.
    SSHLibrary.Execute Command  sudo pkill -9 snmptrapd

    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}
    ${trap_info_line_one}=  Get From List  ${lines}  -2
    ${trap_info_line_two}=  Get From List  ${lines}  -1

    ${snmp_trap_one}=  Split String  ${trap_info_line_one}  \t
    Remove Values From List  ${snmp_trap_one}  ${EMPTY}

    ${snmp_trap_two}=  Split String  ${trap_info_line_two}  \t
    Remove Values From List  ${snmp_trap_two}  ${EMPTY}

    ${snmp_trap}=  Combine Lists  ${snmp_trap_one}  ${snmp_trap_two}

    Log Many  ${snmp_trap}
    Verify SNMP Trap  ${snmp_trap}  ${expected_error}

    RETURN  ${snmp_trap}


Start SNMP Manager On Specific Port
    [Documentation]  Start SNMP listener on specific port on the remote SNMP manager.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP.
    # snmp_port    Network port on which SNMP manager need to run.

    ${ip_and_port}=  Catenate  ${snmp_mgr_ip}:${snmp_port}

    Open Connection And Log In  ${SNMP_MGR1_USERNAME}  ${SNMP_MGR1_PASSWORD}
    ...  alias=snmp_server  host=${SNMP_MGR1_IP}

    # The execution of the SNMP_TRAPD_CMD is necessary to cause SNMP to begin
    # listening to SNMP messages.
    SSHLibrary.write  ${SNMP_TRAPD_CMD} ${ip_and_port} &


Generate Error On BMC And Verify Trap
    [Documentation]  Generate error on BMC and verify if trap is sent.
    [Arguments]  ${event_log}=${CMD_SEL_LOG_CLEAR}  ${expected_error}=${SEL_LOG_CLEAR_EVENT}

    # Description of argument(s):
    # event_log       Event logs to be created.
    # expected_error  Expected error on SNMP.

    Start SNMP Manager

    # Generate error log.
    BMC Execute Command  ${event_log}

    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=15s

    Reset SNMP Manager Config Via Redfish  ${SNMP_DEFAULT_IP}  ${SNMP_DEFAULT_PORT}

    # Stop SNMP manager process.
    SSHLibrary.Execute Command  sudo pkill -9 snmptrapd

    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}
    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}

    ${trap_info_line_one}=  Get From List  ${lines}  -2
    ${trap_info_line_two}=  Get From List  ${lines}  -1

    ${snmp_trap_one}=  Split String  ${trap_info_line_one}  \t
    Remove Values From List  ${snmp_trap_one}  ${EMPTY}

    ${snmp_trap_two}=  Split String  ${trap_info_line_two}  \t
    Remove Values From List  ${snmp_trap_two}  ${EMPTY}

    ${snmp_trap}=  Combine Lists  ${snmp_trap_one}  ${snmp_trap_two}

    Log Many  ${snmp_trap}

    Verify SNMP Trap  ${snmp_trap}  ${expected_error}

    RETURN  ${snmp_trap}

