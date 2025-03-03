*** Settings ***
Documentation    Test certificate in OpenBMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/certificate_utils.robot
Library          String

Test Tags       Certificate

Suite Setup      Suite Setup Execution
Suite Teardown   Suite Teardown
Test Teardown    Test Teardown Execution


*** Variables ***

${invalid_value}  abc
${ROOT_CA_FILE_PATH}  /etc/ssl/certs/authority/*
${keybit_length}  ${2048}

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
    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates
    ${cert_count}=  Get Length  ${cert_list}

    # Install CA certificate to reach maximum count of 10.
    FOR  ${INDEX}  IN RANGE  ${cert_count}  10
      Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok  ${FALSE}
      ${cert_count}=  Evaluate  ${cert_count} + 1
    END

    # Verify error while installing 11th CA certificate.
    Install And Verify Certificate Via Redfish  CA  Valid Certificate  error  ${FALSE}


Verify Error While Uploading Same CA Certificate
    [Documentation]  Verify error while uploading same CA certificate two times.
    [Tags]  Verify_Error_While_Uploading_Same_CA_Certificate

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

    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate Valid Privatekey
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_dict}=  Create Dictionary
    ...  @odata.id=/redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol/HTTPS/Certificates/1
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}

    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Wait Until Keyword Succeeds  2 mins  15 secs  Verify Certificate Visible Via OpenSSL  ${cert_file_path}


Verify CSR Generation For Server Certificate
    [Documentation]  Verify CSR generation for server certificate.
    [Tags]  Verify_CSR_Generation_For_Server_Certificate
    [Template]  Generate CSR Via Redfish

    # csr_type  key_pair_algorithm  key_bit_length  key_curv_id  expected_status
    Server      RSA                 ${keybit_length}         ${EMPTY}     ok
    Server      EC                  ${EMPTY}                 prime256v1   ok
    Server      EC                  ${EMPTY}                 secp521r1    ok
    Server      EC                  ${EMPTY}                 secp384r1    ok


Verify CSR Generation For Client Certificate
    [Documentation]  Verify CSR generation for client certificate.
    [Tags]  Verify_CSR_Generation_For_Client_Certificate
    [Template]  Generate CSR Via Redfish

    # csr_type  key_pair_algorithm  key_bit_length  key_curv_id  expected_status
    Client      RSA                 ${keybit_length}         ${EMPTY}     ok
    Client      EC                  ${EMPTY}                 prime256v1   ok
    Client      EC                  ${EMPTY}                 secp521r1    ok
    Client      EC                  ${EMPTY}                 secp384r1    ok


Verify CSR Generation For Server Certificate With Invalid Value
    [Documentation]  Verify error while generating CSR for server certificate with invalid value.
    [Tags]  Verify_CSR_Generation_For_Server_Certificate_With_Invalid_Value
    [Template]  Generate CSR Via Redfish

    # csr_type  key_pair_algorithm  key_bit_length    key_curv_id       expected_status
    Server      ${invalid_value}    ${keybit_length}           prime256v1        error
    Server      RAS                 ${invalid_value}           ${EMPTY}          error
    Server      EC                  ${EMPTY}                   ${invalid_value}  error


Verify CSR Generation For Client Certificate With Invalid Value
    [Documentation]  Verify error while generating CSR for client certificate with invalid value.
    [Tags]  Verify_CSR_Generation_For_Client_Certificate_With_Invalid_Value
    [Template]  Generate CSR Via Redfish

    Client      ${invalid_value}    ${keybit_length}           prime256v1        error
    Client      RSA                 ${invalid_value}           ${EMPTY}          error
    Client      EC                  ${EMPTY}                   ${invalid_value}  error


Verify Expired Certificate Install
    [Documentation]  Verify installation of expired certificate.
    [Tags]  Verify_Expired_Certificate_Install
    [Setup]  Run Keywords  Get Current BMC Date  AND  Modify BMC Date
    [Template]  Install And Verify Certificate Via Redfish
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore BMC Date

    # cert_type  cert_format          expected_status
    Client       Expired Certificate  ok
    CA           Expired Certificate  ok


Verify Expired Certificate Replace
    [Documentation]  Verify replacing the certificate with an expired one.
    [Tags]  Verify_Expired_Certificate_Replace
    [Setup]  Run Keywords  Get Current BMC Date  AND  Modify BMC Date
    [Template]  Replace Certificate Via Redfish
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore BMC Date

    # cert_type  cert_format          expected_status
    Server       Expired Certificate  ok


Verify Not Yet Valid Certificate Install
    [Documentation]  Verify installation of not yet valid certificates.
    [Tags]  Verify_Not_Yet_Valid_Certificate_Install
    [Setup]  Run Keywords  Get Current BMC Date  AND  Modify BMC Date
    [Template]  Install And Verify Certificate Via Redfish
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore BMC Date

    # cert_type  cert_format                expected_status
    Client       Not Yet Valid Certificate  ok
    CA           Not Yet Valid Certificate  ok


Verify Not Yet Valid Certificate Replace
    [Documentation]  Verify replacing certificate with a not yet valid one.
    [Tags]  Verify_Not_Yet_Valid_Certificate_Replace
    [Setup]  Run Keywords  Get Current BMC Date  AND  Modify BMC Date
    [Template]  Replace Certificate Via Redfish
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Restore BMC Date

    # cert_type  cert_format                expected_status
    Server       Not Yet Valid Certificate  ok
    Client       Not Yet Valid Certificate  ok
    CA           Not Yet Valid Certificate  ok


Verify Certificates Location Via Redfish
    [Documentation]  Verify the location of certificates via Redfish.
    [Tags]  Verify_Certificates_Location_Via_Redfish

    ${cert_id}=  Install And Verify Certificate Via Redfish
    ...  CA  Valid Certificate  ok

    ${resp}=  Redfish.Get  /redfish/v1/CertificateService/CertificateLocations
    ${Links}=  Get From Dictionary  ${resp.dict}  Links

    ${match_cert}=  Catenate
    ...  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates/${cert_id}
    ${match}=  Set Variable  ${False}

    FOR  ${Certificates_dict}  IN  @{Links['Certificates']}
       Continue For Loop If
       ...  "${Certificates_dict['@odata.id']}}" != "${match_cert}}"
       ${match}=  Set Variable  ${True}
    END

    Should Be Equal  ${match}  ${True}
    ...  msg=Verify the location of certificates via Redfish fail.


*** Keywords ***

Get Current BMC Date
    [Documentation]  Get current BMC date.

    ${cli_date_time}=  CLI Get BMC DateTime
    Set Test Variable  ${cli_date_time}

Restore BMC Date
    [Documentation]  Restore BMC date to its prior value.

    Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}  body={'DateTime': '${cli_date_time}'}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


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

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Server'  ${REDFISH_HTTPS_CERTIFICATE_URI}/
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}/

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${payload}=  Create Dictionary  City=Austin  CertificateCollection=${certificate_dict}
    ...  CommonName=${OPENBMC_HOST}  Country=US  Organization=xyz
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


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail

Suite Teardown
    [Documentation]  Do suite teardown tasks.

    Redfish.Logout
