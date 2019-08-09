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
${program_name}         nping

*** Test Cases ***

Send ICMP Timestamp Request
    [Documentation]  Send ICMP packet type 13 and check BMC drops such packets
    [Tags]  Send_ICMP_Timestamp_Request

    # Send ICMP packet type 13 to BMC and check packet loss.
    ${packet_loss}=  Send Network Packets
    ...  ${OPENBMC_HOST}  ${ICMP_PACKETS}  ${NETWORK_PORT}  ${ICMP_TIMESTAMP_REQUEST}
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
    ${cmd_buf}=  Set Variable  --delay ${delay} ${host} -c ${count} --${packet_type} ${cmd_suffix}

    ${nping_result}=  Nping  ${cmd_buf}
    [Return]   ${nping_result['percent_lost']}
