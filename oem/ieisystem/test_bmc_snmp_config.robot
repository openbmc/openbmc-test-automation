*** Settings ***
Documentation  This testing requires special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.

Resource  ../../lib/snmp/resource.robot
Resource  ../../lib/snmp/snmp_utils.robot
Resource  ../../lib/openbmc_ffdc.robot
Resource  ../../lib/logging_utils.robot

Library  String
Library  SSHLibrary

Suite Setup      Redfish.Login
Test Teardown    FFDC On Test Case Fail
Suite Teardown   Redfish.Logout

Test Tags        BMC_SNMP_Config

*** Test Cases ***

Configure SNMP Manager On BMC And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    ...  ${snmp_manager_id}  Valid

    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Reset SNMP Manager And Object  ${SNMP_DEFAULT_IP}  ${SNMP_DEFAULT_PORT}


Configure SNMP Manager On BMC With Non Default Port And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Non_Default_Port_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    ...  ${snmp_manager_id}  Valid

    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Reset SNMP Manager And Object  ${SNMP_DEFAULT_IP}  ${NON_DEFAULT_PORT1}


Configure SNMP Manager On BMC With Out Of Range Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with out-of range port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Out_Of_Range_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port                  Scenario
    ${SNMP_MGR1_IP}    ${out_of_range_port}  ${snmp_manager_id}  error


Configure SNMP Manager On BMC With Alpha Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with alpha port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Alpha_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1_IP}    ${alpha_port}  ${snmp_manager_id}  error


Configure SNMP Manager On BMC With Negative Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with negative port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Negative_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port              Scenario
    ${SNMP_MGR1_IP}    ${negative_port}  ${snmp_manager_id}  error


Configure SNMP Manager On BMC With Empty Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with empty port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Empty_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1_IP}    ${empty_port}  ${snmp_manager_id}  error


Configure SNMP Manager On BMC With Out Of Range IP And Verify
    [Documentation]  Configure SNMP Manager On BMC with out-of range IP and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Out_Of_Range_IP_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP   Port                  Scenario
    ${out_of_range_ip}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}  error


Configure Multiple SNMP Managers And Verify
    [Documentation]  Configure multiple SNMP Managers And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id_1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id_1}

    Reset SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}
    Reset SNMP Manager And Object  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id_1}


Configure Multiple SNMP Managers With Non Default Port And Verify
    [Documentation]  Configure multiple SNMP Managers with non-default port And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Non_Default_Port_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id_1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id_1}

    Reset SNMP Manager And Object  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id}
    Reset SNMP Manager And Object  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id_1}


Configure Multiple SNMP Managers With Different Ports And Verify
    [Documentation]  Configure multiple SNMP Managers with different ports And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Different_Ports_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id_1}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}  ${snmp_manager_id_2}  Valid

    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id_1}
    Verify SNMP Manager  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}  ${snmp_manager_id_2}

    Reset SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}
    Reset SNMP Manager And Object  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  ${snmp_manager_id_1}
    Reset SNMP Manager And Object  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}  ${snmp_manager_id_2}


Generate Error On BMC And Verify If Trap Is Sent
    [Documentation]  Generate Error On BMC And Verify If Trap Is Sent.
    [Tags]  Generate_Error_On_BMC_And_Verify_If_Trap_Is_Sent
    [Template]  Create Error On BMC And Verify If Trap Is Sent

    # event_log                   expected_error
    ${CMD_SEL_LOG_CLEAR}          ${SEL_LOG_CLEAR_EVENT}


Generate Error On BMC And Verify Trap On SNMP
    [Documentation]  Generate error on bmc and verify trap on SNMP.
    [Tags]  Generate_Error_On_BMC_And_Verify_Trap_On_SNMP
    [Template]  Create Error On BMC And Verify If Trap Is Sent

    # event_log                                              expected_error
    ${CMD_TEST_TRAP} ${SNMP_MGR1_IP} ${SNMP_DEFAULT_PORT}    ${SNMP_TEST_TRAP_EVENT}
    ${CMD_SEL_LOG_CLEAR}                                     ${SEL_LOG_CLEAR_EVENT}


Configure SNMP Manager With Less Octet IP And Verify
     [Documentation]  Configure SNMP manager on BMC with less octet IP and verify.
     [Tags]  Configure_SNMP_Manager_With_Less_Octet_IP_And_Verify
     [Template]  Configure SNMP Manager On BMC

     # SNMP manager IP   Port                   Id                    Scenario
     10.10.10            ${SNMP_DEFAULT_PORT}   ${snmp_manager_id}    error


Verify SNMP SysUpTime
    [Documentation]  Verify SNMP SysUpTime.
    [Tags]  Verify_SNMP_SysUpTime

    Generate Error And Verify System Up Time


Verify SNMP SysUpTime On BMC Reboot
    [Documentation]  Verify SNMP SysUpTime on BMC reboot.
    [Tags]  Verify_SNMP_SysUpTime_On_BMC_Reboot

    # Reboot BMC to reset system uptime.
    OBMC Reboot (off)

    ${uptime}=  Generate Error And Verify System Up Time

    # Check if uptime is reset after reboot.
    Should Be True  ${uptime} <= 1  msg=SNMP SysUpTime is not reset on reboot


*** Keywords ***

Create Error On BMC And Verify If Trap Is Sent
    [Documentation]  Generate error on BMC and verify if trap is sent.
    [Arguments]  ${event_log}=${CMD_SEL_LOG_CLEAR}  ${expected_error}=${SEL_LOG_CLEAR_EVENT}

    # Description of argument(s):
    # event_log                           Event logs to be created.
    # expected_error                      Expected error on SNMP.

    Configure SNMP Manager On BMC
    ...  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}  Valid

    Start SNMP Manager
    BMC Execute Command  ${event_log}
    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=15s
    Reset SNMP Manager And Object
    ...  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${snmp_manager_id}
    SSHLibrary.Execute Command  sudo pkill -9 snmptrapd

    ${lines}=  Split To Lines 	 ${SNMP_LISTEN_OUT}
    ${trap_info_line_one}=  Get From List  ${lines}  -2
    Log Many  ${trap_info_line_one}
    ${trap_info_line_two}=  Get From List  ${lines}  -1
    Log Many  ${trap_info_line_two}

    ${snmp_trap_one}=  Split String  ${trap_info_line_one}  \t
    Remove Values From List  ${snmp_trap_one}  ${EMPTY}
    Log Many  ${snmp_trap_one}

    ${snmp_trap_two}=  Split String  ${trap_info_line_two}  \t
    Remove Values From List  ${snmp_trap_two}  ${EMPTY}
    Log Many  ${snmp_trap_two}

    ${snmp_trap}=  Combine Lists  ${snmp_trap_one}  ${snmp_trap_two}

    Log Many  ${snmp_trap}

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

    RETURN  ${snmp_trap}


Generate Error And Verify System Up Time
    [Documentation]  Generate error and verify system up time.

    # Get system uptime on BMC.
    # Example output of uptime:
    # (8055.79 15032.86)

    ${cmd_output}   ${stderr}  ${rc}=  BMC Execute Command  cat /proc/uptime
    @{times}=  Split String  ${cmd_output}

    ${bmc_uptime_in_minutes}=  Evaluate  int(${times}[0])/60

    ${trap}=  Create Error On BMC And Verify If Trap Is Sent

    # Extract System up time from SNMP trap.

    ${timeticks}=  Set Variable  ${trap[0].split(":")[-3:-1]}
    ${hours}=  Convert To Number  ${timeticks[0]}
    ${minutes}=  Convert To Number  ${timeticks[1]}

    # SNMP SysUptime will be in milli seconds.
    # Convert into minutes.
    ${sysuptime_in_minutes}=  Evaluate   int(${hours})*60 + int(${minutes})

    Should Be Equal As Integers  ${bmc_uptime_in_minutes}  ${sysuptime_in_minutes}

    RETURN  ${sysuptime_in_minutes}
