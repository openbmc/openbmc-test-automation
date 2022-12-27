*** Settings ***
Documentation  NTP Validation.

Resource       ../../lib/bmc_redfish_resource.robot
Resource       ../../lib/bmc_network_utils.robot
Library        ../../lib/bmc_network_utils.py
Library        Collections

Suite Setup     Redfish.Login
Suite Teardown  Redfish.Logout

*** Variables ***
${time_date}  timedatectl
@{additional_ntp_address}  14.139.60.103  14.139.60.106  14.139.60.107

*** Test Cases ***
Enable NTP Protocol And Add NTP Address
    [Documentation]  Enable ntp protocol and add ntp addresses.
    [Tags]  Enable_NTP_Protocol_And_Add_NTP_Address

    Enable NTP Protocol And Add NTP Addressess
    ${ntp_details}=  Get NTP Details
    Run Keyword And Continue On Failure  Lists Should Be Equal  ${ntp_details['NTPServers']}
    ...  ${NTP_SERVER_ADDRESSES}  msg=NTP Server addressess are not same
    Run Keyword And Continue On Failure  Should Be Equal  ${ntp_details['ProtocolEnabled']}  ${True}
    ...  msg=ProtocolEnabled Property is showing wrongly

Disable NTP Protocol And Check NTP Protocol Disabled
    [Documentation]  Disable ntp protocol and check ntp protocol disabled.
    [Tags]  Disable_NTP_Protocol_And_Check_NTP_Protocol_Disabled

    Disable NTP Protocol
    Check NTP Protocol Disabled

Enable NTP Protocol And Check NTP Protocol Enabled
    [Documentation]  Enable ntp protocol and check ntp protocol enabled.
    [Tags]  Enable_NTP_Protocol_And_Check_NTP_Protocol_Enabled

    Enable NTP Protocol
    Check NTP Protocol Enabled

Update NTP Address And Check NTP Address Was Updated
    [Documentation]  Update ntp address.
    [Tags]  Update_NTP_Address

    Enable NTP Protocol And Add NTP Addressess
    Check NTP Address Was Updated  ${NTP_SERVER_ADDRESSES}
    Update New NTP Address
    Check NTP Address Was Updated  ${additional_ntp_address}

Disable NTP Protocol And Reboot BMC
    [Documentation]  Disable ntp protocol and reboot bmc.
    [Tags]  Disable_NTP_Protocol_And_Reboot_BMC

    Disable NTP Protocol
    Check NTP Protocol Disabled
    Perform BMC Reboot
    Redfish.Login
    Check NTP Protocol Disabled

Enable NTP Protocol And Reboot BMC
    [Documentation]  Enable ntp protocol and reboot bmc.
    [Tags]  Enable_NTP_Protocol_And_Reboot_BMC

    Enable NTP Protocol
    Check NTP Protocol Enabled
    Perform BMC Reboot
    Redfish.Login
    Check NTP Protocol Enabled

Disable NTP Reboot BMC Enable NTP
    [Documentation]  Disable ntp, reboot bmc and Enable NTP.
    [Tags]  Disable_NTP_Reboot_BMC_Enable_NTP

    Disable NTP Protocol
    Check NTP Protocol Disabled
    Perform BMC Reboot
    Redfish.Login
    Check NTP Protocol Disabled
    ${bmc_rsp}=  BMC Execute Command  date
    ${rsp_lst}=  Convert To List  ${bmc_rsp}
    ${rsp}=  Get From List  ${rsp_lst}  0
    Should Contain  ${rsp}  1970
    ...  msg=NTP Protocol was not disabled
    Enable NTP Protocol And Add NTP Addressess
    Check NTP Protocol Enabled
    Check NTP Address Was Updated  ${NTP_SERVER_ADDRESSES}
    ${bmc_rsp}=  BMC Execute Command  date
    ${rsp_lst}=  Convert To List  ${bmc_rsp}
    ${rsp}=  Get From List  ${rsp_lst}  0
    Should Not Contain  ${rsp}  1970
    ...  msg=NTP Protocol was not enabled

*** Keywords ***
Get NTP Details
    [Documentation]  Return NTP Details.

    ${ntp_details}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/bmc/NetworkProtocol/  NTP

    [Return]  ${ntp_details}

Create Payload For Enable Or Disable NTP Protocol
    [Documentation]  Return payload for ntp protocol.
    [Arguments]  ${ntp_protocol_status}

    # Description Of Arguments:
    # ntp_protocol_status  true, false.

    ${status}=  Set Variable If
    ...  '${ntp_protocol_status}' == 'true'  ${True}
    ...  '${ntp_protocol_status}' == 'false'  ${False}

    ${payload}=  Catenate  {'NTP':{'ProtocolEnabled':${status}}}

    [Return]  ${payload}

Create Payload For Add Or Delete NTP Addressess
    [Documentation]  Return payload for add ntp addressess.
    [Arguments]  ${ntp_address}=${NTP_SERVER_ADDRESSES}

    # Description Of Arguments:
    # ntp_address  list of ntp address.
    # for example["216.239.35.4"].

    ${payload}=  Catenate  {'NTP':{'NTPServers':${ntp_address}}}

    [Return]  ${payload}

Create Payload For NTP Protocol And NTP Addressess
    [Documentation]  Return payload for ntp protocol and ntp addressess.
    [Arguments]  ${ntp_protocol_status}  ${ntp_address}=${NTP_SERVER_ADDRESSES}

    # Description Of Arguments:
    # ntp_protocol_status  true, false.
    # ntp_address  list of ntp address.
    # for example["216.239.35.4"].

    ${status}=  Set Variable If
    ...  '${ntp_protocol_status}' == 'true'  ${True}
    ...  '${ntp_protocol_status}' == 'false'  ${False}

    ${payload}=  Catenate  {'NTP':{'ProtocolEnabled':${status}, 'NTPServers':${ntp_address}}}

    [Return]  ${payload}

Enable NTP Protocol And Add NTP Addressess
    [Documentation]  Enable NTP Protocol and Add NTP Addressess.

    ${payload}=  Create Payload For NTP Protocol And NTP Addressess  true
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/bmc/NetworkProtocol  body=${payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]
    Sleep  2s

Disable NTP Protocol
    [Documentation]  Disable ntp protocol.

    ${payload}=  Create Payload For Enable Or Disable NTP Protocol  false
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/bmc/NetworkProtocol  body=${payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]
    Sleep  5s

Enable NTP Protocol
    [Documentation]  Disable ntp protocol.

    ${payload}=  Create Payload For Enable Or Disable NTP Protocol  true
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/bmc/NetworkProtocol  body=${payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]
    Sleep  2s

Check NTP Protocol Enabled
    [Documentation]  Check NTP protocol enabled.

    ${bmc_rsp}=  BMC Execute Command  ${time_date}
    ${rsp_lst}=  Convert To List  ${bmc_rsp}
    ${rsp}=  Get From List  ${rsp_lst}  0
    ${rsp_line}=  Get Lines Containing String  ${rsp}  NTP service:

    Should Contain  ${rsp_line}  active
    ...  msg=NTP service was not in active

Check NTP Protocol Disabled
    [Documentation]  Check NTP protocol disabled.

    ${bmc_rsp}=  BMC Execute Command  ${time_date}
    ${rsp_lst}=  Convert To List  ${bmc_rsp}
    ${rsp}=  Get From List  ${rsp_lst}  0
    ${rsp_line}=  Get Lines Containing String  ${rsp}  NTP service:

    Should Contain  ${rsp_line}  inactive
    ...  msg=NTP service was in active

Update New NTP Address
    [Documentation]  Update new ntp address.

    ${payload}=  Create Payload For Add Or Delete NTP Addressess  ${additional_ntp_address}
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/bmc/NetworkProtocol  body=${payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]
    Sleep  2s

Check NTP Address Was Updated
    [Documentation]  Validate ntp address was updated.
    [Arguments]  ${ntp_address}

    ${ntp_details}=  Get NTP Details
    Lists Should Be Equal  ${ntp_details['NTPServers']}  ${ntp_address}
    ...  msg=NTP Server addressess are not same

Perform BMC Reboot
    [Documentation]  Do BMC Reboot.

    Redfish BMC Reset Operation
    Wait Until Keyword Succeeds  12 min  10 sec  Ping Host  ${OPENBMC_HOST}
    SSHLibrary.Open Connection    ${OPENBMC_HOST}
    Wait Until Keyword Succeeds  10 min  1 sec  SSHLibrary.Login    ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
