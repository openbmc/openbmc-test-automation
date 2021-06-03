*** Settings ***
Documentation  This testing requires special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.

Resource  ../lib/snmp/resource.robot
Resource  ../lib/snmp/snmp_utils.robot
Resource  ../lib/openbmc_ffdc.robot
Resource  ../lib/logging_utils.robot

Library  String
Library  SSHLibrary

Test Teardown  FFDC On Test Case Fail

*** Variables ***

${CMD_INTERNAL_FAILURE}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0

${CMD_FRU_CALLOUT}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.Timeout
...  xyz.openbmc_project.Logging.Entry.Level.Error 2 "TIMEOUT_IN_MSEC" "5"
...  "CALLOUT_INVENTORY_PATH" "/xyz/openbmc_project/inventory/system/chassis/motherboard"

${CMD_INFORMATIONAL_ERROR}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.TestError2
...  xyz.openbmc_project.Logging.Entry.Level.Informational 0

${CMD_DEBUG_TRABALL_ERROR}=  /tmp/tarball/bin/logging-test -c AutoTestSimple
${SNMP_TRAP_BMC_INTERNAL_FAILURE}  xyz.openbmc_project.Common.Error.InternalFailure
${SNMP_TRAP_BMC_CALLOUT_ERROR}  xyz.openbmc_project.Common.Error.Timeout
${SNMP_TRAP_BMC_INFORMATIONAL_ERROR}  xyz.openbmc_project.Common.Error.TestError2

*** Test Cases ***
Configure SNMP Manager On BMC And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

Configure SNMP Manager On BMC With Non-default Port And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Non_Default_Port_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

Configure SNMP Manager On BMC With Out Of Range Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with out-of range port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Out_Of_Range_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port                  Scenario
    ${SNMP_MGR1_IP}    ${out_of_range_port}  error

Configure SNMP Manager On BMC With Alpha Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with alpha port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Alpha_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1_IP}    ${alpha_port}  error

Configure SNMP Manager On BMC With Negative Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with negative port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Negative_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port              Scenario
    ${SNMP_MGR1_IP}    ${negative_port}  error

Configure SNMP Manager On BMC With Empty Port And Verify
    [Documentation]  Configure SNMP Manager On BMC with empty port and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Empty_Port_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1_IP}    ${empty_port}  error

Configure SNMP Manager On BMC With Out Of Range IP And Verify
    [Documentation]  Configure SNMP Manager On BMC with out-of range IP and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_With_Out_Of_Range_IP_And_Verify
    [Template]  Configure SNMP Manager On BMC

    # SNMP manager IP   Port                  Scenario
    ${out_of_range_ip}  ${SNMP_DEFAULT_PORT}  error

Configure Multiple SNMP Managers And Verify
    [Documentation]  Configure multiple SNMP Managers And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Delete SNMP Manager And Object  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

Configure Multiple SNMP Managers With Non-default Port And Verify
    [Documentation]  Configure multiple SNMP Managers with non-default port And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Non_Default_Port_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    Delete SNMP Manager And Object  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}

Configure Multiple SNMP Managers With Different Ports And Verify
    [Documentation]  Configure multiple SNMP Managers with different ports And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Different_Ports_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}  Valid

    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    Verify SNMP Manager  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Delete SNMP Manager And Object  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    Delete SNMP Manager And Object  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}

Generate Error On BMC And Verify If Trap Is Sent
    [Documentation]  Generate Error On BMC And Verify If Trap Is Sent.
    [Tags]  Generate_Error_On_BMC_And_Verify_If_Trap_Is_Sent
    [Setup]  Install Tarball
    [Template]  Create Error On BMC And Verify If Trap Is Sent

    # event_log                   expected_error
    ${CMD_DEBUG_TRABALL_ERROR}    ${SNMP_TRAP_BMC_ERROR}

Generate Error On BMC And Verify Trap On SNMP
    [Documentation]  Generate error on bmc and verify trap on SNMP.
    [Tags]  Generate_Error_On_BMC_And_Verify_Trap_On_SNMP
    [Template]  Create Error On BMC And Verify If Trap Is Sent

     # event_log                  expected_error
     ${CMD_INTERNAL_FAILURE}      ${SNMP_TRAP_BMC_INTERNAL_FAILURE}
     ${CMD_FRU_CALLOUT}           ${SNMP_TRAP_BMC_CALLOUT_ERROR}
     ${CMD_INFORMATIONAL_ERROR}   ${SNMP_TRAP_BMC_INFORMATIONAL_ERROR}

Configure SNMP Manager With Less Octet IP And Verify
     [Documentation]  Configure SNMP manager on BMC with less octet IP and verify.
     [Tags]  Configure_SNMP_Manager_With_Less_Octet_IP_And_Verify
     [Template]  Configure SNMP Manager On BMC

     # SNMP manager IP   Port                  Scenario
     10.10.10            ${SNMP_DEFAULT_PORT}  error

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
    [Arguments]  ${event_log}=${CMD_INTERNAL_FAILURE}  ${expected_error}=${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Description of argument(s):
    # event_log                           Event logs to be created.
    # expected_error                      Expected error on SNMP.

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid

    Start SNMP Manager
    BMC Execute Command  ${event_log}
    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=1s
    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    SSHLibrary.Execute Command  sudo killall snmptrapd
    ${lines} =  Split To Lines 	 ${SNMP_LISTEN_OUT}
    ${trap_info}=  Get From List  ${lines}  -1
    ${SNMP_TRAP} =  Split String  ${trap_info}  \t

    Should Contain  ${SNMP_TRAP}[0]  DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks:
    Should Be Equal  ${SNMP_TRAP}[1]  SNMPv2-MIB::snmpTrapOID.0 = OID: SNMPv2-SMI::enterprises.49871.1.0.0.1
    Should Match Regexp  ${SNMP_TRAP}[2]  SNMPv2-SMI::enterprises.49871.1.0.1.1 = Gauge32: \[0-9]*
    Should Match Regexp  ${SNMP_TRAP}[3]  SNMPv2-SMI::enterprises.49871.1.0.1.2 = Opaque: UInt64: \[0-9]*
    Should Match Regexp  ${SNMP_TRAP}[4]  SNMPv2-SMI::enterprises.49871.1.0.1.3 = INTEGER: \[0-9]
    Should Be Equal  ${SNMP_TRAP}[5]  SNMPv2-SMI::enterprises.49871.1.0.1.4 = STRING: "${expected_error}"

    [Return]  ${SNMP_TRAP}


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
