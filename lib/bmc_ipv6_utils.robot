*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Library                 ../lib/gen_misc.py
Library                 ../lib/utils.py
Library                 ../lib/bmc_network_utils.py


*** Keywords ***

Get BMC IPv6 Info
    [Documentation]  Get system IPv6 address and prefix length.

    # Get system IP address and prefix length details using "ip addr"
    # Sample Output of "ip addr":
    # 1: eth0: <BROADCAST,MULTIAST> mtu 1500 qdisc mq state UP qlen 1000
    #     link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    #     inet xx.xx.xx.xx/24 brd xx.xx.xx.xx scope global eth0
    #     inet6 fe80::xxxx:xxxx:xxxx:xxxx/64 scope link
    #     inet6 xxxx::xxxx:xxxx:xxxx:xxxx/64 scope global

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  /sbin/ip addr

    # Get line having IPv6 address details.
    ${lines}=  Get Lines Containing String  ${cmd_output}  inet6

    # List IP address details.
    @{ip_components}=  Split To Lines  ${lines}

    @{ipv6_data}=  Create List

    # Get all IP addresses and prefix lengths on system.
    FOR  ${ip_component}  IN  @{ip_components}
      @{if_info}=  Split String  ${ip_component}
      ${ip_n_prefix}=  Get From List  ${if_info}  1
      Append To List  ${ipv6_data}  ${ip_n_prefix}
    END

    [Return]  ${ipv6_data}


Verify IPv6 On BMC
    [Documentation]  Verify IPv6 on BMC.
    [Arguments]  ${ipv6}

    # Description of argument(s):
    # ipv6  IPv6 address to be verified (e.g. "2001::1234:1234").

    # Get IPv6 address details on BMC using IP command.
    @{ip_data}=  Get BMC IPv6 Info
    Should Contain Match  ${ip_data}  ${ipv6}/*
    ...  msg=IPv6 address does not exist.


Verify IPv6 Default Gateway On BMC
    [Documentation]  Verify IPv6 default gateway on BMC.
    [Arguments]  ${gateway_ip}=0:0:0:0:0:0:0:0

    # Description of argument(s):
    # gateway_ip  Gateway IPv6 address.

    ${route_info}=  Get BMC IPv6 Route Info

    # If gateway IP is empty it will not have route entry.

    Run Keyword If  '${gateway_ip}' == '0:0:0:0:0:0:0:0'
    ...      Pass Execution  Gateway IP is not configured.
    ...  ELSE
    ...      Should Contain  ${route_info}  ${gateway_ip}
    ...      msg=Gateway IP address not matching


Get BMC IPv6 Route Info
    [Documentation]  Get IPv6 route info on BMC.

    # Sample output of "ip -6 route":
    # unreachable ::/96 dev lo metric 1024 error -113
    # unreachable ::ffff:0.0.0.0/96 dev lo metric 1024 error -113
    # 2xxx:xxxx:0:1::/64 dev eth0 proto kernel metric 256
    # fe80::/64 dev eth1 proto kernel metric 256
    # fe80::/64 dev eth0 proto kernel metric 256
    # fe80::/64 dev eth2 proto kernel metric 256


    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  /sbin/ip -6 route

    [Return]  ${cmd_output}
