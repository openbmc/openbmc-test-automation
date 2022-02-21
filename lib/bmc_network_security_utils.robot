*** Settings ***

Documentation  Network security utility file.

Resource                ../lib/resource.robot
Resource                ../lib/bmc_redfish_resource.robot

Send Network Packets And Get Packet Loss
    [Documentation]  Send TCP, UDP or ICMP packets to any network device.
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
