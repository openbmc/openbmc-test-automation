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

    ${active_channel_config}=  Get Active Channel Config
    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}
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
