*** Settings ***
Documentation  This testing requires special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.


Resource  ../../lib/snmp/resource.robot
Resource  ../../lib/snmp/redfish_snmp_utils.robot
Resource  ../../lib/bmc_redfish_resource.robot
Resource  ../../lib/openbmc_ffdc.robot
Resource  ../../lib/bmc_redfish_resource.robot
Resource  ../../lib/openbmc_ffdc.robot
Resource  ../../lib/logging_utils.robot


Test Teardown  FFDC On Test Case Fail
Suite Setup    Suite Setup Execution

*** Variables ***

${snmp_function}     SNMPTrap
${snmp_version}      SNMPv2c
${subscription_uri}  /redfish/v1/EventService/Subscriptions


*** Test Cases ***

Configure SNMP Manager On BMC And Verify
    [Documentation]  Configure SNMP manager on BMC via Redfish and verify.
    [Tags]  Configure_SNMP_Manager_On_BMC_And_Verify
    [Teardown]  Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${HTTP_CREATED}

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login

    # Check for SNMP configurations.
    Valid Value  SNMP_MGR1_IP
    Valid Value  SNMP_DEFAULT_PORT
