*** Settings ***
Documentation       Test BMC manager protocol enable/disable functionality.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/protocol_setting_utils.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Run Keywords    Enable IPMI Protocol    ${initial_ipmi_state}    AND    Redfish.Logout
Test Teardown       FFDC On Test Case Fail

Test Tags           bmc_protocol_settings


*** Variables ***
${cmd_prefix}               ipmitool -I lanplus -C 17 -p 623 -U ${IPMI_USERNAME} -P ${IPMI_PASSWORD}
${SETTING_WAIT_TIMEOUT}     30s


*** Test Cases ***
Verify SSH Is Enabled By Default
    [Documentation]    Verify SSH is enabled by default.
    [Tags]    verify_ssh_is_enabled_by_default

    # Check if SSH is enabled by default.
    Verify SSH Protocol State    ${True}

Enable SSH Protocol And Verify
    [Documentation]    Enable SSH protocol and verify.
    [Tags]    enable_ssh_protocol_and_verify

    Enable SSH Protocol    ${True}

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State    ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work

Disable SSH Protocol And Verify
    [Documentation]    Disable SSH protocol and verify.
    [Tags]    disable_ssh_protocol_and_verify

    # Disable SSH interface.
    Enable SSH Protocol    ${False}

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State    ${False}

    # Check if SSH login and commands fail.
    ${status}=    Run Keyword And Return Status
    ...    Verify SSH Login And Commands Work

    Should Be Equal As Strings    ${status}    False
    ...    msg=SSH Login and commands are working after disabling SSH.
    [Teardown]    Enable SSH Protocol    ${True}

Enable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]    Enable SSH protocol and verify persistency.
    [Tags]    enable_ssh_protocol_and_check_persistency_on_bmc_reboot

    Enable SSH Protocol    ${True}

    # Reboot BMC and verify persistency.
    Redfish OBMC Reboot (off)    stack_mode=skip

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State    ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work

Disable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]    Disable SSH protocol and verify persistency.
    [Tags]    disable_ssh_protocol_and_check_persistency_on_bmc_reboot

    # Disable SSH interface.
    Enable SSH Protocol    ${False}

    # Reboot BMC and verify persistency.
    Redfish OBMC Reboot (off)    stack_mode=skip

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State    ${False}

    # Check if SSH login and commands fail.
    ${status}=    Run Keyword And Return Status
    ...    Verify SSH Login And Commands Work

    Should Be Equal As Strings    ${status}    False
    ...    msg=SSH Login and commands are working after disabling SSH.
    [Teardown]    Enable SSH Protocol    ${True}

Verify Disabling SSH Port Does Not Disable Serial Console Port
    [Documentation]    Verify disabling SSH does not disable serial console port.
    [Tags]    verify_disabling_ssh_port_does_not_disable_serial_console_port

    # Disable SSH interface.
    Enable SSH Protocol    ${False}

    # Check able to establish connection with serial port console.
    Open Connection And Log In    host=${OPENBMC_HOST}    port=2200
    Close All Connections
    [Teardown]    Enable SSH Protocol    ${True}

Verify Existing SSH Session Gets Closed On Disabling SSH
    [Documentation]    Verify existing SSH session gets closed on disabling ssh.
    [Tags]    verify_existing_ssh_session_gets_closed_on_disabling_ssh

    # Open SSH connection.
    Open Connection And Login

    # Disable SSH interface.
    Enable SSH Protocol    ${False}

    # Check if SSH is really disabled via Redfish.
    Verify SSH Protocol State    ${False}

    # Try to execute CLI command on SSH connection.
    # It should fail as disable SSH will close pre existing sessions.
    ${status}=    Run Keyword And Return Status
    ...    BMC Execute Command    /sbin/ip addr

    Should Be Equal As Strings    ${status}    False
    ...    msg=Disabling SSH has not closed existing SSH sessions.
    [Teardown]    Enable SSH Protocol    ${True}

Enable IPMI Protocol And Verify
    [Documentation]    Enable IPMI protocol and verify.
    [Tags]    enable_ipmi_protocol_and_verify

    Enable IPMI Protocol    ${True}

    # Check if IPMI is really enabled via Redfish.
    Verify IPMI Protocol State    ${True}

    # Check if IPMI commands starts working.
    Verify IPMI Works    lan print

Disable IPMI Protocol And Verify
    [Documentation]    Disable IPMI protocol and verify.
    [Tags]    disable_ipmi_protocol_and_verify

    # Disable IPMI interface.
    Enable IPMI Protocol    ${False}

    # Check if IPMI is really disabled via Redfish.
    Verify IPMI Protocol State    ${False}

    # Check if IPMI commands fail.
    ${status}=    Run Keyword And Return Status
    ...    Verify IPMI Works    lan print

    Should Be Equal As Strings    ${status}    False
    ...    msg=IPMI commands are working after disabling IPMI.

Enable IPMI Protocol And Check Persistency On BMC Reboot
    [Documentation]    Set the IPMI protocol attribute to True, reset BMC, and verify
    ...    that the setting persists.
    [Tags]    enable_ipmi_protocol_and_check_persistency_on_bmc_reboot

    Enable IPMI Protocol    ${True}

    Redfish OBMC Reboot (off)    stack_mode=skip

    # Check if the IPMI enabled is set.
    Verify IPMI Protocol State    ${True}

    # Confirm that IPMI commands to access BMC work.
    Verify IPMI Works    lan print

Disable IPMI Protocol And Check Persistency On BMC Reboot
    [Documentation]    Set the IPMI protocol attribute to False, reset BMC, and verify
    ...    that the setting persists.
    [Tags]    disable_ipmi_protocol_and_check_persistency_on_bmc_reboot

    # Disable IPMI interface.
    Enable IPMI Protocol    ${False}

    Redfish OBMC Reboot (off)    stack_mode=skip

    # Check if the IPMI disabled is set.
    Verify IPMI Protocol State    ${False}

    # Confirm that IPMI connection request fails.
    ${status}=    Run Keyword And Return Status
    ...    Verify IPMI Works    lan print

    Should Be Equal As Strings    ${status}    False
    ...    msg=IPMI commands are working after disabling IPMI.

Configure SSH And IPMI Settings And Verify
    [Documentation]    Set the SSH and IPMI protocol attribute to True/False, and verify.
    [Tags]    configure_ssh_and_ipmi_settings_and_verify
    [Template]    Set SSH And IPMI Protocol

    # ssh_state    ipmi_state
    ${True}    ${False}
    ${True}    ${True}
    ${False}    ${True}
    ${False}    ${False}
    [Teardown]    Run Keywords    FFDC On Test Case Fail
    ...    AND    Enable SSH Protocol    ${True}

Configure SSH And IPMI Settings And Verify Persistency On BMC Reboot
    [Documentation]    Set the SSH and IPMI protocol attribute to True/False, and verify
    ...    it's persistency after BMC reboot.
    [Tags]    configure_ssh_and_ipmi_settings_and_verify_persistency_on_bmc_reboot
    [Template]    Set SSH And IPMI Protocol

    # ssh_state    ipmi_state    persistency_check
    ${True}    ${False}    ${True}
    ${True}    ${True}    ${True}
    ${False}    ${True}    ${True}
    ${False}    ${False}    ${True}
    [Teardown]    Run Keywords    FFDC On Test Case Fail
    ...    AND    Enable SSH Protocol    ${True}


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do suite setup tasks.

    Redfish.Login

    ${state}=    Run Keyword And Return Status    Verify IPMI Protocol State
    Set Suite Variable    ${initial_ipmi_state}    ${state}
    Sleep    ${NETWORK_TIMEOUT}s

Set SSH And IPMI Protocol
    [Documentation]    Set SSH and IPMI protocol state.
    [Arguments]    ${ssh_state}    ${ipmi_state}    ${persistency_check}=${False}

    # Description of argument(s):
    # ssh_state    State of SSH to be set (e.g. True, False).
    # ipmi_state    State of IPMI to be set (e.g. True, False).

    ${ssh_protocol_state}=    Create Dictionary    ProtocolEnabled=${ssh_state}
    ${ipmi_protocol_state}=    Create Dictionary    ProtocolEnabled=${ipmi_state}
    ${data}=    Create Dictionary    SSH=${ssh_protocol_state}    IPMI=${ipmi_protocol_state}

    Redfish.Patch    ${REDFISH_NW_PROTOCOL_URI}    body=&{data}
    ...    valid_status_codes=[${HTTP_NO_CONTENT}]

    # Wait for timeout for new values to take effect.
    Sleep    ${SETTING_WAIT_TIMEOUT}

    IF    ${persistency_check} == ${True}
        Redfish OBMC Reboot (off)    stack_mode=skip
    END
    Verify Protocol State    ${ssh_state}    ${ipmi_state}

Verify Protocol State
    [Documentation]    Verify SSH and IPMI protocol state.
    [Arguments]    ${ssh_state}    ${ipmi_state}

    # Description of argument(s):
    # ssh_state    State of SSH to be verified (e.g. True, False).
    # ipmi_state    State of IPMI to be verified (e.g. True, False).

    # Verify SSH state value.
    ${status}=    Run Keyword And Return Status
    ...    Verify SSH Login And Commands Work
    Should Be Equal As Strings    ${status}    ${ssh_state}
    ...    msg=SSH states are not matching.

    # Verify IPMI state value.
    ${status}=    Run Keyword And Return Status
    ...    Verify IPMI Works    lan print

    Should Be Equal As Strings    ${status}    ${ipmi_state}
    ...    msg=IPMI states are not matching.
