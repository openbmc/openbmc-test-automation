*** Settings ***
Documentation  Network stack stress tests using "nping" tool.

Resource                ../lib/resource.robot

Library                 OperatingSystem
Library                 String
Library                 ../lib/gen_robot_valid.py
Library                 ../lib/bmc_network_utils.py

Suite Setup             Suite Setup Execution

Force Tags              Network_Nping

*** Variables ***

${delay}                1000ms
${count}                4
${program_name}         nping1

*** Test Cases ***

Send ICMP Timestamp Request
    [Documentation]  Send ICMP packet type 13 and check BMC drops such packets
    [Tags]  Send_ICMP_Timestamp_Request

    # Send ICMP packet type 13 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets
    ...  ${OPENBMC_HOST}  ${ICMP_PACKETS}  ${NETWORK_PORT}  ${ICMP_ECHO_REQUEST}
    Should Be Equal  ${packet_loss}  100.00
    ...  msg=FAILURE: BMC is not dropping timestamp request messages.

*** Keywords ***

Suite Setup Execution
    [Documentation]  Validate the setup.

    Valid Value  OPENBMC_HOST
    Valid Program  program_name

Send Network Packets
    [Documentation]  Send TCP, UDP or ICMP packets to the target.
    [Arguments]  ${host}  ${packet_type}=${ICMP_PACKETS}  ${port}=80  ${icmp_type}=${ICMP_ECHO_REQUEST}

    # Description of argument(s):
    # host         The host name or IP address of the target system.
    # packet_type  The type of packets to be sent ("tcp, "udp", "icmp").
    # port         Network port.
    # icmp_type    Type of ICMP packets (e.g. 8, 13, 17, etc.).

    # This keyword expects host, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in command line.
    # By default it sends 4 ICMP echo request  packets at 1 packets/second.

    ${cmd_suffix}=  Set Variable If  '${packet_type}' == 'icmp'
    ...  --icmp-type ${icmp_type}
    ...  -p ${port}
    ${cmd_buf}=  Set Variable  nping --delay ${delay} ${host} -c ${count} --${packet_type} ${cmd_suffix}

    ${rc}  ${output}=  Run And Return RC And Output  ${cmd_buf}
    Should Be Equal As Integers  ${rc}  0  msg=Command execution failed.
    ${packet_loss}=  Get Packet Loss  ${host}  ${output}
    [Return]  ${packet_loss}

Get Packet Loss
    [Documentation]  Check packet loss percentage.
    [Arguments]  ${host}  ${traffic_details}

    # Description of arguments:
    # host             The host name or IP address of the target system.
    # traffic_details  Details of the network traffic sent.

    # Sample Output from "nping" command:
    # Starting Nping 0.6.47 ( http://nmap.org/nping ) at 2019-08-07 22:05 IST
    # SENT (0.0181s) TCP Source IP:37577 >
    #   Destination IP:80 S ttl=64 id=39113 iplen=40  seq=629782493 win=1480
    # SENT (0.2189s) TCP Source IP:37577 >
    #   Destination IP:80 S ttl=64 id=39113 iplen=40  seq=629782493 win=1480
    # RCVD (0.4120s) TCP Destination IP:80 >
    #   Source IP:37577 SA ttl=49 id=0 iplen=44  seq=1078301364 win=5840 <mss 1380>
    # Max rtt: 193.010ms | Min rtt: 193.010ms | Avg rtt: 193.010ms
    # Raw packets sent: 2 (80B) | Rcvd: 1 (46B) | Lost: 1 (50.00%)
    # Nping done: 1 IP address pinged in 0.43 seconds

    ${nping_result}=  Parse Nping Output  ${traffic_details}
    [Return]   ${nping_result['percent_lost']}
