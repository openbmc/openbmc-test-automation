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


Verify Client Certificate Install
    [Documentation]  Verify client certificate install.
    [Tags]  Verify_Client_Certificate_Install
    [Template]  Install And Verify Client Certificate Via Redfish

    # cert_type           # cert_format                        expected_status
    Client                Valid Certificate Valid Privatekey   ok
    Client                Empty Certificate Valid Privatekey   error
    Client                Valid Certificate Empty Privatekey   error
    Client                Empty Certificate Empty Privatekey   error
    Client                Expired Certificate                  error

Verify Server Certificate View Via Openssl
    [Documentation]  Verify server certificate via openssl command.
    [Tags]  Verify_Server_Certificate_View_Via_Openssl

    redfish.Login

    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate Valid Privatekey
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    ${certificate_dict}=  Create Dictionary
    ...  @odata.id=/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}

    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}

    Wait Until Keyword Succeeds  2 mins  15 secs  Verify Certificate Visible Via OpenSSL  ${cert_file_path}


*** Keywords ***

Install And Verify Client Certificate Via Redfish
    [Documentation]  Install and verify client certificate using Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client" or "CA").
    # cert_format         Certificate file format
    #                     (e.g. "Valid_Certificate_Valid_Privatekey").
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").

    Delete Certificate Via BMC CLI  ${cert_type}
    # Adding delay after certificate deletion.
    Sleep  15s

    redfish.Login
    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    Install Client Certificate File On BMC  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  ${expected_status}  data=${file_data}

    # Adding delay after certificate installation.
    Sleep  15s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  Run Keyword If  '${expected_status}' == 'ok'  redfish_utils.Get Attribute
    ...  ${REDFISH_LDAP_CERTIFICATE_URI}/1  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'  Should Contain  ${cert_file_content}  ${bmc_cert_content}


Install Client Certificate File On BMC
    [Documentation]  Install certificate file in BMC using POST operation.
    [Arguments]  ${uri}  ${status}=ok  &{kwargs}

    # Description of argument(s):
    # uri         URI for installing certificate file via REST
    #             e.g. "/xyz/openbmc_project/certs/server/https".
    # status      Expected status of certificate installation via REST
    #             e.g. error, ok.
    # kwargs      A dictionary of keys/values to be passed directly to
    #             POST Request.

    Initialize OpenBMC  quiet=${quiet}

    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${kwargs}  headers  ${headers}

    ${ret}=  Post Request  openbmc  ${uri}  &{kwargs}

    Run Keyword If  '${status}' == 'ok'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}
    ...  ELSE IF  '${status}' == 'error'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_INTERNAL_SERVER_ERROR}

    Delete All Sessions


Replace Certificate Via Redfish
    [Documentation]  Test 'replace certificate' operation in the BMC via Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").

    # Install client certificate before replacing client certificate.
    Run Keyword If  '${cert_type}' == 'Client'  Install And Verify Client Certificate Via Redfish
    ...  ${cert_type}  Valid Certificate Valid Privatekey  ok

    redfish.Login

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}

    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    ${certificate_uri}=  Set Variable If  '${cert_type}' == 'Server'
    ...  /redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1
    ...  /redfish/v1/AccountService/LDAP/Certificates/1

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}

    ${expected_resp}=  Set Variable If  '${expected_status}' == 'ok'  ${HTTP_OK}
    ...  '${expected_status}' == 'error'  ${HTTP_INTERNAL_SERVER_ERROR}
    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}  valid_status_codes=[${expected_resp}]

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  redfish_utils.Get Attribute  ${certificate_uri}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'
    ...    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE
    ...    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Verify Certificate Visible Via OpenSSL
    [Documentation]  Checks if given certificate is visible via openssl's showcert command.
    [Arguments]  ${cert_file_path}

    # Description of argument(s):
    # cert_file_path           Certificate file path.

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${openssl_cert_content}=  Get Certificate Content From BMC Via Openssl
    Should Contain  ${cert_file_content}  ${openssl_cert_content}


Delete Certificate Via BMC CLI
    [Documentation]  Delete client certificate via BMC CLI.
    [Arguments]  ${cert_type}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").

    ${certificate_file_path}=  Set Variable If
    ...  '${cert_type}' == 'Client'  /etc/nslcd/certs/cert.pem
    ...  '${cert_type}' == 'CA'  /etc/ssl/certs/Root-CA.pem

    ${certificate_service}=  Set Variable If
    ...  '${cert_type}' == 'Client'  phosphor-certificate-manager@nslcd.service
    ...  '${cert_type}' == 'CA'  phosphor-certificate-manager@authority.service

    ${file_status}  ${stderr}  ${rc}=  BMC Execute Command
    ...  [ -f ${certificate_file_path} ] && echo "Found" || echo "Not Found"

    Run Keyword If  "${file_status}" == "Found"
    ...  Run Keywords  BMC Execute Command  rm ${certificate_file_path}  AND
    ...  BMC Execute Command  systemctl restart ${certificate_service}


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout
