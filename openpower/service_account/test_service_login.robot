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

*** Test Cases ***

Verify Service Login Fails Using Incorrect Password
    [Documentation]  Verify service login fails using incorrect password.
    [Setup]  Remove Existing ACF

    Upload Valid ACF
    ${incorrect_service_password} =  Catenate  SEPARATOR=  ${service_password}  123
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${incorrect_service_password}


*** Keywords ***

Remove Existing ACF
    [Documentation]  Remove existing access control file(ACF).

    BMC Execute Command  rm -f ${acf_dir}/${acf_file}


Upload Valid ACF
    [Documentation]  Upload valid access control file(ACF).

    Run Keywords  Open Connection or SCP
    scp.Put File  ${acf_file}  ${acf_dir}
    scp.Put File  ${production_key}  ${acf_dir}
