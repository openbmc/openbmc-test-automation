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

Test Tags     BMC_IPv6_Config

*** Variables ***
${SERVER_USERNAME}      ${EMPTY}
${SERVER_PASSWORD}      ${EMPTY}
${SERVER_IPv6}          ${EMPTY}


*** Test Cases ***

Get SLAAC Address And Verify Connectivity
    [Documentation]  Fetch the SLAAC address and verify ping and SSH connection.
    [Tags]  Get_SLAAC_Address_And_Verify_Connectivity

    @{ipv6_addressorigin_list}  ${ipv6_slaac_addr}=
    ...  Get Address Origin List And Address For Type  SLAAC
    IF  '${SERVER_USERNAME}' != '${EMPTY}'
        Check IPv6 Connectivity  ${ipv6_slaac_addr}
    ELSE
        Wait For IPv6 Host To Ping  ${ipv6_slaac_addr}
    END
    Verify SSH Connection Via IPv6  ${ipv6_slaac_addr}


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
    [Arguments]  ${host}  ${timeout}=${OPENBMC_REBOOT_TIMEOUT}sec
    ...          ${interval}=5 sec  ${expected_rc}=${0}
    # Description of argument(s):
    # host         The IPv6 address of the host to ping.
    # timeout      Maximum time to wait for the host to respond to ping.
    # interval     Time to wait between ping attempts.
    # expected_rc  Expected return code of ping command.
    Wait Until Keyword Succeeds  ${timeout}  ${interval}  Ping Host Over IPv6  ${host}  ${expected_rc}


Ping Host Over IPv6
    [Documentation]  Ping6 the given host.
    [Arguments]     ${host}  ${expected_rc}=${0}
    # Description of argument(s):
    # host           IPv6 address of the host to ping.
    # expected_rc    Expected return code of ping command.
    Should Not Be Empty    ${host}   msg=No host provided.
    ${rc}   ${output}=     Run and return RC and Output    ping6 -c 4 ${host}
    Log     RC: ${rc}\nOutput:\n${output}
    Should Be Equal     ${rc}   ${expected_rc}


Check IPv6 Connectivity
    [Documentation]  Check ping6 status and verify.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6   IPv6 address to check connectivity.

    Open Connection And Log In  ${SERVER_USERNAME}  ${SERVER_PASSWORD}  host=${SERVER_IPv6}
    Wait For IPv6 Host To Ping  ${OPENBMC_HOST_IPv6}  30 secs


Verify SSH Connection Via IPv6
    [Documentation]  Verify connectivity to the IPv6 host via SSH.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6   IPv6 address to check connectivity.

    IF  '${SERVER_USERNAME}' == '${EMPTY}'
        SSHLibrary.Open Connection  ${OPENBMC_HOST_IPv6}
        SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ELSE
        Open Connection And Log In  ${SERVER_USERNAME}  ${SERVER_PASSWORD}  host=${SERVER_IPv6}  alias=IPv6Conn
        SSHLibrary.Open Connection  ${OPENBMC_HOST_IPv6}
        SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  jumphost_index_or_alias=IPv6Conn
    END

