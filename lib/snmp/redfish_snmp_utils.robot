Documentation  Utility for SNMP configurations via Redfish.

*** Settings ***

Resource                ../../lib/utils.robot
Resource                ../../lib/connection_client.robot
Resource                ../../lib/boot_utils.robot
Library                 ../../lib/gen_misc.py
Library                 ../../lib/utils.py


*** Keywords ***

Get SNMP Manager List
    [Documentation]  Get the list of SNMP managers and return IP address and port.

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

    Redfish.Post  ${snmp_uri}  body=&{snmp_mgr_data}
    ...  valid_status_codes=[${valid_status_codes}]


Verify SNMP Manager On BMC
    [Documentation]  Verify SNMP manager on BMC.
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
    @{snmp_mgr_uris}=  Redfish.Get Members List  ${snmp_uri}  filter=snmp

    [Return]  ${snmp_mgr_uris}
