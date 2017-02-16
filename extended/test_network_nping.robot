*** Settings ***
Documentation  This program generates network traffic and
...            checks system behavior and packets loss.

Library  OperatingSystem
Library  String

Suite Setup  Setup_NPING

*** Variables ***

${port}  80
${protocol}  tcp
${delay}  200ms
${count}  100

*** Test Cases ***

Generate Network Traffic And Check Packet Loss
    [Documentation]  Generate network packets towards target.
    [Tags]  Generate_Network_Traffic_And_Check_Packet_Loss

    ${traffic_details}=  Send Network Packets  ${protocol}  ${port}
    Log To Console  \nPackets sent and received \n\n ${traffic_details}
    Check Packets Loss  ${traffic_details}

*** Keywords ***

Setup_NPING
    [Documentation]  Setup NPING tool.

    ${output}=  Run  which nping
    Should Not Be Empty  ${output}  msg=NPING tool not installed. 

Send Network Packets
    [Documentation]  Send TCP, UDP or ICMP packets towards the target.
    [Arguments]  ${type_of_packets}=tcp  ${port}=80

    # This program expects HOST, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in commad line
    # by default it sends 100 TCP packets at 5 packets/second.

    ${rc}  ${op}  Run Keyword If  '${type_of_packets}' == 'icmp'
    ...  Run And Return RC And Output  
    ...  nping --delay ${delay} ${HOST} -c ${count} --${type_of_packets}
    ...  ELSE  Run And Return RC And Output  
    ...  nping --delay ${delay} ${HOST} -c ${count} -p ${port} --${type_of_packets}
    [Return]  ${op}

Check Packets Loss
    [Documentation]  Check packet loss percentage.
    [Arguments]  ${traffic_details}

    ${summary}=  Get Lines Containing String  ${traffic_details}  Rcvd:
    Log To Console  \nPackets loss summary\n*********************
    Log To Console  *********************\n${summary}
