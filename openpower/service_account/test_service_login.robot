*** Settings ***
Documentation    This suite is to test service user login functionality.

Resource         ../../lib/connection_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail


*** Variables ***

${acf_dir}            /etc/acf

*** Test Cases ***

Verify Service Login Fails Using Incorrect Password
    [Documentation]  Verify service login fails using incorrect password.

    Remove Existing ACF
    Upload Valid ACF
    ${incorrect_service_password} =  Catenate  SEPARATOR=  ${SERVICE_PASSWORD}  123
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${incorrect_service_password}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Upload production key in BMC because it is not part of OpenBMC build yet.
    Run Keywords  Open Connection for SCP
    scp.Put File  ${PRODUCTION_KEY_FILE_PATH}  ${acf_dir}


Remove Existing ACF
    [Documentation]  Remove existing access control file(ACF).

     BMC Execute Command  rm -f ${acf_dir}/*.acf

Upload Valid ACF
    [Documentation]  Upload valid ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${SERVICE_FILE_PATH}  ${acf_dir}
