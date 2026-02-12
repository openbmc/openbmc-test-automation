*** Settings ***

Documentation  Protocol settings utilities keywords.

Resource         ../lib/resource.robot
Resource         ../lib/utils.robot


*** Variables ***

${cmd_prefix}    ipmitool -I lanplus -C 17 -p 623 -U ${IPMI_USERNAME} -P ${IPMI_PASSWORD}


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
    [Arguments]  ${host}=${OPENBMC_HOST}
    [Teardown]  Close All Connections

    # Description of argument(s}:
    # host  OPENBMC_HOST, OPENBMC_HOST_1, Use eth0 as the default interface

    # Check if we can open SSH connection and login.
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  host=${host}
    # Check if we can run command successfully on SSH session.
    BMC Execute Command  /sbin/ip addr


Verify SSH Protocol State
    [Documentation]  verify SSH protocol state.
    [Arguments]  ${state}=${True}

    # Description of argument(s}:
    # state  Enable or disable SSH, e.g. (true, false)

    # Sample output:
    # {
    #   "@odata.id": "/redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol",
    #   "@odata.type": "#ManagerNetworkProtocol.v1_5_0.ManagerNetworkProtocol",
    #   "Description": "Manager Network Service",
    #   "FQDN": "bmc",
    #  "HTTP": {
    #    "Port": 0,
    #    "ProtocolEnabled": false
    #  },
    #  "HTTPS": {
    #    "Certificates": {
    #      "@odata.id": "/redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol/HTTPS/Certificates"
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


Enable NTP Protocol
    [Documentation]  Enable or disable NTP protocol.
    [Arguments]  ${enable_value}=${True}

    # Description of argument(s}:
    # enable_value  Enable or disable NTP, e.g. (true, false).

    ${ntp_state}=  Create Dictionary  ProtocolEnabled=${enable_value}
    ${data}=  Create Dictionary  NTP=${ntp_state}

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


Verify NTP Protocol State
    [Documentation]  verify NTP protocol state.
    [Arguments]  ${state}=${True}

    # Description of argument(s}:
    # state  Enable or disable NTP, e.g. (true, false)

    ${resp}=  Redfish.Get  ${REDFISH_NW_PROTOCOL_URI}
    Should Be Equal As Strings  ${resp.dict['NTP']['ProtocolEnabled']}  ${state}
    ...  msg=Protocol states are not matching.


Check SSH Login Via Different Users
    [Documentation]  Check if SSH connection works via different users.
    [Arguments]  ${username}  ${port}  ${host}=${OPENBMC_HOST}

    # Description of argument(s}:
    # username     Username to be used to check login. (e.g. admin or read_only)
    # port         Network port used for SSH login (e.g. 22 or 2200)
    # host         OPENBMC_HOST, OPENBMC_HOST_1, Use eth0 as the default interface

    # Create users with admin & read only privilege.
    Create Users With Different Roles  users=${USERS}  force=${True}

    # Check if we can open SSH connection and login.
    SSHLibrary.Open Connection  ${host}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${username}  ${OPENBMC_PASSWORD}
    ...  ${port}

    IF  '${username}' == 'admin_user' or '${username}' == 'readonly_user'
        Should Be Equal  ${status}  ${False}
        ...  msg=Connection is not allowed to port 22 via admin or readonly user.
    ELSE
        Should Be Equal  ${status}  ${True}
        ...  msg=Connection is allowed & able to login.
    END