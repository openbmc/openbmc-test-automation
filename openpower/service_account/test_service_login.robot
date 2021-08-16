*** Settings ***
Documentation    This suite is to test service user login functionality.

Resource         ../../lib/connection_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Variables ***

${acf_file}           service.acf
${acf_dir}            /etc/acf
${production_key}     ibmacf-prod.key

*** Test Cases ***

Verify Service User Login With Valid ACF file
    [Documentation]  Verify service user login with valid ACF file.
    [Setup]  Remove Existing ACF

    Upload Valid ACF
    Redfish.Login  service  ${service_password}


Verify Service User Login Without ACF file
    [Documentation]  Verify service user login without ACF file.
    [Setup]  Remove Existing ACF

    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  service  ${service_password}


*** Keywords ***

Remove Existing ACF
    [Documentation]  Remove existing ACF.

    BMC Execute Command  rm -f ${acf_dir}/${acf_file}


Upload Valid ACF
    [Documentation]  Upload valid ACF.

    Run Keywords  Open Connection for SCP
    scp.Put File  ${acf_file}  ${acf_dir}
    scp.Put File  ${production_key}  ${acf_dir}
