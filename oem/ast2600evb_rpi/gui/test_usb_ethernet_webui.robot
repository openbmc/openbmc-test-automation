*** Settings ***
Documentation  USB Ethernet Web UI test cases for AST2600 EVB+RPI setup.
...
...  Verifies Web UI is accessible over USB Ethernet IP via an SSH tunnel
...  from the test runner through the RPI host to the BMC.
...
...  Test Environment:
...  - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...  - Host: Raspberry Pi (RPI) at ${HOST_IP}
...  - USB Ethernet: BMC at ${BMC_USB_ETH_IP}

Resource        ../resource.resource

Suite Setup     Redfish.Login
Suite Teardown  Suite Teardown Execution

Test Tags  EVB_RPI

*** Test Cases ***

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

    # Wait for the SSH tunnel process to bind the local port before sending traffic.
    # No direct observable condition is available; 5 s is sufficient for ssh to establish the tunnel.
    Sleep  5s
    # Verify tunnel works
    ${result}=  Wait Until Keyword Succeeds  15s  1s
    ...  Run Process  curl  -k  https://127.0.0.1:18443/redfish/v1
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
