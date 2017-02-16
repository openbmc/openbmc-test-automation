*** Settings ***
Documentation  This program sends network traffic and
...            checks system behavior and packet loss.

Library  OperatingSystem
Library  String

Suite Setup  Validate Setup

*** Variables ***

${OPENBMC_HOST}      ${EMPTY}
${HOST}              ${EMPTY}
${port}              80
${packet_type}       tcp
${delay}             200ms
${count}             100
${bmc_packet_loss}   ${EMPTY}
${host_packet_loss}  ${EMPTY}

*** Test Cases ***

Send And Check Packet Loss
    [Documentation]  Generate network packets to target.
    [Tags]  Send_And_Check_Packet_Loss

    # Send packets to BMC and check packet loss. 
    ${packet_loss}=  Send Network Packets  ${OPENBMC_HOST}  ${packet_type}  ${port}
    Set Global variable  ${bmc_packet_loss}  ${packet_loss}

    # Send packets to any host and check packet loss.
    ${packet_loss}=  Send Network Packets  ${HOST}  ${packet_type}  ${port}
    Set Global variable  ${host_packet_loss}  ${packet_loss}

Confirm The Issue
    [Documentation]  Determine whether issue is with Network or BMC.
    [Tags]  Confirm_The_Issue
    Compare Results  ${bmc_packet_loss}  ${host_packet_loss}

*** Keywords ***

Validate Setup
    [Documentation]  Validate the setup.

    Should Not Be Empty  ${OPENBMC_HOST}  msg=BMC IP address not provided.
    Should Not Be Empty  ${HOST}  msg=Host IP address not provided.
    ${output}=  Run  which nping
    Should Not Be Empty  ${output}  msg="nping" tool not installed.

Send Network Packets
    [Documentation]  Send TCP, UDP or ICMP packets to the target.
    [Arguments]  ${host}  ${packet_type}=tcp  ${port}=80

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
    ...  Sample Output
    ...  Packet loss summary on xx.xx.xx.xx
    ...  Raw packets sent: 10 (400B) | Rcvd: 3 (138B) | Lost: 7 (70.00%)

    [Arguments]  ${host}  ${traffic_details}

    ${summary}=  Get Lines Containing String  ${traffic_details}  Rcvd:
    Log To Console  \nPacket loss summary on ${host}\n*********************
    Log To Console  *********************\n${summary}\n
    [Return]  ${summary}

Compare Results
    [Documentation]  Comapare packet loss on host & BMC host.
    [Arguments]  ${bmc_loss}  ${host_loss}

    Run Keyword If
    ...  '${bmc_loss}' == '${host_loss}' and 'Lost: 0 (0.00%)' in '${bmc_loss}'
    ...  Log To Console  \n\n*** No issue with both Network and BMC ***\n
    ...  ELSE IF  '${bmc_loss}' != '${host_loss}'
    ...  Log To Console  \n\n*** There is an issue with BMC ***\n
    ...  ELSE  Log To Console  \n\n*** There is a Network issue ***\n
