*** Settings ***
Documentation  Test BMC manager protocol enable/disable functionality.

Resource   ../../lib/resource.robot
Resource   ../../lib/bmc_redfish_resource.robot
Resource   ../../lib/openbmc_ffdc.robot

Suite Setup    Redfish.Login
Test Teardown  FFDC On Test Case Fail


*** Test Cases ***

Enable SSH Protocol And Verify
    [Documentation]  Enable SSH protocol and verify.
    [Tags]  Enable_SSH_Protocol_And_Verify

    Enable SSH Protocol  ${True}

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State  ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work


Disable SSH Protocol And Verify
    [Documentation]  Disable SSH protocol and verify.
    [Teardown]  Enable SSH Protocol  ${True}

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State  ${False}

    # Check if SSH login and commands fail.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.


Enable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]  Enable SSH protocol and verify persistency.

    Enable SSH Protocol  ${True}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State  ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work


Disable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]  Disable SSH protocol and verify persistency.
    [Teardown]  Enable SSH Protocol  ${True}

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State  ${False}

    # Check if SSH login and commands fail.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.


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
    # }

    ${resp}=  Redfish.Get  ${REDFISH_NW_PROTOCOL_URI}
    Should Be Equal As Strings  ${resp.dict['SSH']['ProtocolEnabled']}  ${state}
    ...  msg=Protocol states are not matching.
