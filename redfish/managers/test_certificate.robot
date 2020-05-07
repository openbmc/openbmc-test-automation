*** Settings ***
Documentation    Test certificate in OpenBMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/certificate_utils.robot
Library          String

Force Tags       Certificate_Test

Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

${invalid_value}  abc
${ROOT_CA_FILE_PATH}  /etc/ssl/certs/authority/*


** Test Cases **

Verify Server Certificate Replace
    [Documentation]  Verify server certificate replace.
    [Tags]  Verify_Server_Certificate_Replace
    [Template]  Replace Certificate Via Redfish

    # cert_type  cert_format                         expected_status
    Server       Valid Certificate Valid Privatekey  ok
    Server       Empty Certificate Valid Privatekey  error
    Server       Valid Certificate Empty Privatekey  error
    Server       Empty Certificate Empty Privatekey  error


Verify Client Certificate Replace
    [Documentation]  Verify client certificate replace.
    [Tags]  Verify_Client_Certificate_Replace
    [Template]  Replace Certificate Via Redfish

    # cert_type  cert_format                         expected_status
    Client       Valid Certificate Valid Privatekey  ok
    Client       Empty Certificate Valid Privatekey  error
    Client       Valid Certificate Empty Privatekey  error
    Client       Empty Certificate Empty Privatekey  error


Verify CA Certificate Replace
    [Documentation]  Verify CA certificate replace.
    [Tags]  Verify_CA_Certificate_Replace
    [Template]  Replace Certificate Via Redfish

    # cert_type  cert_format        expected_status
    CA           Valid Certificate  ok
    CA           Empty Certificate  error


Verify Client Certificate Install
    [Documentation]  Verify client certificate install.
    [Tags]  Verify_Client_Certificate_Install
    [Template]  Install And Verify Certificate Via Redfish

    # cert_type  cert_format                         expected_status
    Client       Valid Certificate Valid Privatekey  ok
    Client       Empty Certificate Valid Privatekey  error
    Client       Valid Certificate Empty Privatekey  error
    Client       Empty Certificate Empty Privatekey  error


Verify CA Certificate Install
    [Documentation]  Verify CA certificate install.
    [Tags]  Verify_CA_Certificate_Install
    [Template]  Install And Verify Certificate Via Redfish

    # cert_type  cert_format        expected_status
    CA           Valid Certificate  ok
    CA           Empty Certificate  error


Verify Maximum CA Certificate Install
    [Documentation]  Verify maximum CA certificate install.
    [Tags]  Verify_Maximum_CA_Certificate_Install
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Delete All CA Certificate Via Redfish

    # Get CA certificate count from BMC.
    redfish.Login
    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/bmc/Truststore/Certificates
    ${cert_count}=  Get Length  ${cert_list}

    # Install CA certificate to reach maximum count of 10.
    FOR  ${INDEX}  IN RANGE  ${cert_count}  10
      Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok  ${FALSE}
      ${cert_count}=  Evaluate  ${cert_count} + 1
    END

    # Verify error while installing 11th CA certificate.
    Install And Verify Certificate Via Redfish  CA  Valid Certificate  error  ${FALSE}


Verify Error While Uploding Same CA Certificate
    [Documentation]  Verify error while uploading same CA certificate two times.
    [Tags]  Verify_Error_While_Uploding_Same_CA_Certificate

    # Create certificate file for uploading.
    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate  365
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    # Install CA certificate.
    Install Certificate File On BMC  ${REDFISH_CA_CERTIFICATE_URI}  ok  data=${file_data}

    # Adding delay after certificate installation.
    Sleep  30s

    # Check error while uploading same certificate.
    Install Certificate File On BMC  ${REDFISH_CA_CERTIFICATE_URI}  error  data=${file_data}


Verify Server Certificate View Via Openssl
    [Documentation]  Verify server certificate via openssl command.
    [Tags]  Verify_Server_Certificate_View_Via_Openssl

    redfish.Login

    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate Valid Privatekey
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_dict}=  Create Dictionary
    ...  @odata.id=/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}

    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}

    Wait Until Keyword Succeeds  2 mins  15 secs  Verify Certificate Visible Via OpenSSL  ${cert_file_path}


Verify CSR Generation For Server Certificate
    [Documentation]  Verify CSR generation for server certificate.
    [Tags]  Verify_CSR_Generation_For_Server_Certificate
    [Template]  Generate CSR Via Redfish

    # csr_type  key_pair_algorithm  key_bit_length  key_curv_id  expected_status
    Server      RSA                 ${2048}         ${EMPTY}     ok
    Server      EC                  ${EMPTY}        prime256v1   ok
    Server      EC                  ${EMPTY}        secp521r1    ok
    Server      EC                  ${EMPTY}        secp384r1    ok


Verify CSR Generation For Client Certificate
    [Documentation]  Verify CSR generation for client certificate.
    [Tags]  Verify_CSR_Generation_For_Client_Certificate
    [Template]  Generate CSR Via Redfish

    # csr_type  key_pair_algorithm  key_bit_length  key_curv_id  expected_status
    Client      RSA                 ${2048}         ${EMPTY}     ok
    Client      EC                  ${EMPTY}        prime256v1   ok
    Client      EC                  ${EMPTY}        secp521r1    ok
    Client      EC                  ${EMPTY}        secp384r1    ok


Verify CSR Generation For Server Certificate With Invalid Value
    [Documentation]  Verify error while generating CSR for server certificate with invalid value.
    [Tags]  Verify_CSR_Generation_For_Server_Certificate_With_Invalid_Value
    [Template]  Generate CSR Via Redfish

    # csr_type  key_pair_algorithm  key_bit_length    key_curv_id       expected_status
    Server      ${invalid_value}    ${2048}           prime256v1        error
    Server      RAS                 ${invalid_value}  ${EMPTY}          error
    Server      EC                  ${EMPTY}          ${invalid_value}  error


Verify CSR Generation For Client Certificate With Invalid Value
    [Documentation]  Verify error while generating CSR for client certificate with invalid value.
    [Tags]  Verify_CSR_Generation_For_Client_Certificate_With_Invalid_Value
    [Template]  Generate CSR Via Redfish

    Client      ${invalid_value}    ${2048}           prime256v1        error
    Client      RSA                 ${invalid_value}  ${EMPTY}          error
    Client      EC                  ${EMPTY}          ${invalid_value}  error


Verify Expired Client Certificate Install
    [Documentation]  Verify installation of expired CA certificate.
    [Tags]  Verify_Expired_Client_Certificate_Install

    Install And Verify Certificate Via Redfish  Client  Expired Certificate  error


Verify Expired CA Certificate Install
    [Documentation]  Verify installation of expired CA certificate.
    [Tags]  Verify_Expired_CA_Certificate_Install

    Install And Verify Certificate Via Redfish  CA  Expired Certificate  error


*** Keywords ***

Install And Verify Certificate Via Redfish
    [Documentation]  Install and verify certificate using Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}  ${delete_cert}=${True}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").
    # cert_format         Certificate file format
    #                     (e.g. "Valid_Certificate_Valid_Privatekey").
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").
    # delete_cert         Certificate will be deleted before installing if this True.

    redfish.Login
    Run Keyword If  '${cert_type}' == 'CA' and '${delete_cert}' == '${True}'
    ...  Delete All CA Certificate Via Redfish
    ...  ELSE IF  '${cert_type}' == 'Client' and '${delete_cert}' == '${True}'
    ...  Delete Certificate Via BMC CLI  ${cert_type}

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}

    ${cert_id}=  Install Certificate File On BMC  ${certificate_uri}  ${expected_status}  data=${file_data}
    Logging  Installed certificate id: ${cert_id}

    # Adding delay after certificate installation.
    Sleep  30s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  Run Keyword If  '${expected_status}' == 'ok'  redfish_utils.Get Attribute
    ...  ${certificate_uri}/${cert_id}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'  Should Contain  ${cert_file_content}  ${bmc_cert_content}
    [Return]  ${cert_id}


Replace Certificate Via Redfish
    [Documentation]  Test 'replace certificate' operation in the BMC via Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").

    # Install certificate before replacing client or CA certificate.
    ${cert_id}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    Install And Verify Certificate Via Redfish  ${cert_type}  Valid Certificate Valid Privatekey  ok
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Install And Verify Certificate Via Redfish  ${cert_type}  Valid Certificate  ok

    redfish.Login

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}

    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Server'  ${REDFISH_HTTPS_CERTIFICATE_URI}/1
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}/1
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}/${cert_id}

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}

    ${expected_resp}=  Set Variable If  '${expected_status}' == 'ok'  ${HTTP_OK}
    ...  '${expected_status}' == 'error'  ${HTTP_NOT_FOUND}, ${HTTP_INTERNAL_SERVER_ERROR}
    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}  valid_status_codes=[${expected_resp}]

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  redfish_utils.Get Attribute  ${certificate_uri}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'
    ...    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE
    ...    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Generate CSR Via Redfish
    [Documentation]  Generate CSR using Redfish.
    [Arguments]  ${cert_type}  ${key_pair_algorithm}  ${key_bit_length}  ${key_curv_id}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type ("Server" or "Client").
    # key_pair_algorithm  CSR key pair algorithm ("EC" or "RSA")
    # key_bit_length      CSR key bit length ("2048").
    # key_curv_id         CSR key curv id ("prime256v1" or "secp521r1" or "secp384r1").
    # expected_status     Expected status of certificate replace Redfish
    #                     request ("ok" or "error").

    redfish.Login

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Server'  ${REDFISH_HTTPS_CERTIFICATE_URI}/
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}/

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${payload}=  Create Dictionary  City=Austin  CertificateCollection=${certificate_dict}
    ...  CommonName=${OPENBMC_HOST}  Country=US  Organization=IBM
    ...  OrganizationalUnit=ISL  State=AU  KeyBitLength=${key_bit_length}
    ...  KeyPairAlgorithm=${key_pair_algorithm}  KeyCurveId=${key_curv_id}

    # Remove not applicable field for CSR generation.
    Run Keyword If  '${key_pair_algorithm}' == 'EC'  Remove From Dictionary  ${payload}  KeyBitLength
    ...  ELSE IF  '${key_pair_algorithm}' == 'RSA'  Remove From Dictionary  ${payload}  KeyCurveId

    ${expected_resp}=  Set Variable If  '${expected_status}' == 'ok'  ${HTTP_OK}
    ...  '${expected_status}' == 'error'  ${HTTP_INTERNAL_SERVER_ERROR}, ${HTTP_BAD_REQUEST}
    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.GenerateCSR
    ...  body=${payload}  valid_status_codes=[${expected_resp}]

    # Delay added between two CSR generation request.
    Sleep  5s


Delete Certificate Via BMC CLI
    [Documentation]  Delete certificate via BMC CLI.
    [Arguments]  ${cert_type}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").

    ${certificate_file_path}  ${certificate_service}  ${certificate_uri}=
    ...  Run Keyword If  '${cert_type}' == 'Client'
    ...    Set Variable  /etc/nslcd/certs/cert.pem  phosphor-certificate-manager@nslcd.service
    ...    ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Set Variable  ${ROOT_CA_FILE_PATH}  phosphor-certificate-manager@authority.service
    ...    ${REDFISH_CA_CERTIFICATE_URI}

    ${file_status}  ${stderr}  ${rc}=  BMC Execute Command
    ...  [ -f ${certificate_file_path} ] && echo "Found" || echo "Not Found"

    Return From Keyword If  "${file_status}" != "Found"
    BMC Execute Command  rm ${certificate_file_path}
    BMC Execute Command  systemctl restart ${certificate_service}
    BMC Execute Command  systemctl daemon-reload
    Wait Until Keyword Succeeds  1 min  10 sec  Redfish.Get  ${certificate_uri}/1
    ...  valid_status_codes=[${HTTP_NOT_FOUND}, ${HTTP_INTERNAL_SERVER_ERROR}]


Delete All CA Certificate Via Redfish
    [Documentation]  Delete all CA certificate via Redfish.

    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/bmc/Truststore/Certificates
    FOR  ${cert}  IN  @{cert_list}
      Redfish.Delete  ${cert}  valid_status_codes=[${HTTP_NO_CONTENT}]
    END


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout
