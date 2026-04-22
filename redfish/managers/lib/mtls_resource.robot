*** Settings ***
Documentation  Shared keywords and variables for mTLS auth tests.

Resource         ../../../lib/resource.robot
Resource         ../../../lib/bmc_redfish_resource.robot
Resource         ../../../lib/bmc_redfish_utils.robot
Resource         ../../../lib/openbmc_ffdc.robot
Resource         ../../../lib/certificate_utils.robot
Library          ../../../lib/mtls_cert_utils.py
Library          Collections
Library          OperatingSystem
Library          RequestsLibrary
Library          String

*** Variables ***
${ACCOUNT_SERVICE_URI}   /redfish/v1/AccountService
${SESSIONS_URI}          /redfish/v1/SessionService/Sessions
${CERT_INSTALL_WAIT}     10

*** Keywords ***
MTLS Suite Setup
    [Documentation]  Generate certificates, install CA on BMC,
    ...  and enable TLS authentication.

    Redfish.Login

    # Create temp directory for certificates.
    ${tmp}=  Evaluate  tempfile.mkdtemp(prefix='mtls_')
    ...  modules=tempfile
    Set Suite Variable  ${MTLS_CERT_DIR}  ${tmp}

    # Get BMC hostname for UPN generation.
    # Read from NetworkProtocol (same source bmcweb uses).
    ${hostname}=  Redfish.Get Attribute
    ...  /redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol
    ...  HostName

    # Generate main CA.
    ${ca_cert}  ${ca_key}=  Generate CA
    Set Suite Variable  ${CA_CERT_PEM}  ${ca_cert}
    Set Suite Variable  ${CA_KEY_PEM}  ${ca_key}
    Write Cert And Key  ${ca_cert}  ${ca_key}
    ...  ${MTLS_CERT_DIR}/ca-cert.pem
    ...  ${MTLS_CERT_DIR}/ca-key.pem

    # Generate CN-based client cert (root).
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}
    ...  common_name=${OPENBMC_USERNAME}
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/cn-client-cert.pem
    ...  ${MTLS_CERT_DIR}/cn-client-key.pem

    # Generate UPN-based client cert.
    ${upn_value}=  Catenate  SEPARATOR=@
    ...  ${OPENBMC_USERNAME}  ${hostname}
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}  upn=${upn_value}
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/upn-client-cert.pem
    ...  ${MTLS_CERT_DIR}/upn-client-key.pem

    # Generate expired client cert.
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}
    ...  common_name=${OPENBMC_USERNAME}
    ...  not_valid_before=2020-01-01 00:00:00
    ...  not_valid_after=2021-01-01 00:00:00
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/expired-cert.pem
    ...  ${MTLS_CERT_DIR}/expired-key.pem

    # Generate not-yet-valid client cert.
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}
    ...  common_name=${OPENBMC_USERNAME}
    ...  not_valid_before=2060-01-01 00:00:00
    ...  not_valid_after=2070-01-01 00:00:00
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/not-yet-valid-cert.pem
    ...  ${MTLS_CERT_DIR}/not-yet-valid-key.pem

    # Generate untrusted CA and client cert.
    ${u_ca_cert}  ${u_ca_key}=  Generate CA
    ...  common_name=Untrusted CA
    Write Cert And Key  ${u_ca_cert}  ${u_ca_key}
    ...  ${MTLS_CERT_DIR}/untrusted-ca-cert.pem
    ...  ${MTLS_CERT_DIR}/untrusted-ca-key.pem
    ${cert}  ${key}=  Generate Client Cert
    ...  ${u_ca_cert}  ${u_ca_key}
    ...  common_name=${OPENBMC_USERNAME}
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/untrusted-client-cert.pem
    ...  ${MTLS_CERT_DIR}/untrusted-client-key.pem

    # Generate wrong EKU (serverAuth) client cert.
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}
    ...  common_name=${OPENBMC_USERNAME}
    ...  extended_key_usage=serverAuth
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/wrong-eku-cert.pem
    ...  ${MTLS_CERT_DIR}/wrong-eku-key.pem

    # Generate cert with no username (no CN, no UPN).
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/no-username-cert.pem
    ...  ${MTLS_CERT_DIR}/no-username-key.pem

    # Generate self-signed client cert.
    ${cert}  ${key}=  Generate Self Signed Client Cert
    ...  ${OPENBMC_USERNAME}
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/self-signed-cert.pem
    ...  ${MTLS_CERT_DIR}/self-signed-key.pem

    # Generate nonexistent-user client cert.
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca_cert}  ${ca_key}
    ...  common_name=doesnotexist
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/nonexistent-cert.pem
    ...  ${MTLS_CERT_DIR}/nonexistent-key.pem

    # Generate intermediate CA and client cert.
    # Client cert file includes the intermediate CA cert to
    # form a complete chain for TLS handshake.
    ${int_cert}  ${int_key}=  Generate Intermediate CA
    ...  ${ca_cert}  ${ca_key}
    Write Cert And Key  ${int_cert}  ${int_key}
    ...  ${MTLS_CERT_DIR}/intermediate-ca-cert.pem
    ...  ${MTLS_CERT_DIR}/intermediate-ca-key.pem
    ${cert}  ${key}=  Generate Client Cert
    ...  ${int_cert}  ${int_key}
    ...  common_name=${OPENBMC_USERNAME}
    ${chain}=  Catenate  SEPARATOR=  ${cert}  ${int_cert}
    Write Cert And Key  ${chain}  ${key}
    ...  ${MTLS_CERT_DIR}/intermediate-client-cert.pem
    ...  ${MTLS_CERT_DIR}/intermediate-client-key.pem

    # Generate second CA and client cert (for multi-CA test).
    # Client cert file includes CA2 cert for TLS chain.
    ${ca2_cert}  ${ca2_key}=  Generate CA
    ...  common_name=Test CA 2
    Write Cert And Key  ${ca2_cert}  ${ca2_key}
    ...  ${MTLS_CERT_DIR}/ca2-cert.pem
    ...  ${MTLS_CERT_DIR}/ca2-key.pem
    ${cert}  ${key}=  Generate Client Cert
    ...  ${ca2_cert}  ${ca2_key}
    ...  common_name=${OPENBMC_USERNAME}
    ${chain}=  Catenate  SEPARATOR=  ${cert}  ${ca2_cert}
    Write Cert And Key  ${chain}  ${key}
    ...  ${MTLS_CERT_DIR}/ca2-client-cert.pem
    ...  ${MTLS_CERT_DIR}/ca2-client-key.pem

    # Install main CA on BMC.
    Delete All CA Certificate Via Redfish
    ${ca_cert_id}=  Install CA Certificate On BMC  ${CA_CERT_PEM}
    Set Suite Variable  ${CA_CERT_ID}  ${ca_cert_id}

    # Enable TLS auth and set mapping to CommonName.
    Enable TLS Authentication
    Set Certificate Mapping Attribute  CommonName

MTLS Suite Teardown
    [Documentation]  Disable TLS auth, clean up certs, and logout.

    Run Keyword And Ignore Error
    ...  Set Certificate Mapping Attribute  CommonName
    Run Keyword And Ignore Error
    ...  Disable TLS Authentication
    Run Keyword And Ignore Error
    ...  Delete All CA Certificate Via Redfish

    Run Keyword And Ignore Error
    ...  OperatingSystem.Remove Directory
    ...  ${MTLS_CERT_DIR}  recursive=True
    Redfish.Logout

MTLS Test Teardown
    [Documentation]  Common test teardown for mTLS tests.

    FFDC On Test Case Fail

Install CA Certificate On BMC
    [Documentation]  Install CA cert PEM string to the truststore.
    [Arguments]  ${cert_pem}

    # Description of argument(s):
    # cert_pem  PEM-encoded CA certificate string.

    ${data}=  Create Dictionary
    ...  CertificateString=${cert_pem}
    ...  CertificateType=PEM
    ${resp}=  Redfish.Post
    ...  ${REDFISH_CA_CERTIFICATE_URI}
    ...  body=${data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_CREATED}]
    Sleep  ${CERT_INSTALL_WAIT}s

    RETURN  ${resp.dict['Id']}

Enable TLS Authentication
    [Documentation]  Enable mTLS authentication on BMC.

    ${body}=  Create Dictionary
    ${auth}=  Create Dictionary  TLS=${True}
    ${oem}=  Create Dictionary  AuthMethods=${auth}
    ${openbmc}=  Create Dictionary  OpenBMC=${oem}
    Set To Dictionary  ${body}  Oem=${openbmc}
    Redfish.Patch  ${ACCOUNT_SERVICE_URI}
    ...  body=${body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Disable TLS Authentication
    [Documentation]  Disable mTLS authentication on BMC.

    ${body}=  Create Dictionary
    ${auth}=  Create Dictionary  TLS=${False}
    ${oem}=  Create Dictionary  AuthMethods=${auth}
    ${openbmc}=  Create Dictionary  OpenBMC=${oem}
    Set To Dictionary  ${body}  Oem=${openbmc}
    Redfish.Patch  ${ACCOUNT_SERVICE_URI}
    ...  body=${body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Set Certificate Mapping Attribute
    [Documentation]  Set CertificateMappingAttribute on AccountService.
    [Arguments]  ${attribute}

    # Description of argument(s):
    # attribute  Mapping attribute value (CommonName or
    #            UserPrincipalName).

    ${cert_cfg}=  Create Dictionary
    ...  CertificateMappingAttribute=${attribute}
    ${mfa}=  Create Dictionary  ClientCertificate=${cert_cfg}
    ${body}=  Create Dictionary  MultiFactorAuth=${mfa}
    Redfish.Patch  ${ACCOUNT_SERVICE_URI}
    ...  body=${body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

Get Certificate Mapping Attribute
    [Documentation]  Return the current CertificateMappingAttribute.

    ${resp}=  Redfish.Get Properties
    ...  ${ACCOUNT_SERVICE_URI}
    ${attr}=  Set Variable
    ...  ${resp['MultiFactorAuth']['ClientCertificate']['CertificateMappingAttribute']}

    RETURN  ${attr}

Attempt MTLS Authentication
    [Documentation]  Attempt mTLS authentication and return the HTTP
    ...  status code. Uses requests library directly.
    [Arguments]  ${cert_file}  ${key_file}

    # Description of argument(s):
    # cert_file  Path to PEM client certificate file.
    # key_file   Path to PEM client private key file.

    ${cert_tuple}=  Evaluate
    ...  ('${cert_file}', '${key_file}')
    ${url}=  Catenate  SEPARATOR=
    ...  https://${OPENBMC_HOST}:${HTTPS_PORT}
    ...  ${SESSIONS_URI}
    ${resp}=  Evaluate
    ...  requests.get($url, cert=$cert_tuple, verify=False, timeout=30)
    ...  modules=requests

    ${code}=  Convert To Integer  ${resp.status_code}

    RETURN  ${code}

MTLS Auth Should Succeed
    [Documentation]  Verify mTLS authentication succeeds with the
    ...  given certificate.
    [Arguments]  ${cert_file}  ${key_file}

    # Description of argument(s):
    # cert_file  Path to PEM client certificate file.
    # key_file   Path to PEM client private key file.

    ${code}=  Attempt MTLS Authentication
    ...  ${cert_file}  ${key_file}
    Should Be Equal As Integers  ${code}  ${200}
    ...  msg=mTLS auth failed with status ${code}.

MTLS Auth Should Fail
    [Documentation]  Verify mTLS authentication fails with the
    ...  given certificate.
    [Arguments]  ${cert_file}  ${key_file}

    # Description of argument(s):
    # cert_file  Path to PEM client certificate file.
    # key_file   Path to PEM client private key file.

    ${code}=  Attempt MTLS Authentication
    ...  ${cert_file}  ${key_file}
    Should Not Be Equal As Integers  ${code}  ${200}
    ...  msg=mTLS auth should have failed but got ${code}.

MTLS CN Auth Should Succeed
    [Documentation]  Verify mTLS auth succeeds with the CN cert.

    MTLS Auth Should Succeed
    ...  ${MTLS_CERT_DIR}/cn-client-cert.pem
    ...  ${MTLS_CERT_DIR}/cn-client-key.pem

MTLS CN Auth Should Fail
    [Documentation]  Verify mTLS auth fails with the CN cert.

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/cn-client-cert.pem
    ...  ${MTLS_CERT_DIR}/cn-client-key.pem

Attempt MTLS Patch
    [Documentation]  Attempt an mTLS PATCH request and return the
    ...  HTTP status code.
    [Arguments]  ${cert_file}  ${key_file}  ${uri}  ${body}

    # Description of argument(s):
    # cert_file  Path to PEM client certificate file.
    # key_file   Path to PEM client private key file.
    # uri        Redfish URI to PATCH.
    # body       JSON string for PATCH body.

    ${cert_tuple}=  Evaluate
    ...  ('${cert_file}', '${key_file}')
    ${url}=  Catenate  SEPARATOR=
    ...  https://${OPENBMC_HOST}:${HTTPS_PORT}  ${uri}
    ${headers}=  Create Dictionary
    ...  Content-Type=application/json
    ${resp}=  Evaluate
    ...  requests.patch($url, cert=$cert_tuple, verify=False, data=$body, headers=$headers, timeout=30)
    ...  modules=requests

    RETURN  ${resp.status_code}
