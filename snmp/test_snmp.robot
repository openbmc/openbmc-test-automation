*** Settings ***
Documentation  This testing require special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.

Resource  ../lib/snmp/resource.txt
Resource  ../lib/snmp/snmp_utils.robot

Library  String
Library  SSHLibrary

*** Test Cases ***
Configure SNMP Manager And Verify
    [Documentation]  Configure SNMP Manager And Verify.
    [Tags]  Configure_SNMP_Manager_And_Verify

    Configure SNMP Manager  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}  Valid
    Verify SNMP Manager  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}

    Delete SNMP Manager And Object  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}

Configure SNMP Manager With Non-default Port And Verify
    [Documentation]  Configure SNMP Manager And Verify.
    [Tags]  Configure_SNMP_Manager_And_Verify

    Configure SNMP Manager  ${SNMP_MGR1}  ${NON_DFLT_PORT1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1}  ${NON_DFLT_PORT1}

    Delete SNMP Manager And Object  ${SNMP_MGR1}  ${NON_DFLT_PORT1}

Configure SNMP Manager With Outof_Range Port And Verify
    # SNMP manager IP  Port                 Scenario
    ${SNMP_MGR1}       ${outof_range_port}  error
    [Documentation]  Configure SNMP Manager with out-of range port and verify.
    [Tags]  Configure_SNMP_Manager_With_Outof_Range_Port_And_Verify

    [Template]  Configure SNMP Manager

Configure SNMP Manager With Alpha Port And Verify
    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1}       ${alpha_port}  error
    [Documentation]  Configure SNMP Manager with alpha port and verify.
    [Tags]  Configure_SNMP_Manager_With_Alpha_Port_And_Verify

    [Template]  Configure SNMP Manager

Configure SNMP Manager With Negative Port And Verify
    # SNMP manager IP  Port              Scenario
    ${SNMP_MGR1}       ${negative_port}  error
    [Documentation]  Configure SNMP Manager with negative port and verify.
    [Tags]  Configure_SNMP_Manager_With_Negative_Port_And_Verify

    [Template]  Configure SNMP Manager

Configure SNMP Manager With Empty Port And Verify
    # SNMP manager IP  Port           Scenario
    ${SNMP_MGR1}       ${empty_port}  error
    [Documentation]  Configure SNMP Manager with empty port and verify.
    [Tags]  Configure_SNMP_Manager_With_Empty_Port_And_Verify

    [Template]  Configure SNMP Manager

Configure SNMP Manager With Outof_Range IP And Verify
    # SNMP manager IP  Port               Scenario
    ${outof_range_ip}  ${SNMP_DFLT_PORT}  error
    [Documentation]  Configure SNMP Manager with out-of range IP and verify.
    [Tags]  Configure_SNMP_Manager_With_Empty_Port_And_Verify

    [Template]  Configure SNMP Manager

Configure Multiple SNMP Managers And Verify
    [Documentation]  Configure multiple SNMP Managers And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_And_Verify

    Configure SNMP Manager  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}  Valid
    Configure SNMP Manager  ${SNMP_MGR2}  ${SNMP_DFLT_PORT}  Valid
    Verify SNMP Manager  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}
    Verify SNMP Manager  ${SNMP_MGR2}  ${SNMP_DFLT_PORT}

    Delete SNMP Manager And Object  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}
    Delete SNMP Manager And Object  ${SNMP_MGR2}  ${SNMP_DFLT_PORT}

Configure Multiple SNMP Managers With Non-default Port And Verify
    [Documentation]  Configure multiple SNMP Managers with non-default port And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_And_Verify

    Configure SNMP Manager  ${SNMP_MGR1}  ${NON_DFLT_PORT1}  Valid
    Configure SNMP Manager  ${SNMP_MGR2}  ${NON_DFLT_PORT1}  Valid
    Verify SNMP Manager  ${SNMP_MGR1}  ${NON_DFLT_PORT1}
    Verify SNMP Manager  ${SNMP_MGR2}  ${NON_DFLT_PORT1}

    Delete SNMP Manager And Object  ${SNMP_MGR1}  ${NON_DFLT_PORT1}
    Delete SNMP Manager And Object  ${SNMP_MGR2}  ${NON_DFLT_PORT1}

Configure Multiple SNMP Managers With Different Ports And Verify
    [Documentation]  Configure multiple SNMP Managers with different ports And Verify.
    [Tags]  Configure_Multiple_SNMP_Managers_With_Different_Ports_And__Verify

    Configure SNMP Manager  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}  Valid
    Configure SNMP Manager  ${SNMP_MGR2}  ${NON_DFLT_PORT1}  Valid
    Configure SNMP Manager  ${SNMP_MGR3}  ${NON_DFLT_PORT2}  Valid

    Verify SNMP Manager  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}
    Verify SNMP Manager  ${SNMP_MGR2}  ${NON_DFLT_PORT1}
    Verify SNMP Manager  ${SNMP_MGR3}  ${NON_DFLT_PORT2}

    Delete SNMP Manager And Object  ${SNMP_MGR1}  ${SNMP_DFLT_PORT}
    Delete SNMP Manager And Object  ${SNMP_MGR2}  ${NON_DFLT_PORT1}
    Delete SNMP Manager And Object  ${SNMP_MGR3}  ${NON_DFLT_PORT2}

