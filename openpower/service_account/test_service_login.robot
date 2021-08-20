*** Settings ***
Documentation    This suite is to test service user login functionality with ACF availability.

Resource         ../../lib/connection_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Variables ***

${ACF_FILE}           service.acf
${ACF_DIR}            /etc/acf
${PRODUCTION_KEY}     ibmacf-prod.key
${ACF_FILE_EXPIRED}   service_expired.acf

*** Test Cases ***

Verify Service User Login Fails With Expired ACF 
    [Documentation]  Verify service user login fails with expired ACF.
    [Setup]  Remove Existing ACF

    Upload Expired ACF 
    Verify Service Login Fails 


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login


Remove Existing ACF
    [Documentation]  Remove existing ACF.

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  rm -f ${ACF_DIR}/${ACF_FILE}
    Should Be True  ${rc} == ${0}


Upload Expired ACF
    [Documentation]  Upload expired ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${ACF_FILE_EXPIRED}  ${ACF_DIR}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  mv ${ACF_DIR}/${ACF_FILE_EXPIRED} ${ACF_DIR}/${ACF_FILE}
    Should Be True  ${rc} == ${0}


Verify Service Login Fails
    [Documentation]  Verify service user login fails.

    Redfish.Logout
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${service_password}
