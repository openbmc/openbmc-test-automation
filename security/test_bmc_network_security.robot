*** Settings ***
Documentation  Network stack stress tests using "nping" tool.

Resource                ../lib/resource.robot
Resource                ../lib/bmc_redfish_resource.robot
Resource                ../lib/ipmi_client.robot

Library                 OperatingSystem
Library                 String
Library                 ../lib/gen_robot_valid.py
Library                 ../lib/bmc_network_utils.py
Library                 ../lib/ipmi_utils.py

Suite Setup             Suite Setup Execution

Force Tags              Network_Nping

*** Variables ***

${delay}                1000ms
${count}                4
${program_name}         nping
${iterations}           5000

*** Test Cases ***

Send ICMP Timestamp Request
    [Documentation]  Send ICMP packet type 13 and check BMC drops such packets
    [Tags]  Send_ICMP_Timestamp_Request

    # Send ICMP packet type 13 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${count}  ${ICMP_PACKETS}  ${NETWORK_PORT}  ${ICMP_TIMESTAMP_REQUEST}
    Should Be Equal As Numbers  ${packet_loss}  100.00
    ...  msg=FAILURE: BMC is not dropping timestamp request messages.

Send ICMP Netmask Request
    [Documentation]  Send ICMP packet type 17 and check BMC drops such packets
    [Tags]  Send_ICMP_Netmask_Request

    # Send ICMP packet type 17 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${count}  ${ICMP_PACKETS}  ${NETWORK_PORT}  ${ICMP_NETMASK_REQUEST}
    Should Be Equal As Numbers  ${packet_loss}  100.00
    ...  msg=FAILURE: BMC is not dropping netmask request messages.

Send Network Packets Continuously To Redfish Interface
    [Documentation]  Send network packets continuously to Redfish interface and verify stability.
    [Tags]  Send_Network_Packets_Continuously_To_Redfish_Interface

    # Send large number of packets to Redfish interface.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${TCP_PACKETS}  ${REDFISH_INTERFACE}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping some packets.

    # Check if Redfish interface is functional.
    Redfish.Login
    Redfish.Logout


Send Network Packets Continuously To IPMI Port
    [Documentation]  Send network packets continuously to IPMI port and verify stability.
    [Tags]  Send_Network_Packets_Continuously_To_IPMI_Port

    # Send large number of packets to IPMI port.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${TCP_PACKETS}  ${IPMI_PORT}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping some packets.

    # Check if IPMI interface is functional.
    Run IPMI Standard Command  chassis status


Send Network Packets Continuously To SSH Port
    [Documentation]  Send network packets continuously to SSH port and verify stability.
    [Tags]  Send_Network_Packets_Continuously_To_SSH_Port

    # Send large number of packets to SSH port.
    ${packet_loss}=  Send Network Packets And Get Packet Loss
    ...  ${OPENBMC_HOST}  ${iterations}  ${TCP_PACKETS}  ${SSH_PORT}
    Should Be Equal As Numbers  ${packet_loss}  0.0
    ...  msg=FAILURE: BMC is dropping some packets.

    # Check if SSH interface is functional.

    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}


Flood Redfish Interface With Packets With Flags And Check Stability
    [Documentation]  Send large number of packets with flags to Redfish interface
    ... and check stability.
    [Tags]  Flood_Redfish_Interface_With_Packets_With_Flags_And_Check_Stability
    [Template]  Send Network Packets With Flags And Verify Stability

    # Target         No. Of packets  Interface              Flags

    # Flood syn packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${SYN_PACKETS}

    # Flood reset packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${RESET_PACKETS}

    # Flood fin packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${FIN_PACKETS}

    # Flood syn ack reset packets and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${SYN_ACK_RESET}

    # Flood packets with all flags and check BMC behavior.
    ${OPENBMC_HOST}  ${iterations}   ${REDFISH_INTERFACE}   ${ALL_FLAGS}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Validate the setup.

    Valid Value  OPENBMC_HOST
    Valid Program  program_name

Send Network Packets And Get Packet Loss
    [Documentation]  Send TCP, UDP or ICMP packets to the target.
    [Arguments]  ${host}  ${num}=${count}  ${packet_type}=${ICMP_PACKETS}
    ...          ${port}=80  ${icmp_type}=${ICMP_ECHO_REQUEST}

    # Description of argument(s):
    # host         The host name or IP address of the target system.
    # packet_type  The type of packets to be sent ("tcp, "udp", "icmp").
    # port         Network port.
    # icmp_type    Type of ICMP packets (e.g. 8, 13, 17, etc.).
    # num          Number of packets to be sent.

    # This keyword expects host, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in command line.
    # By default it sends 4 ICMP echo request  packets at 1 packets/second.

    ${cmd_suffix}=  Set Variable If  '${packet_type}' == 'icmp'
    ...  --icmp-type ${icmp_type}
    ...  -p ${port}
    ${cmd_buf}=  Set Variable  --delay ${delay} ${host} -c ${num} --${packet_type} ${cmd_suffix}

    ${nping_result}=  Nping  ${cmd_buf}
    [Return]   ${nping_result['percent_lost']}


Send Network Packets With Flags And Verify Stability
    [Documentation]  Send TCP with flags to the target.
    [Arguments]  ${host}  ${num}=${count}  ${port}=${REDFISH_INTERFACE}
    ...  ${flags}=${SYN_PACKETS}
    [Teardown]  Verify Interface Stability  ${port}

    # Description of argument(s):
    # host         The host name or IP address of the target system.
    # packet_type  The type of packets to be sent ("tcp, "udp", "icmp").
    # port         Network port.
    # flags        Type of flag to be set (e.g. SYN, ACK, RST, FIN, ALL).
    # num          Number of packets to be sent.

    # This keyword expects host, port, type and number of packets to be sent
    # and rate at which packets to be sent, should be given in command line.
    # By default it sends 4 ICMP echo request  packets at 1 packets/second.

    ${cmd_suffix}=  Catenate  -p ${port} --flags ${flags}
    ${cmd_buf}=  Set Variable  --delay ${delay} ${host} -c ${num} --${packet_type} ${cmd_suffix}

    ${nping_result}=  Nping  ${cmd_buf}
    Log To Console  Packets lost: ${nping_result['percent_lost']}


Verify Interface Stability
    [Documentation]  Verify interface is up and active.
    [Arguments]  ${port}

    # Description of argument(s):
    # port  Network port.

    Run Keyword If  ${port} == ${REDFISH_INTERFACE}
    ...  Redfish.Login
    ...  ELSE IF  ${port} == ${SSH_PORT}
    ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ...  ELSE IF  ${port} == ${IPMI_PORT}
    ...  Run External IPMI Standard Command lan print
    ...  ELSE IF  ${port} == ${HOST_SOL_PORT}
    ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  port=${HOST_SOL_PORT}
    ...  ELSE
    ...  Redfish.Login
