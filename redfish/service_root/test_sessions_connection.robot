*** Settings ***

Documentation    Test Redfish session and its connection stability.

Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Disable Redfish Delete Session
Suite Teardown   Run Keywords  Enable Redfish Delete Session  AND  Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Variables ***

${duration}                 6h
${interval}                 30s
${reboot_interval}          30m
${REDFISH_DELETE_SESSIONS}  ${0}


*** Test Cases ***

Create Session And Check Connection Stability
    [Documentation]  Send heartbeat on session continuously and verify connection stability.
    [Tags]  Create_Session_And_Check_Connection_Stability
    [Setup]  Redfish.logout

    # Clear old session and start new session.
    Redfish.Login

    Repeat Keyword  ${duration}  Send Heartbeat


Create Session And Check Connection Stability On Reboot
    [Documentation]  Create Session And Check Connection Stability On Reboot
    [Tags]  Create_Session_And_Check_Connection_Stability_On_Reboot
    [Setup]  Redfish.logout

    # Clear old session and start new session.
    Redfish.Login

    Repeat Keyword  ${duration}  Check Connection On Reboot


*** Keywords ***

Send Heartbeat
    [Documentation]  Send heartbeat to BMC.

    ${hostname}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    Sleep  ${interval}


Check Connection On Reboot
    [Documentation]  Send heartbeat on BMC reboot.

    # Reboot BMC
    Redfish OBMC Reboot (Off)

    # Verify session is still active and no issues on connection after reboot.
    Repeat Keyword  ${reboot_interval}  Send Heartbeat

Disable Redfish Delete Session
    [Documentation]  Disable delete redfish while performing power operation keyword.

    ${REDFISH_DELETE_SESSIONS}=  Set Variable  ${0}
    Set Suite Variable  ${REDFISH_DELETE_SESSIONS}

Enable Redfish Delete Session
    [Documentation]  Enable delete redfish while performing power operation keyword.

    ${REDFISH_DELETE_SESSIONS}=  Set Variable  ${1}
    Set Suite Variable  ${REDFISH_DELETE_SESSIONS}