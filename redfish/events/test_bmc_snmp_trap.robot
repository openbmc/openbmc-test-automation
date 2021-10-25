*** Settings ***
Documentation  This testing requires special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.


Resource      ../../lib/snmp/resource.robot
Resource      ../../lib/snmp/redfish_snmp_utils.robot
Resource      ../../lib/bmc_redfish_resource.robot
Resource      ../../lib/openbmc_ffdc.robot
Resource      ../../lib/logging_utils.robot


Test Teardown  FFDC On Test Case Fail
Suite Setup    Suite Setup Execution


*** Test Cases ***

Configure SNMP Manager On BMC And Verify
    [Documentation]  Configure SNMP manager on BMC via Redfish and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${HTTP_CREATED}

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}


Configure SNMP Manager On BMC With Non-default Port And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Non_Default_Port_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  ${HTTP_CREATED}

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}


Configure SNMP Manager On BMC With Out Of Range Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with out-of range port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Out_Of_Range_Port_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${out_of_range_port}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${out_of_range_port}  ${HTTP_BAD_REQUEST}

    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${out_of_range_port}

    Should Be Equal As Strings  ${status}  False
    ...  msg=BMC is allowing to configure out of range port.


Generate Error On BMC And Verify SNMP Trap
    [Documentation]  Generate error on BMC and verify trap and its fields.
    [Tags]  Generate_Error_On_BMC_And_Verify_SNMP_Trap
    [Template]  Create Error On BMC And Verify Trap

    # event_log                 expected_error

    # Generate internal failure error.
    ${CMD_INTERNAL_FAILURE}     ${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Generate timeout error.
    ${CMD_FRU_CALLOUT}          ${SNMP_TRAP_BMC_CALLOUT_ERROR}

    # Generate informational error.
    ${CMD_INFORMATIONAL_ERROR}  ${SNMP_TRAP_BMC_INFORMATIONAL_ERROR}


Configure SNMP Manager On BMC With Alpha Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with alpha port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Alpha_Port_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${alpha_port}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${alpha_port}  ${HTTP_BAD_REQUEST}

    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${alpha_port}

    Should Be Equal As Strings  ${status}  False
    ...  msg=BMC is allowing to configure invalid port.


Configure SNMP Manager On BMC With Empty Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with empty port and verify
    ...  SNMP manager gets configured with default port.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Empty_Port_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${empty_port}

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}


Configure Multiple SNMP Managers And Verify
    [Documentation]  Configure multiple SNMP managers and verify.
    [Tags]  Configure_Multiple_SNMP_Managers_And_Verify
    [Teardown]  Run Keywords
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    ...  AND
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Configure SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}


Generate Error On BMC And Verify SNMP Trap Is Sent To Non-Default Port
    [Documentation]  Generate error on BMC and verify trap and its fields.
    [Tags]  Generate_Error_On_BMC_And_Verify_SNMP_Trap_Is_Sent_To_Non-Default_Port
    [Template]  Create Error On BMC And Verify Trap On Non-Default Port

    # event_log                 expected_error

    # Generate internal failure error.
    ${CMD_INTERNAL_FAILURE}     ${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Generate timeout error.
    ${CMD_FRU_CALLOUT}          ${SNMP_TRAP_BMC_CALLOUT_ERROR}

    # Generate informational error.
    ${CMD_INFORMATIONAL_ERROR}  ${SNMP_TRAP_BMC_INFORMATIONAL_ERROR}


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


Configure Multiple SNMP Managers With Non-default Port And Verify
    [Documentation]  Configure multiple SNMP Managers with non-default port And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Non_Default_Port_And_Verify
    [Teardown]  Run Keywords
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    ...  AND
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}

    # Configure multiple SNMP managers with non-default port.
    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    Configure SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}

    # Verify if SNMP managers are configured.
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}


Configure Multiple SNMP Managers With Different Ports And Verify
    [Documentation]  Configure multiple SNMP Managers with different ports And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Different_Ports_And_Verify
    [Teardown]  Run Keywords
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    ...  AND
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    ...  AND
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}

    # Configure multiple SNMP managers with different ports.
    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Configure SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    Configure SNMP Manager Via Redfish  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}

    # Verify if SNMP managers are configured.
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}


Configure SNMP Manager With Out Of Range IP On BMC And Verify
    [Documentation]  Configure SNMP Manager On BMC with out-of range IP and expect an error.
    [Tags]  Configure_SNMP_Manager_With_Out_Of_Range_IP_On_BMC_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${out_of_range_ip}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${out_of_range_ip}  ${SNMP_DEFAULT_PORT}  ${HTTP_BAD_REQUEST}

    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${out_of_range_ip}  ${SNMP_DEFAULT_PORT}

    Should Be Equal As Strings  ${status}  False
    ...  msg=BMC is allowing to configure out of range IP.


Verify Persistency Of SNMP Manager And Trap On BMC Reboot
    [Documentation]  Verify persistency of SNMP manager configuration on BMC
    ...  and BMC is able to send trap after reboot.
    [Tags]  Verify_Persistency_Of_SNMP_Manager_And_Trap_On_BMC_Reboot
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${HTTP_CREATED}

    # Reboot BMC and check persistency SNMP manager.
    OBMC Reboot (off)

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    # Check if trap is generated and sent to SNMP manager after reboot.
    Generate Error On BMC And Verify Trap
    ...  ${CMD_INTERNAL_FAILURE}  ${SNMP_TRAP_BMC_INTERNAL_FAILURE}


Configure SNMP Manager With Less Octet IP And Verify
    [Documentation]  Configure SNMP manager on BMC with less octet IP and expect an error.
    [Tags]  Configure_SNMP_Manager_With_Less_Octet_IP_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${less_octet_ip}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${less_octet_ip}  ${SNMP_DEFAULT_PORT}  ${HTTP_BAD_REQUEST}

    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${less_octet_ip}  ${SNMP_DEFAULT_PORT}

    Should Be Equal As Strings  ${status}  False
    ...  msg=BMC is allowing to configure less octet IP.


Configure SNMP Manager On BMC With Negative Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with negative port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Negative_Port_And_Verify

    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${negative_port}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${negative_port}  ${HTTP_BAD_REQUEST}

    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${negative_port}

    Should Be Equal As Strings  ${status}  False
    ...  msg=BMC is allowing to configure negative port.


Configure Multiple SNMP Managers On BMC And Verify Persistency On BMC Reboot
    [Documentation]  Configure multiple SNMP Managers on BMC and verify persistency on BMC reboot.
    [Tags]  Configure_Multiple_SNMP_Managers_On_BMC_And_Verify_Persistency_On_BMC_Reboot
    [Teardown]  Run Keywords
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    ...  AND
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Configure SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    # Reboot BMC and check persistency SNMP manager.
    OBMC Reboot (off)

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}


Configure Multiple SNMP Managers On BMC And Check Trap On BMC Reboot
    [Documentation]  Configure multiple SNMP Managers on BMC and check trap on BMC reboot.
    [Tags]  Configure_Multiple_SNMP_Managers_On_BMC_And_Check_Trap_On_BMC_Reboot
    [Teardown]  Run Keywords
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    ...  AND
    ...  Delete SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Configure SNMP Manager Via Redfish  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    # Reboot BMC and check persistency SNMP manager.
    OBMC Reboot (off)

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    # Check if trap is generated and sent to SNMP managers after reboot.
    Generate Error On BMC And Verify Trap
    ...  ${CMD_INTERNAL_FAILURE}  ${SNMP_TRAP_BMC_INTERNAL_FAILURE}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login

    # Check for SNMP configurations.
    Valid Value  SNMP_MGR1_IP
    Valid Value  SNMP_DEFAULT_PORT


Generate Error And Verify System Up Time
    [Documentation]  Generate error and verify system up time.

    # Get system uptime on BMC.
    # Example output of uptime:
    # (8055.79 15032.86)

    ${cmd_output}   ${stderr}  ${rc}=  BMC Execute Command  cat /proc/uptime
    @{times}=  Split String  ${cmd_output}

    ${bmc_uptime_in_minutes}=  Evaluate  int(${times}[0])/60

    ${trap}=  Create Error On BMC And Verify Trap

    # Extract System up time from SNMP trap.
    # Example - SNMP trap:
    # DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (252367) 0:42:03.67
    # SNMPv2-MIB::snmpTrapOID.0 = OID: SNMPv2-SMI::enterprises.49871.1.0.0.1
    # SNMPv2-SMI::enterprises.49871.1.0.1.1 = Gauge32: 54
    # SNMPv2-SMI::enterprises.49871.1.0.1.2 = Opaque: UInt64: 4622921648578756984
    # SNMPv2-SMI::enterprises.49871.1.0.1.3 = INTEGER: 3
    # SNMPv2-SMI::enterprises.49871.1.0.1.4 = STRING:

    @{words}=  Split String  ${trap}[0]  =

    ${timeticks}=  Fetch From Right  ${words}[1]  (
    ${snmp_sysuptime}=  Fetch From Left  ${timeticks}  )

    # SNMP SysUptime will be in milli seconds.
    # Convert into minutes.
    ${sysuptime_in_minutes}=  Evaluate  int(${snmp_sysuptime})/6000

    Should Be Equal As Integers  ${bmc_uptime_in_minutes}  ${sysuptime_in_minutes}

    [Return]  ${sysuptime_in_minutes}
