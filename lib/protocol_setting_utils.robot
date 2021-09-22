*** Settings ***

Documentation  Protocol settings utilities keywords.

Resource         ../lib/resource.robot
Resource         ../lib/utils.robot


*** Keywords ***

Enable SSH Protocol
    [Documentation]  Enable or disable SSH protocol.
    [Arguments]  ${enable_value}=${True}

    # Description of argument(s}:
    # enable_value  Enable or disable SSH, e.g. (true, false).

    ${ssh_state}=  Create Dictionary  ProtocolEnabled=${enable_value}
    ${data}=  Create Dictionary  SSH=${ssh_state}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for timeout for new values to take effect.
    Sleep  ${NETWORK_TIMEOUT}s


Verify SSH Login And Commands Work
    [Documentation]  Verify if SSH connection works and able to run command on SSH session.
    [Teardown]  Close All Connections

    # Check if we can open SSH connection and login.
    Open Connection And Login

    # Check if we can run command successfully on SSH session.
    BMC Execute Command  /sbin/ip addr


Verify SSH Protocol State
    [Documentation]  verify SSH protocol state.
    [Arguments]  ${state}=${True}

    # Description of argument(s}:
    # state  Enable or disable SSH, e.g. (true, false)

    # Sample output:
    # {
    #   "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol",
    #   "@odata.type": "#ManagerNetworkProtocol.v1_5_0.ManagerNetworkProtocol",
    #   "Description": "Manager Network Service",
    #   "FQDN": "bmc",
    #  "HTTP": {
    #    "Port": 0,
    #    "ProtocolEnabled": false
    #  },
    #  "HTTPS": {
    #    "Certificates": {
    #      "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates"
    #    },
    #    "Port": xxx,
    #    "ProtocolEnabled": true
    #  },
    #  "HostName": "xxxxbmc",
    #  "IPMI": {
    #    "Port": xxx,
    #    "ProtocolEnabled": true
    #  },
    #  "Id": "NetworkProtocol",
    #  "NTP": {
    #    "NTPServers": [
    #      "xx.xx.xx.xx",
    #      "xx.xx.xx.xx",
    #      "xx.xx.xx.xx"
    #    ],
    #    "ProtocolEnabled": true
    #  },
    #  "Name": "Manager Network Protocol",
    #  "SSH": {
    #    "Port": xx,
    #    "ProtocolEnabled": true
    #  },
    #  "Status": {
    #    "Health": "OK",
    #    "HealthRollup": "OK",
    #    "State": "Enabled"
    #  }

    ${resp}=  Redfish.Get  ${REDFISH_NW_PROTOCOL_URI}
    Should Be Equal As Strings  ${resp.dict['SSH']['ProtocolEnabled']}  ${state}
    ...  msg=Protocol states are not matching.


Enable IPMI Protocol
    [Documentation]  Enable or disable IPMI protocol.
    [Arguments]  ${enable_value}=${True}

    # Description of argument(s}:
    # enable_value  Enable or disable IPMI, e.g. (true, false).

    ${ipmi_state}=  Create Dictionary  ProtocolEnabled=${enable_value}
    ${data}=  Create Dictionary  IPMI=${ipmi_state}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for timeout for new values to take effect.
    Sleep  ${NETWORK_TIMEOUT}s


Verify IPMI Works
    [Documentation]  Run IPMI command and return status.
    [Arguments]  ${sub_cmd}  ${host}=${OPENBMC_HOST}

    # Description of argument(s):
    # host         BMC host name or IP address.
    # sub_cmd      The IPMI command string to be executed.

    ${rc}=  Run And Return Rc  ${cmd_prefix} -H ${host} ${sub_cmd}
    Should Be Equal As Strings  ${rc}  0
    ...  msg=IPMI is not enabled and commands are failing.


Verify IPMI Protocol State
    [Documentation]  Verify IPMI protocol state.
    [Arguments]  ${state}=${True}

    # Description of argument(s}:
    # state  Enable or disable IPMI, e.g. (true, false)

    ${resp}=  Redfish.Get  ${REDFISH_NW_PROTOCOL_URI}
    Should Be Equal As Strings  ${resp.dict['IPMI']['ProtocolEnabled']}  ${state}
    ...  msg=Protocol states are not matching.


