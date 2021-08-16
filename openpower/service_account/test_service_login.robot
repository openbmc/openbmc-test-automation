*** Settings ***
Documentation    This suite is to test service user functionality via Redfish.

Resource         ../../lib/connection_client.robot 
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify Service User Enable With Redfish
    [Documentation]  Verify Service User Enable.
    [Setup]  Remove Existing ACF

    Verify Service Login Fails 
    Upload Valid ACF
    Verify Service Login Succeeds


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login

Remove Existing ACF
    [Documentation]  Remove existing ACF.

    Open Connection  ${HOST}
    Login  ${USERNAME}  ${PASSWORD}
    ${rc}=  Execute Command  rm ${ACF_DIR}/${ACF_FILE}
    Should Be Equal  ${rc}  ${0}
    Close All Connections


Upload Valid ACF
    [Documentation]  Upload valid ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${ACF_FILE}  ${ACF_DIR}


Verify Service Login Fails
    [Documentation]  Verify service user login fails.

    Redfish.Logout
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${service_password} 


Verify Service Login Succeeds
    [Documentation]  Verify service user login succeeds.

    Redfish.Logout
    Redfish.Login  service  ${service_password}
