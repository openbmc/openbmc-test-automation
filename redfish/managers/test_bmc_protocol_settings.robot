*** Settings ***
Documentation  Test BMC manager protocol enable/disable functionality.

Resource   ../../lib/bmc_redfish_resource.robot
Resource   ../../lib/openbmc_ffdc.robot
Resource   ../../lib/protocol_setting_utils.robot

Suite Setup     Redfish.Login
Suite Teardown  Redfish.Logout
Test Teardown   FFDC On Test Case Fail


*** Variables ***

${cmd_prefix}  ipmitool -I lanplus -C 17 -p 623 -U ${OPENBMC_USERNAME} -P ${OPENBMC_PASSWORD}


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

    Enable SSH Protocol  ${True}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)

    # Check if SSH is really enabled via Redfish.
    Verify SSH Protocol State  ${True}

    # Check if SSH login and commands on SSH session work.
    Verify SSH Login And Commands Work


Disable SSH Protocol And Check Persistency On BMC Reboot
    [Documentation]  Disable SSH protocol and verify persistency.
    [Teardown]  Enable SSH Protocol  ${True}

    # Disable SSH interface.
    Enable SSH Protocol  ${False}

    # Reboot BMC and verify persistency.
    OBMC Reboot (off)

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
    [Teardown]  Enable IPMI Protocol  ${False}

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


*** Keywords ***

