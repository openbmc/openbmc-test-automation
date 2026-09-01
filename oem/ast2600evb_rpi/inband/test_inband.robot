*** Settings ***
Documentation  Inband test cases for AST2600 EVB+RPI setup.
...
...  Test Environment:
...  - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...  - Host: Raspberry Pi (RPI) at ${HOST_IP}
...  - USB Ethernet: BMC at ${BMC_USB_ETH_IP}, Host at ${HOST_USB_ETH_IP}

Resource        ../resource.robot
Resource        ../../../gui/lib/gui_resource.robot

Suite Setup     Redfish.Login
Suite Teardown  Suite Teardown Execution

Test Tags  EVB_RPI

*** Test Cases ***

Ssif Subsystems
    [Documentation]  Verify SSIF subsystems is enabled by default.
    ...  Checks kernel config for SSIF support and /dev/ipmi-ssif-host device node.
    ...  systemctl status phosphor-ipmi-host.service service is active and running by default.
    [Tags]  Ssif_Subsystems
    [Setup]  Setup BMC SSH Only
    [Teardown]  Close All Connections

    ${output}=  Execute Command  cat /proc/config.gz | zcat | grep SSIF
    Should Contain  ${output}  CONFIG_NET_PTP_CLASSIFY=y
    Should Contain  ${output}  CONFIG_SSIF_IPMI_BMC=y
    ${dev_output}=  Execute Command  ls -l /dev/ipmi*
    Should Contain  ${dev_output}  /dev/ipmi-ssif-host
    ${output}=  Execute Command  systemctl status phosphor-ipmi-host.service
    Should Contain  ${output}  active (running)


Ssifbridge Service
    [Documentation]  Verify ssifbridge service is active and running by default.
    [Tags]  Ssifbridge_Service
    [Setup]  Setup BMC SSH Only
    [Teardown]  Close All Connections

    ${output}=  Execute Command  systemctl status ssifbridge.service
    Should Contain  ${output}  active (running)


Get Manager Certificate Fingerprint
    [Documentation]  Verify BMC returns certificate fingerprint via SSIF IPMI raw command.
    ...  Response layout: [0x52][0x01][32 SHA-256 bytes]
    ...  Compares the IPMI fingerprint with the SHA-256 fingerprint of the BMC TLS
    ...  certificate obtained via openssl to confirm they match.
    [Tags]  Get_Manager_Certificate_Fingerprint
    [Setup]  Setup Host SSH Only
    [Teardown]  Close All Connections

    Set And Verify Credential Bootstrapping  enabled=${True}
    # Get fingerprint bytes from IPMI.
    ${raw}=  Execute Command  sudo ipmitool raw 0x2c 0x01 0x52 0x01
    Should Not Be Empty  ${raw}
    ${bytes}=  Split String  ${raw}
    # Skip first 2 bytes (0x52 status, 0x01 echo); remaining 32 bytes = SHA-256 fingerprint.
    ${fp_bytes}=  Get Slice From List  ${bytes}  2
    ${ipmi_fp}=  Evaluate
    ...  ':'.join(b.upper() for b in $fp_bytes if b.strip())
    Log  IPMI Fingerprint: ${ipmi_fp}
    # Get fingerprint from BMC TLS certificate via openssl.
    ${openssl_out}=  Execute Command
    ...  openssl s_client -connect ${OPENBMC_HOST}:${HTTPS_PORT} -servername ${OPENBMC_HOST} </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
    ${openssl_fp}=  Evaluate  '${openssl_out}'.split('=')[-1].strip()
    Log  OpenSSL Fingerprint: ${openssl_fp}
    # Verify IPMI fingerprint matches the actual BMC certificate fingerprint.
    Should Be Equal As Strings  ${ipmi_fp}  ${openssl_fp}


Default Credential Boot Strapping Enableafterreset True Enabled True
    [Documentation]  Verify Default Credential Boot Strapping values.
    ...  EnableAfterReset and Enabled should both be true by default.
    [Tags]  Default_Credential_Boot_Strapping_Enableafterreset_True_Enabled_True

    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['EnableAfterReset']}  ${True}
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Get Bootstrap Account Credentials And Keep Credential Boot Strapping Enabled
    [Documentation]  Verify BMC returns valid username and password and Credential Boot Strapping
    ...  remains enabled after getting credentials (EnableAfterReset=true, Enabled=true).
    ...  Bootstrap account is deleted in teardown.
    [Tags]  Get_Bootstrap_Account_Credentials_And_Keep_Credential_Boot_Strapping_Enabled
    [Setup]  Setup Host SSH Only
    [Teardown]  Teardown Bootstrap Test

    # Enable Credential Bootstrapping via Redfish.
    Set And Verify Credential Bootstrapping  enabled=${True}
    # Get credentials from host via SSIF, parse and store as suite variables.
    Get Bootstrap Credentials  ${True}
    Log  Bootstrap Username: ${BOOTSTRAP_USERNAME}
    # Verify HostInterfaces still shows Enabled=true via Redfish.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Get Bootstrap Account Credentials And Disable Credential Boot Strapping
    [Documentation]  Verify BMC returns valid username and password and Credential Boot Strapping
    ...  is disabled after getting credentials.
    ...  Bootstrap account is deleted in teardown.
    [Tags]  Get_Bootstrap_Account_Credentials_And_Disable_Credential_Boot_Strapping
    [Setup]  Setup Host SSH Only
    [Teardown]  Teardown Bootstrap Test

    # Enable Credential Bootstrapping via Redfish.
    Set And Verify Credential Bootstrapping  enabled=${True}
    # Get credentials from host via SSIF, parse and store as suite variables.
    Get Bootstrap Credentials  ${False}
    Log  Bootstrap Username: ${BOOTSTRAP_USERNAME}
    # Verify HostInterfaces shows Enabled=false after get with disable via Redfish.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${False}


Enable Credential Boot Strapping
    [Documentation]  Verify Enabling Credential Boot Strapping using redfish.
    [Tags]  Enable_Credential_Boot_Strapping
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${True}


Disable Credential Boot Strapping
    [Documentation]  Verify disabling Credential Boot Strapping using redfish.
    [Tags]  Disable_Credential_Boot_Strapping
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${False}


Disable Credential Boot Strapping And Get Manager Certificate Fingerprint
    [Documentation]  Certificate fingerprint generation should fail when Credential Boot Strapping is disabled and
    ...  manager certificate fingerprint is requested.
    [Tags]  Disable_Credential_Boot_Strapping_And_Get_Manager_Certificate_Fingerprint
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${False}
    ${output}=  Execute Command  sudo ipmitool raw 0x2c 0x01 0x52 0x01
    Should Be Empty  ${output}  CredentialBootstrapping is not disabled


Disable Credential Boot Strapping And Get Bootstrap Account Credentials
    [Documentation]  Bootstrap Account User creation should fail when Credential Boot Strapping is disabled.
    [Tags]  Disable_Credential_Boot_Strapping_And_Get_Bootstrap_Account_Credentials
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${False}
    ${output}=  Execute Command  sudo ipmitool raw 0x2c 0x02 0x52 0xA5
    Should Be Empty  ${output}  CredentialBootstrapping is not disabled
    Set And Verify Credential Bootstrapping  enabled=${True}


Redfish Api Access With Received Bootstrap Account Credential From Host
    [Documentation]  Verify Redfish API access with Bootstrap Account Credential Generated.
    ...  Generates bootstrap credentials in setup and deletes the account in teardown.
    [Tags]  Redfish_Api_Access_With_Received_Bootstrap_Account_Credential_From_Host
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}'
    ...  https://${BMC_USB_ETH_IP}${HOST_INTERFACE_URI}
    ${output}=  Execute Command  ${cmd}  timeout=5
    ${json}=  Evaluate  json.loads('''${output}''')  json
    Should Be Equal  ${json['Description']}  Host Interface


Delete Bootstrap Account With Redfish From Host
    [Documentation]  Delete Bootstrap Account with Redfish API using bootstrap credentials.
    ...  Generates bootstrap credentials in setup; account is deleted by the test itself.
    [Tags]  Delete_Bootstrap_Account_With_Redfish_From_Host
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}' -X DELETE
    ...  https://${BMC_USB_ETH_IP}${REDFISH_ACCOUNTS_URI}${BOOTSTRAP_USERNAME}
    ${output}=  Execute Command  ${cmd}  timeout=5
    ${json}=  Evaluate  json.loads('''${output}''')  json
    Should Be Equal  ${json['@Message.ExtendedInfo'][0]['Message']}  The account was successfully removed.


Host Interface External Accessible Is Disabled
    [Documentation]  Verify External Access to Host Interface is disabled.
    ...  ExternallyAccessible should be false for the Host Interface.
    ...  Generates bootstrap credentials in setup and deletes the account in teardown.
    [Tags]  Host_Interface_External_Accessible_Is_Disabled
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}'
    ...  https://${BMC_USB_ETH_IP}${HOST_INTERFACE_URI}
    ${output}=  Execute Command  ${cmd}
    ${json}=  Evaluate  json.loads('''${output}''')  json
    Should Be Equal  ${json['ExternallyAccessible']}  ${False}
    Should Be Equal  ${json['Description']}  Host Interface
    Should Be Equal  ${json['HostInterfaceType']}  NetworkHostInterface
    Should Be Equal  ${json['Id']}  rhi
    Should Be Equal  ${json['InterfaceEnabled']}  ${True}


Use Bootstrap Account Credential With Internal Connection Ethernet Over Usb
    [Documentation]  Verify Bootstrap Account Credential are usable over internal network
    ...  using Redfish interface (Ethernet over USB).
    ...  Generates bootstrap credentials in setup and deletes the account in teardown.
    [Tags]  Use_Bootstrap_Account_Credential_With_Internal_Connection_Ethernet_Over_Usb
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}'
    ...  https://${BMC_USB_ETH_IP}${REDFISH_BASE_URI}
    ${output}=  Execute Command  ${cmd}
    Should Contain  ${output}  RedfishVersion


Reset Service (Bmc Force Restart) Bootstrap Account Delete
    [Documentation]  Verify on service reset (BMC Force Restart) Bootstrap Account should get deleted.
    [Tags]  Reset_Service_(Bmc_Force_Restart)_Bootstrap_Account_Delete
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    BMC Force Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    Verify Bootstrap Account Deleted


Reset Service (Bmc Graceful Restart) Bootstrap Account Delete
    [Documentation]  Verify on service reset (BMC Graceful Restart) Bootstrap Account should get deleted.
    [Tags]  Reset_Service_(Bmc_Graceful_Restart)_Bootstrap_Account_Delete
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    Verify Bootstrap Account Deleted


Reset Service Bmc Force Restart Credential Bootstrapping Enabled
    [Documentation]  Verify Credential Bootstrapping gets enabled after BMC Force Restart.
    ...  When EnableAfterReset=true and Enabled=false, after BMC restart Enabled should become true.
    [Tags]  Reset_Service_Bmc_Force_Restart_Credential_Bootstrapping_Enabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping (EnableAfterReset remains true by default).
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${True}
    # Force restart BMC.
    BMC Force Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping is enabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Reset Service Bmc Graceful Restart Credential Bootstrapping Enabled
    [Documentation]  Verify Credential Bootstrapping gets enabled after BMC Graceful Restart.
    ...  When EnableAfterReset=true and Enabled=false, after BMC restart Enabled should become true.
    [Tags]  Reset_Service_Bmc_Graceful_Restart_Credential_Bootstrapping_Enabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping (EnableAfterReset remains true by default).
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${True}
    # Graceful restart BMC.
    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping is enabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Reset Service Bmc Force Restart Credential Bootstrapping Remain Disabled
    [Documentation]  Verify Credential Bootstrapping remains disabled after BMC Force Restart.
    ...  When EnableAfterReset=false and Enabled=false, after BMC restart Enabled should remain false.
    [Tags]  Reset_Service_Bmc_Force_Restart_Credential_Bootstrapping_Remain_Disabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping with EnableAfterReset=false.
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${False}
    # Force restart BMC.
    BMC Force Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping remains disabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${False}


Reset Service Bmc Graceful Restart Credential Bootstrapping Remain Disabled
    [Documentation]  Verify Credential Bootstrapping remains disabled after BMC Graceful Restart.
    ...  When EnableAfterReset=false and Enabled=false, after BMC restart Enabled should remain false.
    [Tags]  Reset_Service_Bmc_Graceful_Restart_Credential_Bootstrapping_Remain_Disabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping with EnableAfterReset=false.
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${False}
    # Graceful restart BMC.
    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish Login
    # Verify Credential Bootstrapping remains disabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${False}


Configure Ethernet Over Usb
    [Documentation]  Configure Ethernet over USB on RPI/SoC host.
    ...  Verify Ethernet over IP is already configured in BMC.
    [Tags]  Configure_Ethernet_Over_Usb
    [Setup]  Setup Host SSH
    [Teardown]  Close All Connections

    ${output}=  Execute Command  sudo ip addr add ${HOST_USB_ETH_IP}/16 dev usb0
    ${output}=  Execute Command  sudo ip link set usb0 up
    ${host_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    Should Not Be Empty  ${host_raw}  usb0 has no IPv4 address


Ping Usb Ethernet Ip From Host Usb Ethernet Ip (Rpi/Soc)
    [Documentation]  Verify USB Ethernet IP can be pinged from Host (RPI/SOC) USB IP.
    [Tags]  Ping_Usb_Ethernet_Ip_From_Host_Usb_Ethernet_Ip_(Rpi/Soc)
    [Setup]  Setup Host SSH
    [Teardown]  Close All Connections

    ${output}=  Execute Command  ping -c 4 ${BMC_USB_ETH_IP}
    Should Contain  ${output}  0% packet loss


Web Ui Access Over Usb Ethernet Ip
    [Documentation]  Verify Web UI accessible over USB Ethernet IP.
    [Tags]  Web_Ui_Access_Over_Usb_Ethernet_Ip
    [Setup]  Get USB Ethernet IPs
    [Teardown]  Stop USB Web UI SSH Tunnel

    # Create SSH tunnel.
    # Test Runner -> localhost:18443
    # SSH Tunnel -> HOST
    # HOST -> BMC USB Ethernet IP
    VAR  ${cmd}
    ...  sshpass -p '${HOST_PASSWORD}' ssh -N -L 18443:${BMC_USB_ETH_IP}:443 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${HOST_USERNAME}@${HOST_IP}

    Start Process
    ...  bash
    ...  -c
    ...  ${cmd}
    ...  alias=usb_webui_tunnel
    ...  stdout=${EXECDIR}${/}logs${/}usb_webui_tunnel_stdout.log
    ...  stderr=${EXECDIR}${/}logs${/}usb_webui_tunnel_stderr.log

    Sleep  5s
    # Verify tunnel works
    ${result}=  Run Process  curl  -k  https://127.0.0.1:18443/redfish/v1
    Should Contain  ${result.stdout}  RedfishVersion

    # Open GUI via tunnel
    Open Browser With URL  https://127.0.0.1:18443  
    Login GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Log  Successfully logged into OpenBMC GUI over USB Ethernet

    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}  timeout=15s
    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=30s
    Close Browser

Redfish Api Access Over Usb Ethernet Ip
    [Setup]  Get USB Ethernet IPs
    [Teardown]  Close All Connections

    SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    VAR  ${cmd}  curl -k -u ${OPENBMC_USERNAME}:${OPENBMC_PASSWORD} https://${BMC_USB_ETH_IP}/redfish/v1
    ${output}=  Execute Command  ${cmd}
    Should Contain  ${output}  RedfishVersion


Bmc To Host Throughput
    [Documentation]  Verify BMC to HOST Throughput > 30 MBPS.
    ...  Uses iperf3 reverse mode (-R): BMC server sends, host client receives.
    [Tags]  Bmc_To_Host_Throughput
    [Setup]  Get USB Ethernet IPs
    [Teardown]  Close All Connections

    # Kill any stale iperf3 server on BMC, then start a fresh one.
    ${bmc_conn}=  SSH Open Connection  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Execute Command  pkill iperf3 || true
    Start Command  iperf3 -s
    Sleep  2s  Wait for iperf3 server to bind port 5201
    # Ensure host USB Ethernet interface is up, then run iperf3 client.
    ${rpi_conn}=  SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    ${host_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    ${host_usb_ip}=  Strip String  ${host_raw}
    IF  '${host_usb_ip}' == '${EMPTY}'
        Execute Command  sudo ip addr add ${HOST_USB_ETH_IP}/16 dev usb0
        Execute Command  sudo ip link set usb0 up
        # Confirm the IP was applied successfully.
        ${confirm_raw}=  Execute Command
        ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
        ${confirmed_ip}=  Strip String  ${confirm_raw}
        Should Be Equal As Strings  ${confirmed_ip}  ${HOST_USB_ETH_IP}
    END
    # -R: server (BMC) sends → host receives; check receiver_throughput.
    ${output}=  Execute Command
    ...  iperf3 -c ${BMC_USB_ETH_IP} -t ${IPERF_DURATION} -P ${IPERF_PARALLEL} -R  timeout=${IPERF_TIMEOUT}
    ${sender_throughput}  ${receiver_throughput}  Extract Throughput  ${output}
    Should Be True  ${receiver_throughput} >= 30


Host To Bmc Throughput
    [Documentation]  Verify HOST to BMC Throughput > 30 MBPS.
    ...  Normal mode: host client sends, BMC server receives; check sender_throughput.
    [Tags]  Host_To_Bmc_Throughput
    [Setup]  Get USB Ethernet IPs
    [Teardown]  Close All Connections

    # Kill any stale iperf3 server on BMC, then start a fresh one.
    ${bmc_conn}=  SSH Open Connection  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Execute Command  pkill iperf3 || true
    Start Command  iperf3 -s
    Sleep  2s  Wait for iperf3 server to bind port 5201
    # Ensure host USB Ethernet interface is up, then run iperf3 client.
    ${rpi_conn}=  SSH Open Connection  ${HOST_IP}  ${HOST_USERNAME}  ${HOST_PASSWORD}
    ${host_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    ${host_usb_ip}=  Strip String  ${host_raw}
    IF  '${host_usb_ip}' == '${EMPTY}'
        Execute Command  sudo ip addr add ${HOST_USB_ETH_IP}/16 dev usb0
        Execute Command  sudo ip link set usb0 up
        # Confirm the IP was applied successfully.
        ${confirm_raw}=  Execute Command
        ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
        ${confirmed_ip}=  Strip String  ${confirm_raw}
        Should Be Equal As Strings  ${confirmed_ip}  ${HOST_USB_ETH_IP}
    END
    # No -R: host sends → BMC receives; check sender_throughput.
    ${output}=  Execute Command
    ...  iperf3 -c ${BMC_USB_ETH_IP} -t ${IPERF_DURATION} -P ${IPERF_PARALLEL}  timeout=${IPERF_TIMEOUT}
    ${sender_throughput}  ${receiver_throughput}  Extract Throughput  ${output}
    Should Be True  ${sender_throughput} >= 30


Latency And Packet Loss Test
    [Documentation]  Verify min, max avg, turnaround time and packet loss at 0.01 sec ping interval.
    [Tags]  Latency_And_Packet_Loss_Test
    [Setup]  Setup Host SSH
    [Teardown]  Close All Connections

    ${output}=  Execute Command
    ...  ping -i ${PING_INTERVAL} -c ${PING_COUNT} ${BMC_USB_ETH_IP}  timeout=${PING_TIMEOUT}
    Should Contain  ${output}  min/avg/max
    Should Contain  ${output}  0% packet loss


*** Keywords ***

Stop USB Web UI SSH Tunnel
    [Documentation]  Stop the USB Web UI SSH tunnel process if it is running and
    ...  wait for the process to exit. Any errors encountered during process
    ...  termination or wait operations are ignored to ensure cleanup does
    ...  not impact the calling test case.

    Run Keyword And Ignore Error
    ...  Terminate Process
    ...  usb_webui_tunnel
    ...  kill=True

    Run Keyword And Ignore Error
    ...  Wait For Process
    ...  usb_webui_tunnel
    ...  timeout=10s
