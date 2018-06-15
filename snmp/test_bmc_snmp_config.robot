*** Settings ***
Documentation  This testing require special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.

Resource  ../lib/snmp/resource.txt
Resource  ../lib/snmp/snmp_utils.robot

Library  String
Library  SSHLibrary

*** Test Cases ***
Configure SNMP Manager On BMC And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

Configure SNMP Manager On BMC With Non-default Port And Verify
    [Documentation]  Configure SNMP Manager On BMC And Verify.
    [Tags]  Configure_SNMP_Manager_With_Non_Default_Port_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

Configure SNMP Manager On BMC With Out Of Range Port And Verify
    # SNMP manager IP  Port                  Scenario
    ${SNMP_MGR1_IP}    ${out_of_range_port}  error
    [Documentation]  Configure SNMP Manager On BMC with out-of range port and verify.
    [Tags]  Configure_SNMP_Manager_With_Out Of_Range_Port_On_BMC_And_Verify

    [Template]  Configure SNMP Manager On BMC

Configure SNMP Manager On BMC With Alpha Port And Verify
    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1_IP}    ${alpha_port}  error
    [Documentation]  Configure SNMP Manager On BMC with alpha port and verify.
    [Tags]  Configure_SNMP_Manager_With_Alpha_Port_On_BMC_And_Verify

    [Template]  Configure SNMP Manager On BMC

Configure SNMP Manager On BMC With Negative Port And Verify
    # SNMP manager IP  Port              Scenario
    ${SNMP_MGR1_IP}    ${negative_port}  error
    [Documentation]  Configure SNMP Manager On BMC with negative port and verify.
    [Tags]  Configure_SNMP_Manager_With_Negative_Port_On_BMC_And_Verify

    [Template]  Configure SNMP Manager On BMC

Configure SNMP Manager On BMC With Empty Port And Verify
    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1_IP}    ${empty_port}  error
    [Documentation]  Configure SNMP Manager On BMC with empty port and verify.
    [Tags]  Configure_SNMP_Manager_With_Empty_Port_On_BMC_And_Verify

    [Template]  Configure SNMP Manager On BMC

Configure SNMP Manager On BMC With Out Of Range IP And Verify
    # SNMP manager IP   Port                  Scenario
    ${out_of_range_ip}  ${SNMP_DEFAULT_PORT}  error
    [Documentation]  Configure SNMP Manager On BMC with out-of range IP and verify.
    [Tags]  Configure_SNMP_Manager_With_Out Of_Range_IP_On_BMC_And_Verify

    [Template]  Configure SNMP Manager On BMC

Configure Multiple SNMP Managers And Verify
    [Documentation]  Configure multiple SNMP Managers And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_On_BMC_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Delete SNMP Manager And Object  ${SNMP_MGR2_IP}  ${SNMP_DEFAULT_PORT}

Configure Multiple SNMP Managers With Non-default Port And Verify
    [Documentation]  Configure multiple SNMP Managers with non-default port And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Non_Default_Port_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}
    Delete SNMP Manager And Object  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}

Configure Multiple SNMP Managers With Different Ports And Verify
    [Documentation]  Configure multiple SNMP Managers with different ports And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Different_Ports_On_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}  Valid
    Configure SNMP Manager On BMC  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}  Valid

    Verify SNMP Manager  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Verify SNMP Manager  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    Verify SNMP Manager  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}

    Delete SNMP Manager And Object  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}
    Delete SNMP Manager And Object  ${SNMP_MGR2_IP}  ${NON_DEFAULT_PORT1}
    Delete SNMP Manager And Object  ${SNMP_MGR3_IP}  ${NON_DEFAULT_PORT2}

