*** Settings ***
Documentation    This suite is to test service user login functionality.

Resource         ../../lib/connection_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail


*** Variables ***

${acf_file}           service.acf
${acf_dir}            /etc/acf
${production_key}     ibmacf-prod.key
${acf_file_expired}   service_expired.acf

*** Test Cases ***

Verify Service User Login Fails With Expired ACF
    [Documentation]  Verify service user login fails with expired ACF.
    [Setup]  Remove Existing ACF

    Upload Expired ACF
    Verify Service Login Fails


*** Keywords ***

Remove Existing ACF
    [Documentation]  Remove existing ACF.

    BMC Execute Command  rm -f ${ACF_DIR}/${ACF_FILE}


Upload Expired ACF
    [Documentation]  Upload expired ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${acf_file_expired}  ${acf_dir}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  mv ${acf_dir}/${acf_file_expired} ${acf_dir}/${acf_file}
    Should Be True  ${rc} == ${0}


Verify Service Login Fails
    [Documentation]  Verify service user login fails.

    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${SERVICE_PASSWORD}
