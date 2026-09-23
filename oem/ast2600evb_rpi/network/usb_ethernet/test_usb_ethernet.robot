*** Settings ***
Documentation  USB Ethernet network test cases for AST2600 EVB+RPI setup.
...
...  Covers USB Ethernet interface configuration, connectivity (ping), Redfish API
...  access over USB Ethernet IP, and throughput/latency benchmarks.
...
...  Test Environment:
...  - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...  - Host: Raspberry Pi (RPI) at ${HOST_IP}
...  - USB Ethernet: BMC at ${BMC_USB_ETH_IP}, Host at ${HOST_USB_ETH_IP}

Resource        ../../resource.resource

Suite Setup     Redfish.Login
Suite Teardown  Suite Teardown Execution

Test Tags  EVB_RPI

*** Test Cases ***

Configure Ethernet Over Usb
    [Documentation]  Configure Ethernet over USB on the RPI host.
    ...  Verify Ethernet over IP is already configured in BMC.
    [Tags]  Configure_Ethernet_Over_Usb
    [Setup]  Setup Host SSH
    [Teardown]  Close All Connections

    ${output}=  Execute Command  sudo ip addr add ${HOST_USB_ETH_IP}/16 dev usb0
    ${output}=  Execute Command  sudo ip link set usb0 up
    ${host_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    Should Not Be Empty  ${host_raw}  usb0 has no IPv4 address on host
    # Verify BMC-side usb0 is already configured by firmware.
    SSH Open Connection  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${bmc_raw}=  Execute Command
    ...  ip addr show usb0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    Should Not Be Empty  ${bmc_raw}  usb0 has no IPv4 address on BMC


Ping Usb Ethernet Ip From Rpi Soc Host
    [Documentation]  Verify USB Ethernet IP can be pinged from Host (RPI/SOC) USB IP.
    [Tags]  Ping_Usb_Ethernet_Ip_From_Rpi_Soc_Host
    [Setup]  Setup Host SSH
    [Teardown]  Close All Connections

    ${output}=  Execute Command  ping -c 4 ${BMC_USB_ETH_IP}
    Should Contain  ${output}  0% packet loss


Redfish Api Access Over Usb Ethernet Ip
    [Documentation]  Verify Redfish API is accessible over USB Ethernet IP.
    [Tags]  Redfish_Api_Access_Over_Usb_Ethernet_Ip
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
