*** Settings ***
Documentation   Verify mTLS client certificate authentication.

Resource        lib/mtls_resource.robot

Suite Setup     MTLS Suite Setup
Suite Teardown  MTLS Suite Teardown
Test Teardown   MTLS Test Teardown

Test Tags       MTLS_Authentication

*** Variables ***

${READONLY_USERNAME}  mtls_readonly
${READONLY_PASSWORD}  T3stReadOnly

*** Test Cases ***

Verify MTLS Auth With CommonName Mapping
    [Documentation]  Verify mTLS authentication succeeds when
    ...  CertificateMappingAttribute is CommonName and the
    ...  client certificate CN matches a valid BMC user.
    [Tags]  Verify_MTLS_Auth_With_CommonName_Mapping

    Set Certificate Mapping Attribute  CommonName
    MTLS CN Auth Should Succeed

Verify MTLS Auth With UPN Mapping
    [Documentation]  Verify mTLS authentication succeeds when
    ...  CertificateMappingAttribute is UserPrincipalName and
    ...  the client certificate SAN UPN matches a valid user.
    [Tags]  Verify_MTLS_Auth_With_UPN_Mapping

    Set Certificate Mapping Attribute  UserPrincipalName
    MTLS Auth Should Succeed
    ...  ${MTLS_CERT_DIR}/upn-client-cert.pem
    ...  ${MTLS_CERT_DIR}/upn-client-key.pem
    [Teardown]  Run Keywords
    ...  Set Certificate Mapping Attribute  CommonName
    ...  AND  MTLS Test Teardown

Verify Switching Between Mapping Attributes
    [Documentation]  Verify switching CertificateMappingAttribute
    ...  between CommonName and UserPrincipalName works correctly
    ...  with each respective certificate type.
    [Tags]  Verify_Switching_Between_Mapping_Attributes

    # Start with CommonName mapping.
    Set Certificate Mapping Attribute  CommonName
    MTLS CN Auth Should Succeed

    # Switch to UPN mapping. CN cert should fail, UPN should work.
    Set Certificate Mapping Attribute  UserPrincipalName
    MTLS CN Auth Should Fail
    MTLS Auth Should Succeed
    ...  ${MTLS_CERT_DIR}/upn-client-cert.pem
    ...  ${MTLS_CERT_DIR}/upn-client-key.pem

    # Switch back to CommonName. CN should work again.
    Set Certificate Mapping Attribute  CommonName
    MTLS CN Auth Should Succeed
    [Teardown]  Run Keywords
    ...  Set Certificate Mapping Attribute  CommonName
    ...  AND  MTLS Test Teardown

Verify MTLS Auth With Intermediate CA
    [Documentation]  Verify mTLS authentication succeeds when the
    ...  client certificate is signed by an intermediate CA whose
    ...  root CA is in the BMC truststore.
    [Tags]  Verify_MTLS_Auth_With_Intermediate_CA

    MTLS Auth Should Succeed
    ...  ${MTLS_CERT_DIR}/intermediate-client-cert.pem
    ...  ${MTLS_CERT_DIR}/intermediate-client-key.pem

Verify MTLS Coexists With Session Auth
    [Documentation]  Verify session-based authentication continues
    ...  to work when mTLS authentication is enabled.
    [Tags]  Verify_MTLS_Coexists_With_Session_Auth

    # Verify mTLS works.
    MTLS CN Auth Should Succeed

    # Verify session auth still works.
    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/SessionService/Sessions
    ...  valid_status_codes=[${HTTP_OK}]
    Should Not Be Empty  ${resp.dict}

Verify MTLS With Admin And ReadOnly Roles
    [Documentation]  Verify mTLS RBAC: admin cert can PATCH,
    ...  readonly cert can GET but cannot PATCH.
    [Tags]  Verify_MTLS_With_Admin_And_ReadOnly_Roles
    [Teardown]  Admin And ReadOnly Teardown

    # Create readonly user.
    Redfish Create User  ${READONLY_USERNAME}
    ...  ${READONLY_PASSWORD}  ReadOnly  ${True}  ${True}

    # Generate cert for readonly user.
    ${cert}  ${key}=  Generate Client Cert
    ...  ${CA_CERT_PEM}  ${CA_KEY_PEM}
    ...  common_name=${READONLY_USERNAME}
    Write Cert And Key  ${cert}  ${key}
    ...  ${MTLS_CERT_DIR}/readonly-cert.pem
    ...  ${MTLS_CERT_DIR}/readonly-key.pem

    # Readonly cert should authenticate (GET).
    MTLS Auth Should Succeed
    ...  ${MTLS_CERT_DIR}/readonly-cert.pem
    ...  ${MTLS_CERT_DIR}/readonly-key.pem

    # Readonly cert should not be able to PATCH.
    ${status}=  Attempt MTLS Patch
    ...  ${MTLS_CERT_DIR}/readonly-cert.pem
    ...  ${MTLS_CERT_DIR}/readonly-key.pem
    ...  ${ACCOUNT_SERVICE_URI}
    ...  {"AccountLockoutThreshold": 5}
    Should Be Equal As Integers  ${status}  ${HTTP_FORBIDDEN}
    ...  msg=ReadOnly PATCH should return 403 but got ${status}.

    # Admin cert should be able to PATCH.
    MTLS CN Auth Should Succeed

Verify MTLS Configuration Persists After BMC Reboot
    [Documentation]  Verify mTLS authentication settings and CA
    ...  certs persist after BMC reboot.
    [Tags]  Verify_MTLS_Configuration_Persists_After_BMC_Reboot
    [Teardown]  Restore MTLS State After Reboot

    # Verify mTLS works before reboot.
    MTLS CN Auth Should Succeed

    # Reboot BMC.
    Redfish OBMC Reboot (off)

    # Wait for BMC to be ready and login again.
    Redfish.Login

    # CertificateMappingAttribute is not persisted by bmcweb
    # (in-memory only), so restore it after reboot.
    Set Certificate Mapping Attribute  CommonName

    # Verify CA certs persisted and mTLS still works.
    MTLS CN Auth Should Succeed

Verify MTLS Fails With Expired Certificate
    [Documentation]  Verify mTLS authentication fails when the
    ...  client certificate has expired.
    [Tags]  Verify_MTLS_Fails_With_Expired_Certificate

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/expired-cert.pem
    ...  ${MTLS_CERT_DIR}/expired-key.pem

Verify MTLS Fails With Not Yet Valid Certificate
    [Documentation]  Verify mTLS authentication fails when the
    ...  client certificate is not yet valid.
    [Tags]  Verify_MTLS_Fails_With_Not_Yet_Valid_Certificate

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/not-yet-valid-cert.pem
    ...  ${MTLS_CERT_DIR}/not-yet-valid-key.pem

Verify MTLS Fails With Untrusted CA
    [Documentation]  Verify mTLS authentication fails when the
    ...  client certificate is signed by a CA not in the BMC
    ...  truststore.
    [Tags]  Verify_MTLS_Fails_With_Untrusted_CA

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/untrusted-client-cert.pem
    ...  ${MTLS_CERT_DIR}/untrusted-client-key.pem

Verify MTLS Fails With Non Existent Username
    [Documentation]  Verify mTLS authentication fails when the
    ...  certificate CN maps to a user that does not exist on
    ...  the BMC.
    [Tags]  Verify_MTLS_Fails_With_Non_Existent_Username

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/nonexistent-cert.pem
    ...  ${MTLS_CERT_DIR}/nonexistent-key.pem

Verify MTLS Fails With Wrong EKU
    [Documentation]  Verify mTLS authentication fails when the
    ...  client certificate has ServerAuth EKU instead of
    ...  ClientAuth.
    [Tags]  Verify_MTLS_Fails_With_Wrong_EKU

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/wrong-eku-cert.pem
    ...  ${MTLS_CERT_DIR}/wrong-eku-key.pem

Verify MTLS Fails With No Username In Certificate
    [Documentation]  Verify mTLS authentication fails when the
    ...  client certificate has no CN and no UPN SAN.
    [Tags]  Verify_MTLS_Fails_With_No_Username_In_Certificate

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/no-username-cert.pem
    ...  ${MTLS_CERT_DIR}/no-username-key.pem

Verify MTLS Fails With Self Signed Client Certificate
    [Documentation]  Verify mTLS authentication fails when the
    ...  client certificate is self-signed and not signed by a
    ...  trusted CA.
    [Tags]  Verify_MTLS_Fails_With_Self_Signed_Client_Certificate

    MTLS Auth Should Fail
    ...  ${MTLS_CERT_DIR}/self-signed-cert.pem
    ...  ${MTLS_CERT_DIR}/self-signed-key.pem

Verify Removing CA From Truststore Breaks MTLS
    [Documentation]  Verify mTLS authentication fails after the
    ...  CA certificate is removed from the BMC truststore.
    [Tags]  Verify_Removing_CA_From_Truststore_Breaks_MTLS
    [Teardown]  Restore CA After Removal

    # Verify mTLS works with CA installed.
    MTLS CN Auth Should Succeed

    # Delete all CA certs from truststore.
    Delete All CA Certificate Via Redfish

    # Verify mTLS now fails.
    MTLS CN Auth Should Fail

Verify Adding Second CA Allows Both To Authenticate
    [Documentation]  Verify clients from two different CAs can
    ...  both authenticate when both CA certs are in the
    ...  truststore.
    [Tags]  Verify_Adding_Second_CA_Allows_Both_To_Authenticate
    [Teardown]  Remove Second CA Teardown

    # Install second CA.
    ${ca2_cert}=  OperatingSystem.Get File
    ...  ${MTLS_CERT_DIR}/ca2-cert.pem
    Install CA Certificate On BMC  ${ca2_cert}

    # Both client certs should work.
    MTLS CN Auth Should Succeed
    MTLS Auth Should Succeed
    ...  ${MTLS_CERT_DIR}/ca2-client-cert.pem
    ...  ${MTLS_CERT_DIR}/ca2-client-key.pem

Verify Server Certificate Replacement Preserves MTLS
    [Documentation]  Verify mTLS authentication continues to work
    ...  after the server HTTPS certificate is replaced.
    [Tags]  Verify_Server_Certificate_Replacement_Preserves_MTLS

    # Verify mTLS works before server cert replace.
    MTLS CN Auth Should Succeed

    # Generate and replace server certificate.
    Replace Certificate Via Redfish  Server
    ...  Valid Certificate Valid Privatekey  ok
    Sleep  ${CERT_INSTALL_WAIT}s

    # Verify mTLS still works after server cert replace.
    MTLS CN Auth Should Succeed

Verify Disabling TLS Auth Rejects MTLS
    [Documentation]  Verify mTLS authentication is rejected when
    ...  TLS authentication is disabled on the BMC.
    [Tags]  Verify_Disabling_TLS_Auth_Rejects_MTLS
    [Teardown]  Run Keywords
    ...  Enable TLS Authentication
    ...  AND  MTLS Test Teardown

    Disable TLS Authentication
    MTLS CN Auth Should Fail

Verify Re-enabling TLS Auth Restores MTLS
    [Documentation]  Verify mTLS authentication works again after
    ...  TLS auth is disabled and re-enabled without
    ...  re-installing certificates.
    [Tags]  Verify_Re-enabling_TLS_Auth_Restores_MTLS

    # Disable TLS auth.
    Disable TLS Authentication
    MTLS CN Auth Should Fail

    # Re-enable TLS auth.
    Enable TLS Authentication
    MTLS CN Auth Should Succeed

*** Keywords ***

Admin And ReadOnly Teardown
    [Documentation]  Clean up readonly user after test.

    Run Keyword And Ignore Error
    ...  Redfish.Delete
    ...  ${REDFISH_ACCOUNTS_URI}${READONLY_USERNAME}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    MTLS Test Teardown

Verify Certificate Mapping Is
    [Documentation]  Verify CertificateMappingAttribute matches
    ...  the expected value. Fails if not, for use with
    ...  Wait Until Keyword Succeeds.
    [Arguments]  ${expected}

    # Description of argument(s):
    # expected  Expected mapping attribute value.

    ${attr}=  Get Certificate Mapping Attribute
    Should Be Equal As Strings  ${attr}  ${expected}

Restore MTLS State After Reboot
    [Documentation]  Restore mTLS state after reboot test to
    ...  ensure subsequent tests have a clean environment.

    Run Keyword And Ignore Error
    ...  Set Certificate Mapping Attribute  CommonName
    Run Keyword And Ignore Error
    ...  Enable TLS Authentication
    # Reinstall CA if mTLS auth is broken.
    ${status}=  Run Keyword And Return Status
    ...  MTLS CN Auth Should Succeed
    IF  not ${status}
        Run Keyword And Ignore Error
        ...  Delete All CA Certificate Via Redfish
        Run Keyword And Ignore Error
        ...  Reinstall Primary CA
    END
    MTLS Test Teardown

Reinstall Primary CA
    [Documentation]  Re-install the primary CA and update suite var.

    ${ca_cert_id}=  Install CA Certificate On BMC  ${CA_CERT_PEM}
    Set Suite Variable  ${CA_CERT_ID}  ${ca_cert_id}

Restore CA After Removal
    [Documentation]  Re-install CA cert after removal test.

    Reinstall Primary CA
    MTLS Test Teardown

Remove Second CA Teardown
    [Documentation]  Remove second CA and keep only the primary.

    Delete All CA Certificate Via Redfish
    Reinstall Primary CA
    MTLS Test Teardown
