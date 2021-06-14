Documentation  Utility for SNMP configurations via Redfish.

*** Settings ***

Resource                ../../lib/utils.robot
Resource                ../../lib/connection_client.robot
Library                 ../../lib/gen_misc.py
Library                 ../../lib/utils.py


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
    # snmp_port     Network port where SNMP manager is listening.

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
      ${resp}=  Redfish.Get  ${snmp_mgr_uri}
      ${snmp_mgr}=  Get From Dictionary  ${resp.dict}  Destination

      # Delete the SNMP manager if the requested IP & ports are found
      # and mark is_snmp_found to true.
      Run Keyword If  'snmp://${snmp_ip_port}' == '${snmp_mgr}'
      ...  Run Keywords  Set Local Variable  ${is_snmp_found}  ${True}
      ...  AND  Redfish.Delete  ${snmp_mgr_uri}
    END

    Pass Execution If  ${is_snmp_found} == ${False}
    ...  SNMP Manager: ${snmp_mgr_ip}:${snmp_port} is not configured on BMC

    # Check if the SNMP manager is really deleted from BMC.
    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${snmp_mgr_ip}  ${snmp_port}

    Should Be Equal  ${status}  ${False}  msg=SNMP manager is not deleted in the backend.
