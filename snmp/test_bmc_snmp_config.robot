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

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid

    Start SNMP Manager
    BMC Execute Command  /tmp/tarball/bin/logging-test -c AutoTestSimple
    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=1s
    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    SSHLibrary.Execute Command  sudo killall snmptrapd

    Should Contain  ${SNMP_LISTEN_OUT}  ${SNMP_TRAP_BMC_ERROR}
    ...  msg=Failed to receive trap message.

Generate Error On BMC And Verify Trap On SNMP
    [Documentation]  Generate error on bmc and verify trap on SNMP.
    [Tags]  Generate_Error_On_BMC_And_Verify_Verify_Trap_On_SNMP
    [Template]  Create Error On BMC And Verify If Trap Is Sent

     # error_log                  expected_error
     ${CMD_INTERNAL_FAILURE}      ${SNMP_TRAP_BMC_INTERNAL_FAILURE}
     ${CMD_FRU_CALLOUT}           ${SNMP_TRAP_BMC_CALLOUT_ERROR}
     ${CMD_INFORMATIONAL_ERROR}   ${SNMP_TRAP_BMC_INFORMATIONAL_ERROR}

*** Keywords ***

Create Error On BMC And Verify If Trap Is Sent
    [Documentation]  Generate Error On BMC And Verify If Trap Is Sent.
    [Arguments]  ${error_log}  ${expected_error}

    # Description of argument(s):
    # error_log                           Error logs to be created.
    # expected_error                      Expected error on SNMP.

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid

    Start SNMP Manager
    BMC Execute Command  ${error_log}
    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=1s
    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    SSHLibrary.Execute Command  sudo killall snmptrapd

    Should Contain  ${SNMP_LISTEN_OUT}  ${expected_error}
    ...  msg=Failed to receive trap message.

