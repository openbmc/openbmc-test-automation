*** Settings ***
Documentation    This suite is to test service user login functionality.
...              This test expects SERVICE_FILE_PATH, PRODUCTION_KEY_FILE_PATH and
...              SERVICE_USER_PASSWORD to be provided.
...
...              Execution Method :
...              python -m robot -v OPENBMC_HOST:<hostname> -v SERVICE_FILE_PATH:<service file path>
...              -v PRODUCTION_KEY_FILE_PATH:<production key file path>
...              -v SERVICE_USER_PASSWORD:<service user password>
...              openpower/service_account/test_service_login.robot

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

Verify Service User Login With Valid ACF file
    [Documentation]  Verify service user login with valid ACF file.
    [Tags]  Verify_Service_User_Login_With_Valid_ACF_file

    Upload Valid ACF
    Redfish.Login  service  ${SERVICE_USER_PASSWORD}


Verify Service User Login Without ACF file
    [Documentation]  Verify service user login without ACF file.
    [Tags]  Verify_Service_User_Login_Without_ACF_file

    Remove Existing ACF
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${SERVICE_USER_PASSWORD}


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


Upload Valid ACF
    [Documentation]  Upload valid ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${SERVICE_FILE_PATH}  ${acf_dir}


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
