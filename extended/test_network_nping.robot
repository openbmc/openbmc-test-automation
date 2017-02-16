*** Settings ***
Documentation  This program sends network traffic and
...            checks system behavior and packets loss.

Library  OperatingSystem
Library  String

Suite Setup  Check If Tool Exist

*** Variables ***

${port}              80
${protocol}          tcp
${delay}             200ms
${count}             100
${packet_loss_bmc}   ${EMPTY}
${packet_loss_host}  ${EMPTY}

*** Test Cases ***

Generate Network Traffic And Check Packet Loss On BMC HOST
    [Documentation]  Generate network packets towards target.
    [Tags]  Generate_Network_Traffic_And_Check_Packet_Loss_On_BMC_HOST

    ${traffic_details}=  Send Network Packets  ${OPENBMC_HOST}  ${protocol}  ${port}
    Log To Console  \nPackets sent and received \n\n ${traffic_details}
    ${packet_loss}  Check Packets Loss  ${OPENBMC_HOST}  ${traffic_details}
    Set Global variable  ${packet_loss_bmc}  ${packet_loss}

Generate Network Traffic And Check Packet Loss On HOST
    [Documentation]  Generate network packets towards target.
    [Tags]  Generate_Network_Traffic_And_Check_Packet_Loss_On_HOST

    ${traffic_details}=  Send Network Packets  ${HOST}  ${protocol}  ${port}
    Log To Console  \nPackets sent and received \n\n ${traffic_details}
    ${packet_loss}  Check Packets Loss  ${HOST}  ${traffic_details}
    Set Global variable  ${packet_loss_host}  ${packet_loss}

Confirm The Issue
    [Documentation]  Determine issue is with Network or BMC.

    Compare Results  ${packet_loss_bmc}  ${packet_loss_host}

*** Keywords ***

Check If Tool Exist
    [Documentation]  Check NPING tool exists.

    ${output}=  Run  which nping
    Should Not Be Empty  ${output}  msg=NPING tool not installed.

Send Network Packets
    [Documentation]  Send TCP, UDP or ICMP packets towards the target.
    [Arguments]  ${HOST}  ${type_of_packets}=tcp  ${port}=80

    # This program expects HOST, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in commad line
    # by default it sends 100 TCP packets at 5 packets/second.

    ${rc}  ${op}  Run Keyword If  '${type_of_packets}' == 'icmp'
    ...  Run And Return RC And Output
    ...  nping --delay ${delay} ${HOST} -c ${count} --${type_of_packets}
    ...  ELSE  Run And Return RC And Output
    ...  nping --delay ${delay} ${HOST} -c ${count} -p ${port} --${type_of_packets}
    Should Be Equal As Integers  ${rc}  0  msg=command execution failed.
    [Return]  ${op}

Check Packets Loss
    [Documentation]  Check packet loss percentage.
    [Arguments]  ${HOST}  ${traffic_details}

    ${summary}=  Get Lines Containing String  ${traffic_details}  Rcvd:
    Log To Console  \nPackets loss summary on ${HOST}\n*********************
    Log To Console  *********************\n${summary}
    [Return]  ${summary}

Compare Results
    [Documentation]  Comapare packets loss on host & BMC host.
    [Arguments]  ${loss_bmc}  ${loss_host}

    Run Keyword If
    ...  '${loss_bmc}' == '${loss_host}' and '0.00%' in '${loss_bmc}'
    ...  Log To Console  \n\n*** No issue with both Network and BMC ***\n
    ...  ELSE IF  '${loss_bmc}' != '${loss_host}'
    ...  Log To Console  \n\n*** There is an issue with BMC ***\n
    ...  ELSE  Log To Console  \n\n*** There is a Network issue ***\n
