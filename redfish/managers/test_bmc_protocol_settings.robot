*** Settings ***
Documentation  Test BMC manager protocol enable/disable functionality.

Resource   ../../lib/bmc_redfish_resource.robot
Resource   ../../lib/bmc_network_utils.robot
Resource   ../../lib/openbmc_ffdc.robot
Resource   ../../lib/protocol_setting_utils.robot
Library    ../../lib/bmc_network_utils.py
Library    Collections

Suite Setup     Suite Setup Execution
Suite Teardown  Run Keywords  Enable IPMI Protocol  ${initial_ipmi_state}  AND  Redfish.Logout
Test Teardown   FFDC On Test Case Fail


*** Variables ***

${cmd_prefix}              ipmitool -I lanplus -C 17 -p 623 -U ${IPMI_USERNAME} -P ${IPMI_PASSWORD}
${SETTING_WAIT_TIMEOUT}    30s
${time_date}               timedatectl
@{additional_ntp_address}  14.139.60.103  14.139.60.106  14.139.60.107

*** Test Cases ***

Verify SSH Is Enabled By Default
    [Documentation]  Verify SSH is enabled by default.
    [Tags]  Verify_SSH_Is_Enabled_By_Default

    # Check if SSH is enabled by default.
    Verify SSH Protocol State  ${True}


Enable SSH Protocol And Verify
    [Documentation]  Enable SSH protocol and verify.
    [Tags]  Enable_SSH_Protocol_And_Verify

    Enable SSH Protocol  ${True}

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State  ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work


Disable SSH Protocol And Verify
    [Documentation]  Disable SSH protocol and verify.
    [Tags]  Disable_SSH_Protocol_And_Verify
    [Teardown]  Enable SSH Protocol  ${True}

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State  ${False}

    # Check if SSH login and commands fail.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.


Enable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]  Enable SSH protocol and verify persistency.
    [Tags]  Enable_SSH_Protocol_And_Check_Persistency_On_BMC_Reboot

    Enable SSH Protocol  ${True}

    # Reboot BMC and verify persistency.
    Redfish OBMC Reboot (off)  stack_mode=skip

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State  ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work


Disable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]  Disable SSH protocol and verify persistency.
    [Tags]  Disable_SSH_Protocol_And_Check_Persistency_On_BMC_Reboot
    [Teardown]  Enable SSH Protocol  ${True}

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Reboot BMC and verify persistency.
    Redfish OBMC Reboot (off)  stack_mode=skip

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State  ${False}

    # Check if SSH login and commands fail.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work

    Should Be Equal As Strings  ${status}  False
    ...  msg=SSH Login and commands are working after disabling SSH.


Verify Disabling SSH Port Does Not Disable Serial Console Port
    [Documentation]  Verify disabling SSH does not disable serial console port.
    [Tags]  Verify_Disabling_SSH_Port_Does_Not_Disable_Serial_Console_Port
    [Teardown]  Enable SSH Protocol  ${True}

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Check able to establish connection with serial port console.
    Open Connection And Log In  host=${OPENBMC_HOST}  port=2200
    Close All Connections


Verify Existing SSH Session Gets Closed On Disabling SSH
    [Documentation]  Verify existing SSH session gets closed on disabling ssh.
    [Tags]  Verify_Existing_SSH_Session_Gets_Closed_On_Disabling_SSH
    [Teardown]  Enable SSH Protocol  ${True}

    # Open SSH connection.
    Open Connection And Login

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State  ${False}

    # Try to execute CLI command on SSH connection.
    # It should fail as disable SSH will close pre existing sessions.
    ${status}=  Run Keyword And Return Status
    ...  BMC Execute Command  /sbin/ip addr

    Should Be Equal As Strings  ${status}  False
    ...  msg=Disabling SSH has not closed existing SSH sessions.


Enable IPMI Protocol And Verify
    [Documentation]  Enable IPMI protocol and verify.
    [Tags]  Enable_IPMI_Protocol_And_Verify

    Enable IPMI Protocol  ${True}

    # Check if IPMI is really enabled via Redfish.
    Verify IPMI Protocol State  ${True}

    # Check if IPMI commands starts working.
    Verify IPMI Works  lan print


Disable IPMI Protocol And Verify
    [Documentation]  Disable IPMI protocol and verify.
    [Tags]  Disable_IPMI_Protocol_And_Verify

    # Disable IPMI interface.
    Enable IPMI Protocol  ${False}

    # Check if IPMI is really disabled via Redfish.
    Verify IPMI Protocol State  ${False}

    # Check if IPMI commands fail.
    ${status}=  Run Keyword And Return Status
    ...  Verify IPMI Works  lan print

    Should Be Equal As Strings  ${status}  False
    ...  msg=IPMI commands are working after disabling IPMI.


Enable IPMI Protocol And Check Persistency On BMC Reboot
    [Documentation]  Set the IPMI protocol attribute to True, reset BMC, and verify
    ...              that the setting persists.
    [Tags]  Enable_IPMI_Protocol_And_Check_Persistency_On_BMC_Reboot

    Enable IPMI Protocol  ${True}

    Redfish OBMC Reboot (off)  stack_mode=skip

    # Check if the IPMI enabled is set.
    Verify IPMI Protocol State  ${True}

    # Confirm that IPMI commands to access BMC work.
    Verify IPMI Works  lan print


Disable IPMI Protocol And Check Persistency On BMC Reboot
    [Documentation]  Set the IPMI protocol attribute to False, reset BMC, and verify
    ...              that the setting persists.
    [Tags]  Disable_IPMI_Protocol_And_Check_Persistency_On_BMC_Reboot

    # Disable IPMI interface.
    Enable IPMI Protocol  ${False}

    Redfish OBMC Reboot (off)  stack_mode=skip

    # Check if the IPMI disabled is set.
    Verify IPMI Protocol State  ${False}

    # Confirm that IPMI connection request fails.
    ${status}=  Run Keyword And Return Status
    ...  Verify IPMI Works  lan print

    Should Be Equal As Strings  ${status}  False
    ...  msg=IPMI commands are working after disabling IPMI.


Configure SSH And IPMI Settings And Verify
    [Documentation]  Set the SSH and IPMI protocol attribute to True/False, and verify.
    [Tags]  Configure_SSH_And_IPMI_Settings_And_Verify
    [Template]  Set SSH And IPMI Protocol
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Enable SSH Protocol  ${True}

    # ssh_state  ipmi_state
    ${True}      ${False}
    ${True}      ${True}
    ${False}     ${True}
    ${False}     ${False}


Configure SSH And IPMI Settings And Verify Persistency On BMC Reboot
    [Documentation]  Set the SSH and IPMI protocol attribute to True/False, and verify
    ...  it's persistency after BMC reboot.
    [Tags]  Configure_SSH_And_IPMI_Settings_And_Verify_Persistency_On_BMC_Reboot
    [Template]  Set SSH And IPMI Protocol
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Enable SSH Protocol  ${True}

    # ssh_state  ipmi_state  persistency_check
    ${True}      ${False}    ${True}
    ${True}      ${True}     ${True}
    ${False}     ${True}     ${True}
    ${False}     ${False}    ${True}


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
    Check NTP Protocol Disabled


Enable NTP Protocol And Reboot BMC
    [Documentation]  Enable ntp protocol and reboot bmc.
    [Tags]  Enable_NTP_Protocol_And_Reboot_BMC

    Enable NTP Protocol
    Check NTP Protocol Enabled
    Perform BMC Reboot
    Check NTP Protocol Enabled


Disable NTP Reboot BMC Enable NTP
    [Documentation]  Disable ntp, reboot bmc and Enable NTP.
    [Tags]  Disable_NTP_Reboot_BMC_Enable_NTP
    [Teardown]  Run Keywords  Redfish.Login  AND
    ...  Enable NTP Protocol And Add NTP Addressess  AND
    ...  Check NTP Protocol Enabled  AND
    ...  Sleep  30s

    Disable NTP Protocol
    Check NTP Protocol Disabled
    Perform BMC Reboot
    Sleep  30s
    Check NTP Protocol Disabled
    ${bmc_rsp}=  BMC Execute Command  date
    ${rsp_lst}=  Convert To List  ${bmc_rsp}
    ${rsp}=  Get From List  ${rsp_lst}  0
    ${rtc_status}=  Check RTC Status  ${rsp}
    IF  ${rtc_status} == ${False}
        Should Contain  ${rsp}  1970
        ...  msg=NTP Protocol was not disabled
    Else
        Should Not Contain  ${rsp}  1970
        ...  msg=Even though RTC is there, bmc reverting back to 1970.
    END

    Enable NTP Protocol And Add NTP Addressess
    Check NTP Protocol Enabled
    Check NTP Address Was Updated  ${NTP_SERVER_ADDRESSES}
    ${bmc_rsp}=  BMC Execute Command  date
    ${rsp_lst}=  Convert To List  ${bmc_rsp}
    ${rsp}=  Get From List  ${rsp_lst}  0
    Should Not Contain  ${rsp}  1970
    ...  msg=NTP Protocol was not enabled

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login

    ${state}=  Run Keyword And Return Status  Verify IPMI Protocol State
    Set Suite Variable  ${initial_ipmi_state}  ${state}
    Sleep  ${NETWORK_TIMEOUT}s


Set SSH And IPMI Protocol
    [Documentation]  Set SSH and IPMI protocol state.
    [Arguments]  ${ssh_state}  ${ipmi_state}  ${persistency_check}=${False}

    # Description of argument(s):
    # ssh_state     State of SSH to be set (e.g. True, False).
    # ipmi_state    State of IPMI to be set (e.g. True, False).

    ${ssh_protocol_state}=  Create Dictionary  ProtocolEnabled=${ssh_state}
    ${ipmi_protocol_state}=  Create Dictionary  ProtocolEnabled=${ipmi_state}
    ${data}=  Create Dictionary  SSH=${ssh_protocol_state}  IPMI=${ipmi_protocol_state}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for timeout for new values to take effect.
    Sleep  ${SETTING_WAIT_TIMEOUT}

    Run Keyword if  ${persistency_check} == ${True}
    ...  Redfish OBMC Reboot (off)  stack_mode=skip
    Verify Protocol State  ${ssh_state}  ${ipmi_state}


Verify Protocol State
    [Documentation]  Verify SSH and IPMI protocol state.
    [Arguments]  ${ssh_state}  ${ipmi_state}

    # Description of argument(s):
    # ssh_state     State of SSH to be verified (e.g. True, False).
    # ipmi_state    State of IPMI to be verified (e.g. True, False).

    # Verify SSH state value.
    ${status}=  Run Keyword And Return Status
    ...  Verify SSH Login And Commands Work
    Should Be Equal As Strings  ${status}  ${ssh_state}
    ...  msg=SSH states are not matching.

    # Verify IPMI state value.
    ${status}=  Run Keyword And Return Status
    ...  Verify IPMI Works  lan print

    Should Be Equal As Strings  ${status}  ${ipmi_state}
    ...  msg=IPMI states are not matching.


Get NTP Details
    [Documentation]  Return NTP Details.

    ${ntp_details}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}/NetworkProtocol/  NTP

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
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}/NetworkProtocol  body=${payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]
    Sleep  2s


Disable NTP Protocol
    [Documentation]  Disable ntp protocol.

    ${payload}=  Create Payload For Enable Or Disable NTP Protocol  false
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}/NetworkProtocol  body=${payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]
    Sleep  10s


Enable NTP Protocol
    [Documentation]  Disable ntp protocol.

    ${payload}=  Create Payload For Enable Or Disable NTP Protocol  true
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}/NetworkProtocol  body=${payload}
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
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}/NetworkProtocol  body=${payload}
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
    # Get the BMC Status.
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational


Check RTC Status
    [Documentation]  Will Check RTC is available in Test Server. Retur True if RTC
    ...  available in the server or else it will return Flase.
    [Arguments]  ${time_date_resp}

    # ${bmc_rsp}=  BMC Execute Command  ${time_date}
    # ${rsp_lst}=  Convert To List  ${bmc_rsp}
    # ${rsp}=  Get From List  ${rsp_lst}  0
    ${rtc_match}=  Get Regexp Matches  ${time_date_resp}  RTC time:\\s+n/a
    ${status}=  Set Variable If  ${rtc_match} != []
    ...  ${Flase}
    ...  ${True}
    Log To Console  ${status}

    [Return]  ${status}
