*** Settings ***
Documentation  Test BMC manager protocol enable/disable functionality.

Resource   ../../lib/bmc_redfish_resource.robot
Resource   ../../lib/openbmc_ffdc.robot
Resource   ../../lib/protocol_setting_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Run Keywords  Enable IPMI Protocol  ${initial_ipmi_state}  AND  Redfish.Logout
Test Teardown   FFDC On Test Case Fail

Test Tags      BMC_Protocol_Settings

*** Variables ***

${cmd_prefix}            ipmitool -I lanplus -C 17 -p 623 -U ${IPMI_USERNAME} -P ${IPMI_PASSWORD}
${SETTING_WAIT_TIMEOUT}  30s

@{ADMIN}                 admin_user              ${OPENBMC_PASSWORD}
@{ReadOnly}              readonly_user           ${OPENBMC_PASSWORD}
&{USERS}                 Administrator=${ADMIN}  ReadOnly=${ReadOnly}


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


Enable NTP Protocol And Verify
    [Documentation]  Enable NTP protocol and verify.
    [Tags]  Enable_NTP_Protocol_And_Verify

    Enable NTP Protocol  ${True}

    # Check if NTP is really enabled via Redfish.
    Verify NTP Protocol State  ${True}


Disable NTP Protocol And Verify
    [Documentation]  Disable NTP protocol and verify.
    [Tags]  Disable_NTP_Protocol_And_Verify

    # Disable NTP interface.
    Enable NTP Protocol  ${False}

    # Check if NTP is really disabled via Redfish.
    Verify NTP Protocol State  ${False}


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
    [Template]  Set SSH IPMI And NTP Protocol
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
    [Template]  Set SSH IPMI And NTP Protocol
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Enable SSH Protocol  ${True}

    # ssh_state  ipmi_state  persistency_check
    ${True}      ${False}    ${True}
    ${True}      ${True}     ${True}
    ${False}     ${True}     ${True}
    ${False}     ${False}    ${True}


Configure NTP SSH And IPMI Settings And Verify
    [Documentation]  Set NTP, SSH and IPMI protocol attribute to True/False, and verify.
    [Tags]  Configure_NTP_SSH_And_IPMI_Settings_And_Verify
    [Template]  Set SSH IPMI And NTP Protocol
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Enable SSH Protocol  ${True}

    #ssh_state   ipmi_state   persistency_check   ntp_state
    ${True}      ${False}     ${False}            ${False}
    ${False}     ${True}      ${False}            ${False}
    ${False}     ${True}      ${False}            ${True}
    ${False}     ${False}     ${False}            ${False}
    ${True}      ${True}      ${False}            ${True}


Verify SSH To Port 22 Is Not Allowed Via Admin And ReadOnly User Role
    [Documentation]  Try to establish SSH connection to port 22 with admin and
    ...  readonly user and verify.
    [Tags]  Verify_SSH_To_Port_22_Is_Not_Allowed_Via_Admin_And_ReadOnly_User_Role
    [Setup]  Enable SSH Protocol  ${True}
    [Template]  Check SSH Login To Port 22 Via Different Users
    [Teardown]  Delete BMC Users Via Redfish  users=${USERS}

    # username
    admin_user
    readonly_user


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login

    ${state}=  Run Keyword And Return Status  Verify IPMI Protocol State
    Set Suite Variable  ${initial_ipmi_state}  ${state}
    Sleep  ${NETWORK_TIMEOUT}s


Set SSH IPMI And NTP Protocol
    [Documentation]  Set SSH, IPMI and NTP protocol state.
    [Arguments]  ${ssh_state}  ${ipmi_state}  ${persistency_check}=${False}  ${ntp_state}=''

    # Description of argument(s):
    # ssh_state          State of SSH to be set (e.g. True, False).
    # ipmi_state         State of IPMI to be set (e.g. True, False).
    # ntp_state          State of NTP to be set (e.g. True, False).
    # persistency_check  Persistency check (e.g. True, False).

    ${ssh_protocol_state}=  Create Dictionary  ProtocolEnabled=${ssh_state}
    ${ipmi_protocol_state}=  Create Dictionary  ProtocolEnabled=${ipmi_state}

    IF  ${ntp_state} != ''
        ${ntp_protocol_state}=  Create Dictionary  ProtocolEnabled=${ntp_state}
        ${data}=  Create Dictionary  SSH=${ssh_protocol_state}  IPMI=${ipmi_protocol_state}  NTP=${ntp_protocol_state}
    ELSE
        ${data}=  Create Dictionary  SSH=${ssh_protocol_state}  IPMI=${ipmi_protocol_state}
    END

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for timeout for new values to take effect.
    Sleep  ${SETTING_WAIT_TIMEOUT}

    IF  ${persistency_check} == ${True}
        Redfish OBMC Reboot (off)  stack_mode=skip
    END

    Verify Protocol State  ${ssh_state}  ${ipmi_state}  ${ntp_state}


Verify Protocol State
    [Documentation]  Verify SSH, IPMI and NTP protocol state.
    [Arguments]  ${ssh_state}  ${ipmi_state}  ${ntp_state}=''

    # Description of argument(s):
    # ssh_state     State of SSH to be verified (e.g. True, False).
    # ipmi_state    State of IPMI to be verified (e.g. True, False).
    # ntp_state     State of NTP to be verified (e.g. True, False).

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

    # Verify NTP state value via Redfish.
    IF  ${ntp_state} != ''
        ${resp}=  Redfish.Get  ${REDFISH_NW_PROTOCOL_URI}
        Should Be Equal As Strings  ${resp.dict['NTP']['ProtocolEnabled']}  ${ntp_state}
        ...  msg=NTP protocol states are not matching.
    END


Check SSH Login To Port 22 Via Different Users
    [Documentation]  Check if SSH connection to port 22 works via different users.
    [Arguments]  ${username}  ${host}=${OPENBMC_HOST}

    # Description of argument(s}:
    # host         OPENBMC_HOST, OPENBMC_HOST_1, Use eth0 as the default interface.
    # username     Username to be used to check login. (e.g. admin or read_only)

    # Create users with admin & read only previlige.
    Create Users With Different Roles  users=${USERS}  force=${True}

    # Check if we can open SSH connection and login.
    SSHLibrary.Open Connection  ${host}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${username}  ${OPENBMC_PASSWORD}

    IF  '${username}' == 'service'
        Should Be Equal  ${status}  ${True}
        ...  msg=Connection is allowed & able to login via service user.
    ELSE
        Should Be Equal  ${status}  ${False}
        ...  msg=Connection is not allowed to port 22 via admin or readonly user.
    END
