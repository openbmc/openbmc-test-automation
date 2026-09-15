<<<<<<< PATCH SET (8b64a7 ast2600evb_rpi: added BIOS Settings tests with ast2600evb + )
*** Settings ***
Documentation  Common resource file for inband test suite.
...
...  Provides shared variables for EVB+RPI test environment.
...  BMC credentials reuse the standard framework variables:
...  ${OPENBMC_HOST}  - BMC IP address (passed at runtime via --variable)
...  ${OPENBMC_USERNAME}  - BMC SSH/Redfish username (default: root)
...  ${OPENBMC_PASSWORD}  - BMC SSH/Redfish password (default: 0penBmc)

Library  SSHLibrary
Library  Collections
Library  String
Library  OperatingSystem
Library  RequestsLibrary
Library  JSONLibrary

Resource   ../../lib/bmc_redfish_resource.robot
Resource   ../../lib/common_utils.robot
Resource   ../../gui/lib/gui_resource.robot
Variables  ../../data/variables.py
Variables  ../../data/ipmi_raw_cmd_table.py

*** Variables ***
# RPI / SoC Host connection.
${HOST_IP}         ${OS_HOST}
${HOST_USERNAME}   ${OS_USERNAME}
${HOST_PASSWORD}   ${OS_PASSWORD}
# iperf3 parameters.
${IPERF_DURATION}  30
${IPERF_PARALLEL}  4
${IPERF_TIMEOUT}   60
# ping parameters.
${PING_COUNT}      1000
${PING_INTERVAL}   0.01
${PING_TIMEOUT}    60
# Timing.
${BMC_RESET_WAIT}  120s

*** Keywords ***

SSH Open Connection
    [Documentation]  Open an SSH connection to the given host and log in.
    ...  Returns the SSHLibrary connection index so callers can use
    ...  Switch Connection when managing multiple simultaneous connections.
    [Arguments]  ${host}  ${user}  ${password}

    # Description of argument(s):.
    # host      The hostname or IP address to connect to.
    # user      The SSH username for login.
    # password  The SSH password for login.

    ${conn_idx}=  SSHLibrary.Open Connection  ${host}
    SSHLibrary.Login  ${user}  ${password}
    Sleep  1s
    RETURN  ${conn_idx}


Get Host Interface JSON
    [Documentation]  GET the HostInterfaces/RHI endpoint on BMC via Redfish library and
    ...  return the response dictionary. Requires an active Redfish session.

    ${resp}=  Redfish.Get  ${HOST_INTERFACE_URI}
    RETURN  ${resp.dict}


Set And Verify Credential Bootstrapping
    [Documentation]  PATCH Credential Bootstrapping fields on the HostInterface and immediately
    ...  verify the GET response reflects the requested values.
    ...  Only fields explicitly passed (not ${None}) are set and verified.
    ...
    ...  Examples:
    ...  Set And Verify Credential Bootstrapping  enabled=${True}
    ...  Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${True}
    ...  Set And Verify Credential Bootstrapping  enabled=${True}  enable_after_reset=${True}
    [Arguments]  ${enabled}=${None}  ${enable_after_reset}=${None}

    # Description of argument(s):.
    # enabled             Enable or disable Credential Bootstrapping (${True}/${False}/${None} to skip).
    # enable_after_reset  Re-enable Credential Bootstrapping after BMC reset (${True}/${False}/${None} to skip).

    # Build Credential Bootstrapping payload dict from provided arguments.
    VAR  &{cb}
    IF  $enabled is not None
      Set To Dictionary  ${cb}  Enabled=${enabled}
    END
    IF  $enable_after_reset is not None
      Set To Dictionary  ${cb}  EnableAfterReset=${enable_after_reset}
    END
    VAR  &{payload}  CredentialBootstrapping=${cb}
    Redfish.Patch  ${HOST_INTERFACE_URI}  body=${payload}
    # Verify the patched values via GET.
    ${json}=  Get Host Interface JSON
    IF  $enabled is not None
      Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${enabled}
    END
    IF  $enable_after_reset is not None
      Should Be Equal  ${json['CredentialBootstrapping']['EnableAfterReset']}  ${enable_after_reset}
    END


BMC Force Restart
    [Documentation]  Trigger a BMC Force Restart via Redfish Manager.Reset action.
    ...  Requires an active Redfish session.

    VAR  &{payload}  ResetType=ForceRestart
    Redfish.Post  ${MANAGER_RESET_URI}  body=${payload}
    ...  valid_status_codes=[200, 204]


BMC Graceful Restart
    [Documentation]  Trigger a BMC Graceful Restart via Redfish Manager.Reset action.
    ...  Requires an active Redfish session.

    VAR  &{payload}  ResetType=GracefulRestart
    Redfish.Post  ${MANAGER_RESET_URI}  body=${payload}
    ...  valid_status_codes=[200, 204]


Get USB Ethernet IPs
    [Documentation]  Query the BMC and host for their USB Ethernet (usb0) interface IP
    ...  addresses at runtime and store them as suite variables.
    ...  ${BMC_USB_ETH_IP}  - IP of usb0 on the BMC  (e.g. 169.254.100.100)
    ...  ${HOST_USB_ETH_IP} - IP of usb0 on the host (e.g. 169.254.100.103)
    ...  If the host usb0 interface is not yet configured, the host IP is derived
    ...  from the BMC IP (same /16 subnet, last octet + 3) and the interface is
    ...  configured automatically via SSH.
    ...  Called from Suite Setup so the values are available to all test cases.

    # Query BMC usb0 IP via SSH.
    SSH Open Connection  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${bmc_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    Close All Connections
    ${bmc_usb_ip}=  Strip String  ${bmc_raw}
    VAR  ${BMC_USB_ETH_IP}  ${bmc_usb_ip}  scope=SUITE
    # Query host usb0 IP via SSH.
    SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    ${host_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    ${host_usb_ip}=  Strip String  ${host_raw}
    IF  '${host_usb_ip}' == '${EMPTY}'
        # Derive host IP from BMC IP: same /16 subnet, last octet + 3.
        ${bmc_parts}=  Split String  ${BMC_USB_ETH_IP}  .
        ${host_usb_ip}=  Evaluate
        ...  '.'.join($bmc_parts[:3]) + '.' + str(int($bmc_parts[-1]) + 3)
        Log  Host usb0 not configured - derived IP: ${host_usb_ip}
        # Configure the host usb0 interface.
        Execute Command  sudo ip addr add ${host_usb_ip}/16 dev usb0
        Execute Command  sudo ip link set usb0 up
        # Confirm the IP was applied successfully.
        ${confirm_raw}=  Execute Command
        ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
        ${confirmed_ip}=  Strip String  ${confirm_raw}
        Should Be Equal As Strings  ${confirmed_ip}  ${host_usb_ip}
        Log  Host usb0 confirmed with IP: ${confirmed_ip}
    END
    Close All Connections
    VAR  ${HOST_USB_ETH_IP}  ${host_usb_ip}  scope=SUITE
    Log  BMC USB Ethernet IP: ${BMC_USB_ETH_IP}
    Log  Host USB Ethernet IP: ${HOST_USB_ETH_IP}


Setup Host SSH Only
    [Documentation]  Open SSH connection to the host only (no USB Ethernet IP query).
    ...  Use as [Setup] for tests that need SSH to the host but NOT ${BMC_USB_ETH_IP}.

    SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}


Setup BMC SSH Only
    [Documentation]  Open SSH connection to the BMC only (no USB Ethernet IP query).
    ...  Use as [Setup] for tests that need SSH to the BMC but NOT ${BMC_USB_ETH_IP}.

    SSH Open Connection  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}


Setup Host SSH
    [Documentation]  Get USB Ethernet IPs then open SSH connection to the host.
    ...  Use as [Setup] for tests that need ${BMC_USB_ETH_IP}/${HOST_USB_ETH_IP}
    ...  and an active SSH session to the host.

    Get USB Ethernet IPs
    SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}


Setup Teardown
    [Documentation]  Restore Credential Bootstrapping to its default state (Enabled=true,
    ...  EnableAfterReset=true) and close all open SSH connections.
    ...  Used as [Teardown] for tests that modify CredentialBootstrapping settings so that
    ...  subsequent tests always start from a known-good baseline.

    Set And Verify Credential Bootstrapping  enabled=${True}  enable_after_reset=${True}
    Close All Connections


Suite Teardown Execution
    [Documentation]  Safe suite teardown: logout from Redfish (ignoring errors if the
    ...  session was already invalidated by a BMC restart) and close all SSH connections.

    Run Keyword And Ignore Error  Redfish.Logout
    Close All Connections


Setup Bootstrap Test
    [Documentation]  Get USB Ethernet IPs, enable Credential Bootstrapping via Redfish,
    ...  open SSH connection to the host, and retrieve bootstrap credentials via SSIF IPMI.
    ...  Stores ${BOOTSTRAP_USERNAME} and ${BOOTSTRAP_PASSWORD} as suite variables.
    ...  Use as [Setup] for any test that requires bootstrap credentials.

    Get USB Ethernet IPs
    Set And Verify Credential Bootstrapping  enabled=${True}  enable_after_reset=${True}
    SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    Sleep  1s
    Get Bootstrap Credentials


Teardown Bootstrap Test
    [Documentation]  Delete the bootstrap account via Redfish and close all SSH connections.
    ...  Use as [Teardown] for any test that generates bootstrap credentials.
    ...  Ignores 404 (account already deleted) so it is safe to use even when the test
    ...  itself deletes the account.

    Set And Verify Credential Bootstrapping  enabled=${True}  enable_after_reset=${True}
    Run Keyword And Ignore Error
    ...  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${BOOTSTRAP_USERNAME}
    ...  valid_status_codes=[200, 204, 404]
    Close All Connections


Get Bootstrap Credentials
    [Documentation]  Run SSIF IPMI Get Bootstrap Account Credentials command on the host,
    ...  parse the hex response using NULL (00) terminators instead of fixed offsets,
    ...  and store the username and password as suite-level variables.
    [Arguments]  ${Enabled}=${True}

    # Description of argument(s):.
    # Enabled  If ${True}, request credentials with bootstrapping enabled; if ${False}, disable after retrieval.

    ${raw}=  Wait Until Keyword Succeeds  2 min  10 sec
    ...  Get SSIF Bootstrap Raw Response  ${Enabled}

    # Split hex bytes.
    ${bytes}=  Split String  ${raw}

    # Drop first byte (command echo / status).
    ${data_bytes}=  Get Slice From List  ${bytes}  1

    # Convert hex bytes -> ASCII with explicit NULL markers.
    ${ascii}=  Evaluate
    ...  ''.join(chr(int(b, 16)) if int(b, 16) != 0 else '\\x00' for b in $data_bytes)

    # Split on NULL terminators.
    @{fields}=  Split String  ${ascii}  \x00

    VAR  ${username}  ${fields[0]}
    VAR  ${password}  ${fields[1]}

    # Store as suite variables.
    VAR  ${BOOTSTRAP_USERNAME}  ${username}  scope=SUITE
    VAR  ${BOOTSTRAP_PASSWORD}  ${password}  scope=SUITE

    Log  Bootstrap Username / Account ID: ${username}
    Log  Bootstrap Password obtained and stored as suite variable


Get SSIF Bootstrap Raw Response
    [Documentation]  Run the SSIF IPMI raw command once and fail unless it returns a
    ...    successful (rc=0) non-empty response. Right after a BMC reboot the SSIF/IPMI
    ...    path can take longer to come up than any fixed settling sleep accounts for, so
    ...    this is meant to be called via Wait Until Keyword Succeeds rather than relied
    ...    on directly.
    [Arguments]  ${Enabled}

    # Description of argument(s):
    # Enabled    True to query the "get bootstrapping enabled" raw command
    # (0x52 0xA5); False to query the "disable" raw command (0x52 0x00).

    IF    ${Enabled} == ${True}
        ${raw}  ${rc}=  Execute Command  sudo ipmitool raw ${IPMI_RAW_CMD}[ssif_bootstrap_credentials][Get_Enabled][0]
        ...  return_stdout=True  return_rc=True
    ELSE
        ${raw}  ${rc}=  Execute Command  sudo ipmitool raw ${IPMI_RAW_CMD}[ssif_bootstrap_credentials][Get_Disabled][0]
        ...  return_stdout=True  return_rc=True
    END
    Should Be Equal As Integers  ${rc}  0
    ...    msg=ipmitool raw exited non-zero (rc=${rc}); SSIF path is likely not ready yet.
    Should Not Be Empty  ${raw}
    RETURN  ${raw}


Verify Bootstrap Account Deleted
    [Documentation]  Verify the bootstrap account is no longer present in the Redfish
    ...  account list. Requires an active Redfish session.

    ${resp}=  Redfish.Get  ${REDFISH_ACCOUNTS_URI}
    ${uris}=  Evaluate  [m['@odata.id'] for m in $resp.dict['Members']]
    Should Not Contain  ${uris}  /redfish/v1/AccountService/Accounts/${BOOTSTRAP_USERNAME}


Delete All BMC Accounts Except Root
    [Documentation]  Deletes all Redfish accounts except root (and also skips the current login user).

    # Get the list of account resource URIs (Members) under Accounts collection.
    ${members}=  redfish_utils.Get Member List  ${REDFISH_ACCOUNTS_URI}

    FOR  ${uri}  IN  @{members}
        ${resp}=  Redfish.Get  ${uri}  valid_status_codes=[${HTTP_OK}]
        ${uname}=  Get Variable Value  ${resp.dict["UserName"]}  ${EMPTY}

        # Skip root and skip the currently logged-in user to avoid breaking auth mid-loop.
        IF  '${uname}' == 'root' or '${uname}' == '${OPENBMC_USERNAME}'
          Log  Skipping user ${uname} (${uri})
          CONTINUE
        END

        Log  Deleting user ${uname} (${uri})
        Redfish.Delete  ${uri}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}, ${HTTP_NOT_FOUND}]
    END


Extract Throughput
    [Documentation]  Extracts sender and receiver throughput from final [SUM] lines and normalizes to Mbps.
    ...  Supports Kbits/sec, Mbits/sec, Gbits/sec.
    [Arguments]  ${output}

    # Description of argument(s):.
    # output  The raw iperf3 output string to parse for sender/receiver throughput.

    # sender line has Retr field, receiver line may not.
    # Use \\S+ for the interval so any decimal (e.g. 30.01) is accepted.
    VAR  ${sender_pat}  \\[SUM\\][^\\n]*\\s(\\d+(?:\\.\\d+)?)\\s+([KMG])bits/sec\\s+\\d+\\s+sender
    VAR  ${recv_pat}  \\[SUM\\][^\\n]*\\s(\\d+(?:\\.\\d+)?)\\s+([KMG])bits/sec\\s+receiver
    ${s_val}=  Get Regexp Matches  ${output}  ${sender_pat}  1
    ${s_unit}=  Get Regexp Matches  ${output}  ${sender_pat}  2
    ${r_val}=  Get Regexp Matches  ${output}  ${recv_pat}  1
    ${r_unit}=  Get Regexp Matches  ${output}  ${recv_pat}  2

    Should Not Be Empty  ${s_val}  msg=Sender throughput not found in iperf3 output.
    Should Not Be Empty  ${s_unit}  msg=Sender unit not found in iperf3 output.
    Should Not Be Empty  ${r_val}  msg=Receiver throughput not found in iperf3 output.
    Should Not Be Empty  ${r_unit}  msg=Receiver unit not found in iperf3 output.

    # Get Regexp Matches returns lists; extract first element before converting.
    ${sender_mbps}=  Convert Iperf Unit To Mbps  ${s_val}[0]  ${s_unit}[0]
    ${receiver_mbps}=  Convert Iperf Unit To Mbps  ${r_val}[0]  ${r_unit}[0]

    RETURN  ${sender_mbps}  ${receiver_mbps}


Convert Iperf Unit To Mbps
    [Documentation]  Converts K/M/G bits/sec prefix to Mbps.
    [Arguments]  ${value}  ${unit}

    # Description of argument(s):.
    # value  The numeric throughput value as a string (e.g. "94.5").
    # unit   The unit prefix: K (Kbits/sec), M (Mbits/sec), or G (Gbits/sec).

    IF  '${unit}' == 'K'
      ${mbps}=  Evaluate  float('${value}') / 1000.0
    ELSE IF  '${unit}' == 'M'
      ${mbps}=  Evaluate  float('${value}')
    ELSE IF  '${unit}' == 'G'
      ${mbps}=  Evaluate  float('${value}') * 1000.0
    ELSE
      Fail  Unsupported unit prefix: ${unit}
    END
    RETURN  ${mbps}
=======
>>>>>>> BASE      (3c7573 test_lists: drop dead include from QEMU_CI)
