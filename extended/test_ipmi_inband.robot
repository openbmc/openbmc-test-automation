*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/bmc_network_utils.robot

Suite Setup         Suite Setup Execution
Test Teardown       FFDC On Test Case Fail


**** Test Cases ***


Retrieve Default Gateway Via IPMI And Verify Using REST
    [Documentation]  Retrieve default gateway from LAN print using IPMI.
    [Tags]  Retrieve_Default_Gateway_Via_IPMI_And_Verify_Using_REST

    # Fetch "Default Gateway" from IPMI LAN print.
    ${default_gateway_ipmi}=  Fetch Details From LAN Print  Default Gateway IP

    # Verify "Default Gateway" using REST.
    Read Attribute  ${NETWORK_MANAGER}/config  DefaultGateway
    ...  expected_value=${default_gateway_ipmi}


Retrieve MAC Address Via IPMI And Verify Using REST
    [Documentation]  Retrieve MAC Address from LAN print using IPMI.
    [Tags]  Retrieve_MAC_Address_Via_IPMI_And_Verify_Using_REST

    # Fetch "MAC Address" from IPMI LAN print.
    ${mac_address_ipmi}=  Fetch Details From LAN Print  MAC Address

    # Verify "MAC Address" using REST.
    ${mac_address_rest}=  Get BMC MAC Address
    Should Be Equal  ${mac_address_ipmi}  ${mac_address_rest}
    ...  msg=Verification of MAC address from lan print using IPMI failed.


Retrieve Network Mode Via IPMI And Verify Using REST
    [Documentation]  Retrieve network mode from LAN print using IPMI.
    [Tags]  Retrieve_Network_Mode_Via_IPMI_And_Verify_Using_REST

    # Fetch "Mode" from IPMI LAN print.
    ${network_mode_ipmi}=  Fetch Details From LAN Print  Source

    # Verify "Mode" using REST.
    ${network_mode_rest}=  Read Attribute
    ...  ${NETWORK_MANAGER}/eth0  DHCPEnabled
    Run Keyword If  '${network_mode_ipmi}' == 'Static Address'
    ...  Should Be Equal  ${network_mode_rest}  ${0}
    ...  msg=Verification of network setting failed.
    ...  ELSE  IF  '${network_mode_ipmi}' == 'DHCP'
    ...  Should Be Equal  ${network_mode_rest}  ${1}
    ...  msg=Verification of network setting failed.


Retrieve IP Address Via IPMI And Verify With BMC Details
    [Documentation]  Retrieve IP address from LAN print using IPMI.
    [Tags]  Retrieve_IP_Address_Via_IPMI_And_Verify_With_BMC_Details

    # Fetch "IP Address" from IPMI LAN print.
    ${ip_addr_ipmi}=  Fetch Details From LAN Print  IP Address

    # Verify the IP address retrieved via IPMI with BMC IPs.
    ${ip_address_rest}=  Get BMC IP Info
    Validate IP On BMC  ${ip_addr_ipmi}  ${ip_address_rest}


*** Keywords ***


Fetch Details From LAN Print
    [Documentation]  Fetch details from LAN print.
    [Arguments]  ${field_name}

    # Description of argument(s):
    # ${field_name}   Field name to be fetched from LAN print
    #                 (e.g. "MAC Address", "Source").

    ${stdout}=  Log LAN Print Details
    ${fetch_value}=  Get Lines Containing String  ${stdout}  ${field_name}
    ${value_fetch}=  Fetch From Right  ${fetch_value}  :${SPACE}
    [Return]  ${value_fetch}


Log LAN Print Details
    [Documentation]  Log IPMI LAN print details and return them as a string.

    # Example:

    # Set in Progress        : Set Complete
    # Auth Type Support      : MD5
    # Auth Type Enable       : Callback : MD5
    #                        : User     : MD5
    #                        : Operator : MD5
    #                        : Admin    : MD5
    #                        : OEM      : MD5
    # IP Address Source      : Static Address
    # IP Address             : xx.xx.xx.xx
    # Subnet Mask            : yy.yy.yy.yy
    # MAC Address            : xx.xx.xx.xx.xx.xx
    # Default Gateway IP     : xx.xx.xx.xx
    # 802.1q VLAN ID         : Disabled Cipher Suite
    # Priv Max               : Not Available
    # Bad Password Threshold : Not Available

    Login To OS Host
    Check If IPMI Tool Exist

    ${cmd_buf}=  Catenate  ${IPMI_INBAND_CMD}  lan print

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buf}
    Log  ${stdout}
    [Return]  ${stdout}


Suite Setup Execution
    [Documentation]  Do the suite setup execution tasks.

    Should Not Be Empty
    ...  ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...  ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...  ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot To OS
    REST Power On  quiet=${1}
