Documentation  Utility for SNMP configurations via Redfish.

*** Settings ***

Resource                ../../lib/utils.robot
Resource                ../../lib/connection_client.robot
Library                 ../../lib/gen_misc.py
Library                 ../../lib/utils.py

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


*** Keywords ***

Get SNMP Manager List
    [Documentation]  Get the list of SNMP managers and return IP addresses and ports.

    # Get the list of SNMP manager URIs.
    @{snmp_mgr_uris}=  Get SNMP Child URIs

    ${snmp_mgr_list}=  Create List

    FOR  ${snmp_mgr_uri}  IN  @{snmp_mgr_uris}
      # Sample output:
      # {
      #  "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp1",
      #  "@odata.type": "#EventDestination.v1_7_0.EventDestination",
      #  "Context": "",
      #  "Destination": "snmp://xx.xx.xx.xx:162",
      #  "EventFormatType": "Event",
      #  "Id": "snmp1",
      #  "Name": "Event Destination snmp1",
      #  "Protocol": "SNMPv2c",
      #  "SubscriptionType": "SNMPTrap"

      ${resp}=  Redfish.Get  ${snmp_mgr_uri}
      ${snmp_mgr}=  Get From Dictionary  ${resp.dict}  Destination
      Append To List  ${snmp_mgr_list}  ${snmp_mgr}
    END

    [Return]  ${snmp_mgr_list}


Configure SNMP Manager Via Redfish
    [Documentation]  Configure SNMP manager on BMC via Redfish.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}  ${valid_status_codes}=${HTTP_CREATED}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP address
    # snmp_port  SNMP manager port
    # valid_status_code  expected code

    ${snmp_mgr_data}=  Create Dictionary  Destination=snmp://${snmp_mgr_ip}:${snmp_port}
    ...  SubscriptionType=${snmp_function}  Protocol=${snmp_version}

    Redfish.Post  ${subscription_uri}  body=&{snmp_mgr_data}
    ...  valid_status_codes=[${valid_status_codes}]


Verify SNMP Manager Configured On BMC
    [Documentation]  Verify SNMP manager configured on BMC.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP address
    # snmp_port  SNMP manager port

    # Get the list of SNMP managers that are configured on BMC.
    @{snmp_mgr_list}=  Get SNMP Manager List

    ${snmp_ip_port}=  Catenate  ${snmp_mgr_ip}:${snmp_port}

    List Should Contain Value  ${snmp_mgr_list}  snmp://${snmp_ip_port}
    ...  msg=SNMP manager is not configured.


Get SNMP Child URIs
    [Documentation]  Get the list of all SNMP manager URIs.

    # Sample output of SNMP URI:
    # {
    #  "@odata.id": "/redfish/v1/EventService/Subscriptions",
    #  "@odata.type": "#EventDestinationCollection.EventDestinationCollection",
    #  "Members": [
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp6"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp2"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp9"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp1"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp8"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp4"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp7"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp5"
    #    },
    #    {
    #      "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp3"
    #    }
    #  ],
    #  "Members@odata.count": 9,
    #  "Name": "Event Destination Collections"

    # Get the list of child URIs.
    @{snmp_mgr_uris}=  Redfish.Get Members List  ${subscription_uri}  filter=snmp

    [Return]  ${snmp_mgr_uris}


Delete SNMP Manager Via Redfish
    [Documentation]  Delete SNMP manager.
    [Arguments]  ${snmp_mgr_ip}  ${snmp_port}

    # Description of argument(s):
    # snmp_mgr_ip  SNMP manager IP.
    # snmp_port    Network port where SNMP manager is listening.

    ${is_snmp_found}=  Set Variable  ${False}
    ${snmp_ip_port}=  Catenate  ${snmp_mgr_ip}:${snmp_port}

    # Get the list of SNMP manager URIs.
    @{snmp_mgr_uris}=  Get SNMP Child URIs

    # Find the SNMP manager URI that has IP and port configured.
    FOR  ${snmp_mgr_uri}  IN  @{snmp_mgr_uris}
      # Sample output:
      # {
      #  "@odata.id": "/redfish/v1/EventService/Subscriptions/snmp1",
      #  "@odata.type": "#EventDestination.v1_7_0.EventDestination",
      #  "Context": "",
      #  "Destination": "snmp://xx.xx.xx.xx:162",
      #  "EventFormatType": "Event",
      #  "Id": "snmp1",
      #  "Name": "Event Destination snmp1",
      #  "Protocol": "SNMPv2c",
      #  "SubscriptionType": "SNMPTrap"

      # Find the SNMP manager that has matching destination details.
      ${snmp_mgr}=  Redfish.Get Attribute  ${snmp_mgr_uri}  Destination

      # Delete the SNMP manager if the requested IP & ports are found
      # and mark is_snmp_found to true.
      Run Keyword If  'snmp://${snmp_ip_port}' == '${snmp_mgr}'
      ...  Run Keywords  Set Local Variable  ${is_snmp_found}  ${True}
      ...  AND  Redfish.Delete  ${snmp_mgr_uri}
      ...  AND  Exit For Loop
    END

    Pass Execution If  ${is_snmp_found} == ${False}
    ...  SNMP Manager: ${snmp_mgr_ip}:${snmp_port} is not configured on BMC

    # Check if the SNMP manager is really deleted from BMC.
    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${snmp_mgr_ip}  ${snmp_port}

    Should Be Equal  ${status}  ${False}  msg=SNMP manager is not deleted in the backend.


Create Error On BMC And Verify Trap
    [Documentation]  Generate error on BMC and verify if trap is sent.
    [Arguments]  ${event_log}=${CMD_INTERNAL_FAILURE}  ${expected_error}=${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Description of argument(s):
    # event_log       Event logs to be created.
    # expected_error  Expected error on SNMP.

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  ${HTTP_CREATED}

    Start SNMP Manager

    # Generate error log.
    BMC Execute Command  ${event_log}

    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=1s

    Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    # Stop SNMP manager process.
    SSHLibrary.Execute Command  sudo killall snmptrapd

    # Sample SNMP trap:
    # 2021-06-16 07:05:29 xx.xx.xx.xx [UDP: [xx.xx.xx.xx]:58154->[xx.xx.xx.xx]:xxx]:
    # DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (2100473) 5:50:04.73
    #   SNMPv2-MIB::snmpTrapOID.0 = OID: SNMPv2-SMI::enterprises.49871.1.0.0.1
    #  SNMPv2-SMI::enterprises.49871.1.0.1.1 = Gauge32: 369    SNMPv2-SMI::enterprises.49871.1.0.1.2 = Opaque:
    # UInt64: 1397718405502468474     SNMPv2-SMI::enterprises.49871.1.0.1.3 = INTEGER: 3
    #      SNMPv2-SMI::enterprises.49871.1.0.1.4 = STRING: "xxx.xx.xx Failure"

    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}
    ${trap_info}=  Get From List  ${lines}  -1
    ${snmp_trap}=  Split String  ${trap_info}  \t

    Verify SNMP Trap  ${snmp_trap}  ${expected_error}

    [Return]  ${snmp_trap}


Verify SNMP Trap
    [Documentation]  Verify SNMP trap.
    [Arguments]  ${snmp_trap}  ${expected_error}=${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Description of argument(s):
    # snmp_trap       SNMP trap collected on SNMP manager.
    # expected_error  Expected error on SNMP.

    # Verify all the mandatory fields of trap.
    Should Contain  ${snmp_trap}[0]  DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks:
    Should Be Equal  ${snmp_trap}[1]  SNMPv2-MIB::snmpTrapOID.0 = OID: SNMPv2-SMI::enterprises.49871.1.0.0.1
    Should Match Regexp  ${snmp_trap}[2]  SNMPv2-SMI::enterprises.49871.1.0.1.1 = Gauge32: \[0-9]*
    Should Match Regexp  ${snmp_trap}[3]  SNMPv2-SMI::enterprises.49871.1.0.1.2 = Opaque: UInt64: \[0-9]*
    Should Match Regexp  ${snmp_trap}[4]  SNMPv2-SMI::enterprises.49871.1.0.1.3 = INTEGER: \[0-9]
    Should Be Equal  ${snmp_trap}[5]  SNMPv2-SMI::enterprises.49871.1.0.1.4 = STRING: "${expected_error}"


Start SNMP Manager
    [Documentation]  Start SNMP listener on the remote SNMP manager.

    Open Connection And Log In  ${SNMP_MGR1_USERNAME}  ${SNMP_MGR1_PASSWORD}
    ...  alias=snmp_server  host=${SNMP_MGR1_IP}

    # The execution of the SNMP_TRAPD_CMD is necessary to cause SNMP to begin
    # listening to SNMP messages.
    SSHLibrary.write  ${SNMP_TRAPD_CMD} &


Create Error On BMC And Verify Trap On Non-Default Port
    [Documentation]  Generate error on BMC and verify if trap is sent to non default port.
    [Arguments]  ${event_log}=${CMD_INTERNAL_FAILURE}  ${expected_error}=${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Description of argument(s):
    # event_log       Event logs to be created.
    # expected_error  Expected error on SNMP.

    Configure SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Start SNMP Manager On Specific Port  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    # Generate error log.
    BMC Execute Command  ${event_log}

    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=1s

    Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    # Stop SNMP manager process.
    SSHLibrary.Execute Command  sudo killall snmptrapd

    # Sample SNMP trap:
    # 2021-06-16 07:05:29 xx.xx.xx.xx [UDP: [xx.xx.xx.xx]:58154->[xx.xx.xx.xx]:xxx]:
    # DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (2100473) 5:50:04.73
    #   SNMPv2-MIB::snmpTrapOID.0 = OID: SNMPv2-SMI::enterprises.49871.1.0.0.1
    #  SNMPv2-SMI::enterprises.49871.1.0.1.1 = Gauge32: 369    SNMPv2-SMI::enterprises.49871.1.0.1.2 = Opaque:
    # UInt64: 1397718405502468474     SNMPv2-SMI::enterprises.49871.1.0.1.3 = INTEGER: 3
    #      SNMPv2-SMI::enterprises.49871.1.0.1.4 = STRING: "xxx.xx.xx Failure"

    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}
    ${trap_info}=  Get From List  ${lines}  -1
    ${snmp_trap}=  Split String  ${trap_info}  \t

    Verify SNMP Trap  ${snmp_trap}  ${expected_error}

    [Return]  ${snmp_trap}


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
    [Arguments]  ${event_log}=${CMD_INTERNAL_FAILURE}  ${expected_error}=${SNMP_TRAP_BMC_INTERNAL_FAILURE}

    # Description of argument(s):
    # event_log       Event logs to be created.
    # expected_error  Expected error on SNMP.

    Start SNMP Manager

    # Generate error log.
    BMC Execute Command  ${event_log}

    SSHLibrary.Switch Connection  snmp_server
    ${SNMP_LISTEN_OUT}=  Read  delay=1s

    Delete SNMP Manager Via Redfish  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    # Stop SNMP manager process.
    SSHLibrary.Execute Command  sudo killall snmptrapd

    # Sample SNMP trap:
    # 2021-06-16 07:05:29 xx.xx.xx.xx [UDP: [xx.xx.xx.xx]:58154->[xx.xx.xx.xx]:xxx]:
    # DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (2100473) 5:50:04.73
    #   SNMPv2-MIB::snmpTrapOID.0 = OID: SNMPv2-SMI::enterprises.49871.1.0.0.1
    #  SNMPv2-SMI::enterprises.49871.1.0.1.1 = Gauge32: 369    SNMPv2-SMI::enterprises.49871.1.0.1.2 = Opaque:
    # UInt64: 1397718405502468474     SNMPv2-SMI::enterprises.49871.1.0.1.3 = INTEGER: 3
    #      SNMPv2-SMI::enterprises.49871.1.0.1.4 = STRING: "xxx.xx.xx Failure"

    ${lines}=  Split To Lines  ${SNMP_LISTEN_OUT}
    ${trap_info}=  Get From List  ${lines}  -1
    ${snmp_trap}=  Split String  ${trap_info}  \t

    Verify SNMP Trap  ${snmp_trap}  ${expected_error}

    [Return]  ${snmp_trap}

