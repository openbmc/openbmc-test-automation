*** Settings ***
Documentation    Test certificate in OpenBMC.

Resource         ../../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/certificate_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify Server Certificate Install With Valid Certificate And Valid Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and valid private key.
    [Tags]  Verify_Server_Certificate_Install_With_Valid_Certificate_And_Valid_Private_Key
    [Template]  Certificate Install Via Redfish
    # Certificate type    Certificate file format             Expected Status
    Server                Valid Certificate Valid Privatekey  ok


*** Keywords ***

Certificate Install Via Redfish
    [Documentation]  Test certificate install in the BMC via Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate installation REST
    #                     request(i.e. "ok" or "error").

    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    ${payload}=  Create Dictionary  data=${file_data}
    ${resp}=  redfish.Post  Managers/bmc/NetworkProtocol/HTTPS/Certificates  body=${payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    # Adding delay after certificate installation.
    sleep  10s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    Should Not Be Empty  ${cert_file_content}

    #${bmc_cert_content}=  redfish_utils.Get Properties  /redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1
    ${bmc_cert_content}=  redfish_utils.Get Target Actions  /redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1/  CertificateString
    Run Keyword if  '${expected_status}' == 'ok'
    ...  Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE IF  '${expected_status}' == 'error'
    ...  Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
    OperatingSystem.Directory Should Exist  ${EXECDIR}${/}certificate_dir

    #OpenBMC Delete Request  ${SERVER_CERTIFICATE_URI}
    redfish.Login

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout
