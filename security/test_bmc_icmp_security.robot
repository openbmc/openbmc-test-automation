*** Settings ***
Documentation  Network stack stress tests using "nping" tool.

Resource  ../lib/resource.robot

Library  OperatingSystem
Library  String

Suite Setup  Suite Setup Execution

Force Tags  Network_Nping

*** Variables ***

${delay}             1000ms
${count}             4
${bmc_packet_loss}   ${EMPTY}

*** Test Cases ***

Send ICMP Timestamp Request
    [Documentation]  Send ICMP packet type 13 and check BMC drops such packets
    [Tags]  Send_ICMP_Timestamp_Request

    # Send ICMP packet type 13 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets
    ...  ${OPENBMC_HOST}  icmp  ${NETWORK_PORT}  13
    Should Contain  ${bmc_packet_loss}  Lost: 4 (100.00%)
    ...  msg=Fail, BMC is not dropping timestamp request messages.

*** Keywords ***

Suite Setup Execution
    [Documentation]  Validate the setup.

    Should Not Be Empty  ${OPENBMC_HOST}  msg=BMC IP address not provided.
    ${output}=  Run  which nping
    Should Not Be Empty  ${output}  msg="nping" tool not installed.

Send Network Packets
    [Documentation]  Send TCP, UDP or ICMP packets to the target.
    [Arguments]  ${host}  ${packet_type}=tcp  ${port}=80  ${icmp_type}=8

    # Description of argument(s):
    # host         Target system to which network packets to be sent.
    # packet_type  Type of packets to be sent viz tcp, udp or icmp.
    # port         Network port.
    # icmp_type    Type of ICMP packets e.g.(8, 13, 17 etc).

    # This program expects host, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in command line
    # by default it sends 4 TCP packets at 1 packets/second.

    ${cmd_buff}=  Run Keyword If  '${packet_type}' == 'icmp'
    ...  Set Variable  nping --delay ${delay} ${host} -c ${count} --${packet_type} --icmp-type ${icmp_type}
    ...  ELSE
    ...  Set variable
    ...  nping --delay ${delay} ${host} -c ${count} -p ${port} --${packet_type}

    ${rc}  ${output}=  Run And Return RC And Output  ${cmd_buff}
    Should Be Equal As Integers  ${rc}  0  msg=Command execution failed.
    ${packet_loss}=  Get Packet Loss  ${host}  ${output}
    [Return]  ${packet_loss}

Get Packet Loss
    [Documentation]  Check packet loss percentage.

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

    [Arguments]  ${host}  ${traffic_details}

    # Description of arguments:
    # host             System on which packet loss to be checked.
    # traffic_details  Details of the network traffic sent.

    ${summary}=  Get Lines Containing String  ${traffic_details}  Rcvd:
    Log To Console  \nPacket loss summary on ${host}\n*********************
    [Return]  ${summary}
