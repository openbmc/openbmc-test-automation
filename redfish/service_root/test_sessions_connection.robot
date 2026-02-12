*** Settings ***
Documentation    Test Redfish session and its connection stability.

Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Set Redfish Delete Session Flag  ${0}
Suite Teardown   Run Keywords  Set Redfish Delete Session Flag  ${1}  AND  Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

Test Tags        Sessions_Connection

*** Variables ***

${DURATION}                 6h
${INTERVAL}                 30s
${REBOOT_INTERVAL}          30m

*** Test Cases ***

Create Session And Check Connection Stability
    [Documentation]  Send heartbeat on session continuously and verify connection stability.
    [Tags]  Create_Session_And_Check_Connection_Stability
    [Setup]  Redfish.Logout

    # Clear old session and start new session.
    Redfish.Login

    Repeat Keyword  ${DURATION}  Send Heartbeat


Create Session And Check Connection Stability On Reboot
    [Documentation]  Create Session And Check Connection Stability On Reboot
    [Tags]  Create_Session_And_Check_Connection_Stability_On_Reboot
    [Setup]  Redfish.Logout

    # Clear old session and start new session.
    Redfish.Login

    Repeat Keyword  ${DURATION}  Check Connection On Reboot

*** Keywords ***

Send Heartbeat
    [Documentation]  Send heartbeat to BMC.

    Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName
    Sleep  ${INTERVAL}


Check Connection On Reboot
    [Documentation]  Send heartbeat on BMC reboot.

    # Reboot BMC
    Redfish OBMC Reboot (Off)

    # Verify session is still active and no issues on connection after reboot.
    Repeat Keyword  ${REBOOT_INTERVAL}  Send Heartbeat
