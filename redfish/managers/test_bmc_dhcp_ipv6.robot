*** Settings ***
Documentation  Network interface IPv6 configuration connected to DHCP server
               ...   and verification tests.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/openbmc_ffdc.robot
Resource       ../../lib/bmc_ipv6_utils.robot
Resource       ../../lib/external_intf/vmi_utils.robot
Resource       ../../lib/bmc_network_utils.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections
Library        Process
Library        OperatingSystem
Test Teardown   Test Teardown Execution
Suite Setup     Suite Setup Execution
Suite Teardown  Redfish.Logout

Test Tags     BMC_DHCP_IPv6

*** Variables ***
${SERVER_NAME}          ${EMPTY}
${SERVER_PASSWORD}      ${EMPTY}
${SERVER_IPv6}          ${EMPTY}


*** Test Cases ***

Get DHCPv6 Address And Verify Connectivity
    [Documentation]  Get DHCPv6 address and verify ping and SSH connection.
    [Tags]  Get_DHCPv6_Address_And_Verify_Connectivity

    @{ipv6_addressorigin_list}  ${ipv6_dhcpv6_addr}=
    ...  Get Address Origin List And Address For Type  DHCPv6
    IF  '${SERVER_NAME}' != '${EMPTY}'
        Check Ping6 Status And Verify  ${ipv6_dhcpv6_addr}
    ELSE
        Wait For IPv6 Host To Ping  ${ipv6_dhcpv6_addr}
    END
    Connect To IPv6 Host Via SSH  ${ipv6_dhcpv6_addr}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login
    ${active_channel_config}=  Get Active Channel Config
    Set Suite Variable  ${active_channel_config}

    ${ethernet_interface}=  Set Variable  ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Set Suite variable  ${ethernet_interface}


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail


Wait For IPv6 Host To Ping
    [Documentation]  Verify that the IPv6 host responds successfully to ping.
    [Arguments]  ${host}  ${timeout}=${OPENBMC_REBOOT_TIMEOUT}min
    ...          ${interval}=5 sec  ${expected_rc}=${0}

    # Description of argument(s):
    # host        The IPv6 address of the host to ping.
    # timeout     Maximum time to wait for the host to respond to ping.
    # interval    Time to wait between ping attempts.
    # expected_rc    Expected return code of ping command.

    Wait Until Keyword Succeeds  ${timeout}  ${interval}  Ping6 Host  ${host}  ${expected_rc}


Ping6 Host
    [Documentation]  Ping6 the given host.
    [Arguments]     ${host}  ${expected_rc}=${0}

    # Description of argument(s):
    # host           IPv6 address of the host to ping.
    # expected_rc    Expected return code of ping command.

    Should Not Be Empty    ${host}   msg=No host provided.
    ${rc}   ${output}=     Run and return RC and Output    ping6 -c 4 ${host}
    Log     RC: ${rc}\nOutput:\n${output}
    Should Be Equal     ${rc}   ${expected_rc}


Check Ping6 Status And Verify
    [Documentation]  Check ping6 status and verify.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6   IPv6 address to check connectivity.

    Open Connection And Log In  ${SERVER_NAME}  ${SERVER_PASSWORD}  host=${SERVER_IPv6}
    Wait For IPv6 Host To Ping  ${OPENBMC_HOST_IPv6}  30 secs


Connect To IPv6 Host Via SSH
    [Documentation]  Verify connectivity to the IPv6 host via SSH.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6   IPv6 address to check connectivity.

    IF  '${SERVER_NAME}' == '${EMPTY}'
        SSHLibrary.Open Connection  ${OPENBMC_HOST_IPv6}
        SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ELSE
        Open Connection And Log In  ${SERVER_NAME}  ${SERVER_PASSWORD}  host=${SERVER_IPv6}  alias=IPv6Conn
        SSHLibrary.Open Connection  ${OPENBMC_HOST_IPv6}
        SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  jumphost_index_or_alias=IPv6Conn
    END
