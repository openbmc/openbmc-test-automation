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


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login

    # Check for SNMP configurations.
    Valid Value  SNMP_MGR1_IP
    Valid Value  SNMP_DEFAULT_PORT
