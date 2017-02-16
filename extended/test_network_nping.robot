*** Settings ***
Documentation  Network stack stress tests using "nping" tool.

Resource  ../lib/resource.txt

Library  OperatingSystem
Library  String

Suite Setup  Validate Setup

*** Variables ***

${delay}             200ms
${count}             100
${bmc_packet_loss}   ${EMPTY}

# This variable data is populated at suite setup and collected from a
# test system with OS for reference data to be use for comparison.
${compare_server}  ${EMPTY}

*** Test Cases ***

Verify Zero Network Packet Loss On BMC
    [Documentation]  Pump network packets to target.
    [Tags]  Verify_Zero_Network_Packet_Loss_On_BMC

    # Send packets to BMC and check packet loss.
    ${bmc_packet_loss}=  Send Network Packets
    ...  ${OPENBMC_HOST}  ${PACKET_TYPE}  ${NETWORK_PORT}
    Should Contain
    ...  ${bmc_packet_loss}  Lost: 0 (0.00%)  msg=Fail, Packet loss on BMC.

Verify Zero Network Packet Loss On Test Host Server
    [Documentation]  Send packets to BMC and compare with the "test system"
    ...              packet loss data to detect network packet drop failure.
    [Tags]  Verify_Zero_Network_Packet_Loss_On_Test_Host_Server
    ${bmc_packet_loss}=  Send Network Packets
    ...  ${OPENBMC_HOST}  ${PACKET_TYPE}  ${NETWORK_PORT}
    Check Test Host Server Packet Loss  ${bmc_packet_loss}  ${compare_server}

*** Keywords ***

Validate Setup
    [Documentation]  Validate the setup.

    Should Not Be Empty  ${OPENBMC_HOST}  msg=BMC IP address not provided.
    Should Not Be Empty  ${OS_HOST}  msg=Host IP address not provided.
    ${output}=  Run  which nping
    Should Not Be Empty  ${output}  msg="nping" tool not installed.
    # Send packets to any host and check packet loss.
    ${packet_loss}=  Send Network Packets
    ...  ${OS_HOST}  ${PACKET_TYPE}  ${NETWORK_PORT}
    Set Suite variable  ${compare_server}  ${packet_loss}
    Log To Console  ${compare_server}

Send Network Packets
    [Documentation]  Send TCP, UDP or ICMP packets to the target.
    [Arguments]  ${host}  ${packet_type}=tcp  ${port}=80

    # Description of arguments:
    # ${host}- Target system to which network packets to be sent.
    # ${packet_type}- type of packets to be sent viz tcp, udp or icmp.
    # ${port}- Network port.

    # This program expects host, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in commad line
    # by default it sends 100 TCP packets at 5 packets/second.

    ${cmd_buff}=  Run Keyword If  '${packet_type}' == 'icmp'
    ...  Set Variable  nping --delay ${delay} ${host} -c ${count} --${packet_type}
    ...  ELSE
    ...  Set variable
    ...  nping --delay ${delay} ${host} -c ${count} -p ${port} --${packet_type}
    ${rc}  ${output}  Run And Return RC And Output  ${cmd_buff}
    Should Be Equal As Integers  ${rc}  0  msg=Command execution failed.
    ${packet_loss}  Check Packet Loss  ${host}  ${output}
    [Return]  ${packet_loss}

Check Packet Loss
    [Documentation]  Check packet loss percentage.

    # Sample Output from "nping" command:
    # Starting Nping 0.6.47 ( http://nmap.org/nping ) at 2017-02-21 22:05 IST
    # SENT (0.0181s) TCP Source IP:37577 > Destination IP:80 S ttl=64 id=39113 iplen=40  seq=629782493 win=1480
    # SENT (0.2189s) TCP Source IP:37577 > Destination IP:80 S ttl=64 id=39113 iplen=40  seq=629782493 win=1480
    # RCVD (0.4120s) TCP Destination IP:80 > Source IP:37577 SA ttl=49 id=0 iplen=44  seq=1078301364 win=5840 <mss 1380>
    # Max rtt: 193.010ms | Min rtt: 193.010ms | Avg rtt: 193.010ms
    # Raw packets sent: 2 (80B) | Rcvd: 1 (46B) | Lost: 1 (50.00%)
    # Nping done: 1 IP address pinged in 0.43 seconds

    [Arguments]  ${host}  ${traffic_details}

    # Description of arguments:
    # ${host}- System on whcih packet loss to be checked.
    # ${traffic_details}- Details of the network traffic sent.

    ${summary}=  Get Lines Containing String  ${traffic_details}  Rcvd:
    Log To Console  \nPacket loss summary on ${host}\n*********************
    Log To Console  *********************\n${summary}\n
    [Return]  ${summary}

Check Test Host Server Packet Loss
    [Documentation]  Compare packet loss with a reference test system vs BMC.
    [Arguments]  ${bmc_loss}  ${host_loss}

    # Description of arguments:
    # ${bmc_loss}   Total number of packets sent, packets received
    #               and percentage of packet loss on BMC.
    # ${host_loss}  Total number of packets sent, packets received
    #               and percentage of packet loss on OS host.

    Run Keyword If
    ...  '${bmc_loss}' == '${host_loss}' and 'Lost: 0 (0.00%)' in '${bmc_loss}'
    ...  Log To Console  \n\n*** No issue with both Network and BMC ***\n
    ...  ELSE IF  '${bmc_loss}' != '${host_loss}'
    ...  Fail  msg=Failed, there is an issue with BMC.
    ...  ELSE  Fail  msg=Failed, There is a Network issue.
