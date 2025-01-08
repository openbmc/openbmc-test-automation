*** Settings ***
Documentation                NTP configuration and verification
                             ...  tests.

Resource                     ../../lib/openbmc_ffdc.robot
Resource                     ../../lib/bmc_date_and_time_utils.robot

Test Setup                   Printn
Test Teardown                FFDC On Test Case Fail
Suite Setup                  Suite Setup Execution
Suite Teardown               Suite Teardown Execution


*** Variables ***

${ntp_server_1}              9.9.9.9
${ntp_server_2}              2.2.3.3
&{original_ntp}              &{EMPTY}

*** Test Cases ***

Verify NTP Server Set
    [Documentation]  Patch NTP servers and verify NTP servers is set.
    [Tags]  Verify_NTP_Server_Set
    [Setup]  Set NTP state  ${True}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'NTPServers': ['${ntp_server_1}', '${ntp_server_2}']}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # NTP network take few seconds to reload.
    Wait Until Keyword Succeeds  30 sec  10 sec  Verify NTP Servers Are Populated


Verify NTP Server Value Not Duplicated
    [Documentation]  Verify NTP servers value not same for both primary and secondary server.
    [Tags]  Verify_NTP_Server_Value_Not_Duplicated

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'NTPServers': ['${ntp_server_1}', '${ntp_server_1}']}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${network_protocol}=  Redfish.Get Properties  ${REDFISH_NW_PROTOCOL_URI}
    Should Contain X Times  ${network_protocol["NTP"]["NTPServers"]}  ${ntp_server_1}  1
    ...  msg=NTP primary and secondary server values should not be same.


Verify NTP Server Setting Persist After BMC Reboot
    [Documentation]  Verify NTP server setting persist after BMC reboot.
    [Tags]  Verify_NTP_Server_Setting_Persist_After_BMC_Reboot
    [Setup]  Set NTP state  ${True}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'NTPServers': ['${ntp_server_1}', '${ntp_server_2}']}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Redfish OBMC Reboot (off)
    Redfish.Login

    # NTP network take few seconds to reload.
    Wait Until Keyword Succeeds  30 sec  10 sec  Verify NTP Servers Are Populated


Verify Enable NTP
    [Documentation]  Verify NTP protocol mode can be enabled.
    [Teardown]  Restore NTP Mode
    [Tags]  Verify_Enable_NTP

    # The following patch command should set the ["NTP"]["ProtocolEnabled"] property to "True".
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${True}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Wait Until Keyword Succeeds  1 min  5 sec
    ...  Verify System Time Sync Status  ${True}
    ${ntp}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  NTP
    Rprint Vars  ntp
    Valid Value  ntp["ProtocolEnabled"]  valid_values=[True]

Verify Disable NTP
    [Documentation]  Verify NTP protocol mode can be disabled.
    [Teardown]  Restore NTP Mode
    [Tags]  Verify_Disable_NTP

    # The following patch command should set the ["NTP"]["ProtocolEnabled"] property to "False".
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Wait Until Keyword Succeeds  1 min  5 sec
    ...  Verify System Time Sync Status  ${False}
    ${ntp}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  NTP
    Rprint Vars  ntp
    Valid Value  ntp["ProtocolEnabled"]  valid_values=[False]

Verify Set DateTime With NTP Enabled
    [Documentation]  Verify whether set managers dateTime is restricted with NTP enabled.
    [Tags]  Verify_Set_DateTime_With_NTP_Enabled

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${True}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${ntp}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  NTP
    Valid Value  ntp["ProtocolEnabled"]  valid_values=[True]
    ${local_system_time}=  Get Current Date
    Redfish Set DateTime  ${local_system_time}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}, ${HTTP_INTERNAL_SERVER_ERROR}]

Verify NTP Server Is Not Populated In NetworkSupppliedServers
    [Documentation]  Patch NTP servers and verify NTP servers is not populated in NetworkSuppliedServers.
    [Tags]  Verify_NTP_Server_Is_Not_Populated_In_NetworkSupppliedServers
    [Setup]  Set NTP state  ${True}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'NTPServers': ['${ntp_server_1}']}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # NTP network take few seconds to reload.
    Wait Until Keyword Succeeds  30 sec  10 sec  Verify NTP Servers Are Populated
    # NetworkSuppliedServers has the DHCP NTP server list.
    Verify NTP Servers Are Not Populated In NetworkSuppliedServers

*** Keywords ***

Verify NTP Servers Are Not Populated In NetworkSuppliedServers
    [Documentation]  Redfish GET request /redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol response
    ...              and verify if NTP servers are populated.

    ${network_protocol}=  Redfish.Get Properties  ${REDFISH_NW_PROTOCOL_URI}
    Should Not Contain  ${network_protocol["NTP"]["NetworkSuppliedServers"]}  ${ntp_server_1}
    ...  msg=Static NTP server is coming up in NetworkSuppliedServers.

Suite Setup Execution
    [Documentation]  Do the suite level setup.

    Printn
    Redfish.Login
    Get NTP Initial Status
    ${old_date_time}=  CLI Get BMC DateTime
    ${year_status}=  Run Keyword And Return Status  Should Not Contain  ${old_date_time}  ${year_without_ntp}
    Run Keyword If  ${year_status} == False
    ...  Enable NTP And Add NTP Address

Suite Teardown Execution
    [Documentation]  Do the suite level teardown.

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'NTPServers': ['${EMPTY}', '${EMPTY}']}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    Restore NTP Status
    Redfish.Logout
