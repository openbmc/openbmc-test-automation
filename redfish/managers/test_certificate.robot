*** Settings ***
Documentation    Test certificate in OpenBMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/certificate_utils.robot

Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify Server Certificate Replace
    [Documentation]  Verify server certificate replace.
    [Tags]  Verify_Server_Certificate_Replace
    [Template]  Replace Certificate Via Redfish

    # cert_type           cert_format                         expected_status
    Server                Valid Certificate Valid Privatekey  ok
    Server                Empty Certificate Valid Privatekey  error
    Server                Valid Certificate Empty Privatekey  error
    Server                Empty Certificate Empty Privatekey  error
    Server                Expired Certificate                 error


Verify Client Certificate Replace
    [Documentation]  Verify client certificate replace.
    [Tags]  Verify_Client_Certificate_Replace
    [Template]  Replace Certificate Via Redfish

    # cert_type           cert_format                         expected_status
    Client                Valid Certificate Valid Privatekey  ok
    Client                Empty Certificate Valid Privatekey  error
    Client                Valid Certificate Empty Privatekey  error
    Client                Empty Certificate Empty Privatekey  error
    Client                Expired Certificate                 error


*** Keywords ***

Replace Certificate Via Redfish
    [Documentation]  Test 'replace certificate' operation in the BMC via Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").

    redfish.Login

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}

    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    ${certificate_uri}=  Run Keyword if  '${cert_type}' == 'Server'
    ...  Set Variable  /redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1
    ...  ELSE IF  '${cert_type}' == 'Client'
    ...  Set Variable  /redfish/v1/AccountService/LDAP/Certificates/1

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}
    ${resp}=  redfish.Post  CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  redfish_utils.Get Attribute  ${certificate_uri}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'
    ...    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE
    ...    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
    OperatingSystem.Directory Should Exist  ${EXECDIR}${/}certificate_dir


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout

