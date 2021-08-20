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


*** Test Cases ***

Verify Service User Login Fails With Expired ACF
    [Documentation]  Verify service user login fails with expired ACF.
    
    Remove Existing ACF
    Upload Expired ACF
    Verify Service Login Fails


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Upload production key in BMC because it is not part of OpenBMC build yet.
    Run Keywords  Open Connection for SCP
    scp.Put File  ${PRODUCTION_KEY_FILE_PATH}  ${acf_dir}


Remove Existing ACF
    [Documentation]  Remove existing ACF.

    BMC Execute Command  rm -f ${acf_dir}/*.acf 


Upload Expired ACF
    [Documentation]  Upload expired ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${EXPIRED_SERVICE_FILE_PATH}  ${acf_dir}
    ${acf_file_expired}=  Fetch From Right  ${EXPIRED_SERVICE_FILE_PATH}  /\
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  mv ${acf_dir}/${acf_file_expired} ${acf_dir}/${acf_file}
    Should Be True  ${rc} == ${0}


Verify Service Login Fails
    [Documentation]  Verify service user login fails.

    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${SERVICE_PASSWORD}
