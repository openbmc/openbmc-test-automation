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


Verify Service User SSH Login Without ACF file
    [Documentation]  Verify service user ssh login failure without ACF file.
    [Tags]  Verify_Service_User_SSH_Login_Without_ACF_file

    Remove Existing ACF
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  service  ${SERVICE_USER_PASSWORD}
    Should Be Equal  ${status}  ${False}


Verify Service Login Failure With Expired ACF
    [Documentation]  Verify service user login failure with expired ACF.
    [Tags]  Verify_Service_Login_Failure_With_Expired_ACF
    [Setup]  Valid Value EXPIRED_SERVICE_FILE_PATH

    Remove Existing ACF
    Open Connection for SCP
    scp.Put File  ${EXPIRED_SERVICE_FILE_PATH}  ${acf_dir}
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${SERVICE_USER_PASSWORD}


Verify Service Login Failure With Incorrect Password
    [Documentation]  Verify service login failure with incorrect password.
    [Tags]  Verify_Service_Login_Failure_With_Incorrect_Password

    Remove Existing ACF
    Upload Valid ACF
    ${incorrect_service_password} =  Catenate  SEPARATOR=  ${SERVICE_USER_PASSWORD}  123
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${incorrect_service_password}


Verify SSH Login Access With Service User
    [Documentation]  Verify SSH login access with service user.
    [Tags]  Verify_SSH_Login_Access_With_Service_User
    [Setup]  Remove Existing ACF  AND  Upload Valid ACF

    # Attempt SSH login with service user.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  service  ${SERVICE_USER_PASSWORD}
    Should Be Equal  ${status}  ${True}


Verify SSH Login Failure With Incorrect Service User Password
    [Documentation]  Verify SSH login failure with incorrect service user password.
    [Tags]  Verify_SSH_Login_Failure_With_Incorrect_Service_User_Password
    [Setup]  Remove Existing ACF  AND  Upload Valid ACF

    # Attempt SSH login with service user.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    # Attempt login with invalid password
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  service  ${SERVICE_USER_PASSWORD}123
    Should Be Equal  ${status}  ${False}


Verify Service User Sets Admin Password
    [Documentation]  Verify that service user can update admin password.
    [Tags]  Verify_Service_User_Sets_Admin_Password
    [Teardown]  Restore Admin Password

    Redfish.Login  service  ${SERVICE_USER_PASSWORD}

    # Update admin user password using Redfish.
    ${payload}=  Create Dictionary  Password=NewTestPwd123
    Redfish.Patch  /redfish/v1/AccountService/Accounts/admin  body=&{payload}
    ...  valid_status_codes=[${HTTP_OK}]

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Upload production key in BMC because it is not part of OpenBMC build yet.
    Open Connection for SCP
    scp.Put File  ${PRODUCTION_KEY_FILE_PATH}  ${acf_dir}


Remove Existing ACF
    [Documentation]  Remove existing ACF.

    BMC Execute Command  rm -f ${acf_dir}/*.acf

Upload Valid ACF
    [Documentation]  Upload valid ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${SERVICE_FILE_PATH}  ${acf_dir}


Restore Admin Password
    [Documentation]  Restore original password of admin user.

    ${payload}=  Create Dictionary  Password=${OPENBMC_ADMIN_PASSWORD}
    Redfish.Patch  /redfish/v1/AccountService/Accounts/admin  body=&{payload}
    ...  valid_status_codes=[${HTTP_OK}]
