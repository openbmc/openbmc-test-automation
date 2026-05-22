*** Settings ***
Documentation  Test OpenBMC GUI "Certificates" sub-menu of "Security and access".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/certificate_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers
Test Setup      Test Setup Execution

Test Tags       Certificates_Sub_Menu

*** Variables ***

${MUL_CA_CERTIFICATES}             3
${xpath_certificate_heading}       //h1[text()="Certificates"]
${xpath_add_certificate_button}    //button[contains(normalize-space(.),"Add new certificate")]
${xpath_generate_csr_button}       //*[@data-test-id='certificates-button-generateCsr']
${xpath_generate_csr_heading}      //h5[contains(normalize-space(.), "Generate a Certificate Signing Request")]
${xpath_select_certificate_type}   //*[@data-test-id='modalGenerateCsr-select-certificateType']
${xpath_key_pair_algoritham}       //*[@data-test-id='modalGenerateCsr-select-keyPairAlgorithm']
${xpath_select_country}            //*[@data-test-id='modalGenerateCsr-select-country']
${xpath_input_state}               //*[@data-test-id='modalGenerateCsr-input-state']
${xpath_input_city}                //*[@data-test-id='modalGenerateCsr-input-city']
${xpath_input_company_name}        //*[@data-test-id='modalGenerateCsr-input-companyName']
${xpath_input_company_unit}        //*[@data-test-id='modalGenerateCsr-input-companyUnit']
${xpath_input_common_name}         //*[@data-test-id='modalGenerateCsr-input-commonName']
${xpath_input_contact_person}      //*[@data-test-id='modalGenerateCsr-input-contactPerson']
${xpath_input_email_address}       //*[@data-test-id='modalGenerateCsr-input-emailAddress']
${xpath_generate_csr_submit}       //button[text()='Generate CSR']
${xpath_csr_cancel_button}         //button[normalize-space()='Generate CSR']/preceding-sibling::button
${xpath_select_algorithm_button}   //*[@data-test-id='modalGenerateCsr-select-keyPairAlgorithm']
${xpath_delete_ca_certificate}     (//*[@title="Delete certificate"])[2]
${xpath_delete_ldap_certificate}   //tr[.//td[normalize-space()='LDAP Certificate']]//button[@disabled]
${xpath_delete_https_certificate}  //tr[.//td[normalize-space()='HTTPS Certificate']]//button[@disabled]
${xpath_cancel_button}             //button[normalize-space()='Add']/preceding-sibling::button[1]
${xpath_confirm_delete_button}     //button[text()='Delete']
${xpath_cancel_delete_button}      //button[normalize-space()='Delete']/preceding-sibling::button
${xpath_close_generate_csr}        (//button[contains(@class,'btn-close')])[3]
${xpath_ca_certificate_rows}       //tr[.//td[normalize-space()='CA Certificate']]


*** Test Cases ***

Verify Navigation To Certificate Page
    [Documentation]  Verify navigation to certificate page.
    [Tags]  Verify_Navigation_To_Certificate_Page

    Page Should Contain Element  ${xpath_certificate_heading}


Verify Existence Of All Sections In Certificate Page
    [Documentation]  Verify existence of all sections in certificate page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Certificate_Page

    Page Should Contain  Certificate
    Page Should Contain  Issued by
    Page Should Contain  Issued to
    Page Should Contain  Valid from
    Page Should Contain  Valid until


Verify Existence Of Add Certificate Button
    [Documentation]  Verify existence of add certificate button.
    [Tags]  Verify_Existence_Of_Add_Certificate_Button

    Page Should Contain Element  ${xpath_add_certificate_button}
    Page Should Contain Element  ${xpath_generate_csr_button}


Verify Generate CSR Certificate Button
    [Documentation]  Verify existence of all the fields of CSR generation.
    [Tags]  Verify_Generate_CSR_Certificate_Button
    [Teardown]  Click Element  ${xpath_csr_cancel_button}

    Page Should Contain Element  ${xpath_generate_csr_button}
    Click Element  ${xpath_generate_csr_button}
    Wait Until Page Contains Element  ${xpath_generate_csr_heading}

    Page Should Contain Element  ${xpath_select_certificate_type}
    Page Should Contain Element  ${xpath_select_country}
    Page Should Contain Element  ${xpath_input_state}
    Page Should Contain Element  ${xpath_input_city}
    Page Should Contain Element  ${xpath_input_company_name}
    Page Should Contain Element  ${xpath_input_common_name}
    Page Should Contain Element  ${xpath_input_contact_person}
    Page Should Contain Element  ${xpath_input_email_address}
    Page Should Contain Element  ${xpath_select_algorithm_button}
    Page Should Contain Element  ${xpath_generate_csr_submit}
    Page Should Contain Element  ${xpath_key_pair_algoritham}


Verify Informational Message Under Add Certificate
    [Documentation]  Verify informational message under add certificate tab.
    [Tags]  Verify_Informational_Message_Under_Add_Certificate

    Click Element  ${xpath_add_certificate_button}
    Wait Until Page Contains Element  ${xpath_cancel_button}
    Page Should Contain  BMC shell and Resource dump ACF certificates will not be listed in the table.
    ...                  System has to be powered on to upload Resource dump ACF certificate.
    Click Element  ${xpath_cancel_button}


Verify Delete Button Should Be Disabled For HTTPS And LDAP Certificates
    [Documentation]  Verify delete buttons should be disabled for HTTPS and LDAP certificates.
    [Tags]  Verify_Delete_Button_Should_Be_Disabled_For_HTTPS_And_LDAP_Certificates
    [Setup]  Run Keywords  Delete Certificate Via BMC CLI  Client  AND
    ...      Install And Verify Certificate Via Redfish  Client  Valid Certificate Valid Privatekey  ok

    Element Should Be Disabled  ${xpath_delete_ldap_certificate}
    Element Should Be Disabled  ${xpath_delete_https_certificate}


Verify Installed CA Certificate
    [Documentation]  Install CA certificate and verify the same via GUI.
    [Tags]  Verify_Installed_CA_Certificate
    [Setup]  Run Keywords  Delete All CA Certificate Via Redfish  AND
    ...      Test Setup Execution

    # Install CA certificate via Redfish.
    ${file_data}=  Generate Certificate File Data  CA
    Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok

    # Refresh GUI and verify CA certificate availability in GUI.
    Refresh GUI
    Wait Until Page Contains  CA Certificate  timeout=10


Install Multiple CA Certificates And Verify
    [Documentation]  Install multiple CA certificates and verify them in GUI.
    [Tags]  Install_Multiple_CA_Certificates_And_Verify
    [Teardown]  Cleanup And Restore Single CA Certificate

    Redfish.Login
    ${initial_cert_count}=  Get CA Certificate Count Via Redfish
    Install Multiple CA Certificates  ${initial_cert_count}  ${MUL_CA_CERTIFICATES}
    Verify Certificate Count Via Redfish  ${MUL_CA_CERTIFICATES}
    Redfish.Logout

    Verify CA Certificate Count In GUI  ${MUL_CA_CERTIFICATES}


Verify Installed HTTPS Certificate
    [Documentation]  Install HTTPS certificate via Redfish and verify it in GUI.
    [Tags]  Verify_Installed_HTTPS_Certificate

    # Replace HTTPS certificate.
    Redfish.Login
    Replace Certificate Via Redfish  Server   Valid Certificate Valid Privatekey  ok
    Redfish.Logout

    # Verify certificate is available in GUI.
    Wait Until Page Contains  HTTPS Certificate  timeout=10


Verify Installed LDAP Certificate
    [Documentation]  Install LDAP certificate via Redfish and verify it in GUI.
    [Tags]  Verify_Installed_LDAP_Certificate

    Redfish.Login
    Delete Certificate Via BMC CLI  Client

    # Install LDAP certificate.
    ${file_data}=  Generate Certificate File Data  Client
    Install And Verify Certificate Via Redfish  Client  Valid Certificate Valid Privatekey  ok
    Redfish.Logout

    # Refresh GUI and verify certificate is available in GUI.
    Refresh GUI
    Wait Until Page Contains  LDAP Certificate  timeout=10


Replace CA Certificate And Verify
    [Documentation]  Replace CA certificate and verify it in GUI.
    ...  Verifies that the certificate content changed and count remained at 1.
    [Tags]  Replace_CA_Certificate_And_Verify
    [Setup]  Install CA Certificate
    [Teardown]  Cleanup And Restore Single CA Certificate

    Redfish.Login
    ${original_cert_string}=  Get CA Certificate Content And Verify Count  1
    Replace Certificate Via Redfish  CA  Valid Certificate  ok
    ${new_cert_string}=  Get CA Certificate Content And Verify Count  1
    Verify Certificate Content Changed  ${original_cert_string}  ${new_cert_string}
    Redfish.Logout

    Verify CA Certificate Count In GUI  1


Verify Success Message After Deleting CA Certificate
    [Documentation]  Delete CA certificate and verify success message on BMC GUI page.
    [Tags]  Verify_Success_Message_After_Deleting_CA_Certificate
    [Setup]  Install CA Certificate
    [Teardown]  Install CA Certificate

    Click Element  ${xpath_delete_ca_certificate}
    Sleep  15s
    Click Element  ${xpath_confirm_delete_button}
    Verify Success Message On BMC GUI Page


Verify Cancel Button While Deleting The CA Certificate
    [Documentation]  Verify Cancel button while deleting the CA certificate
    [Tags]  Verify_Cancel_Button_While_Deleting_The_CA_Certificate
    [Setup]  Install CA Certificate

    Click Element  ${xpath_delete_ca_certificate}
    Click Element  ${xpath_cancel_delete_button}
    Page Should Not Contain  ${xpath_cancel_delete_button}


Verify Certificate Page With Readonly User
    [Documentation]  Verify Certificate page with readonly user.
    [Tags]  Verify_Certificate_Page_With_Readonly_User
    [Setup]  Run Keywords  Logout GUI  AND  Create Readonly User And Login To GUI
    ...      AND  Navigate To Required Sub Menu  ${xpath_security_and_access_menu}
    ...      ${xpath_certificates_sub_menu}  certificates
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Page Should Contain  No items available
    Element Should Be Disabled  ${xpath_add_certificate_button}


*** Keywords ***

Generate Certificate File Data
    [Documentation]  Generate data of certificate file.
    [Arguments]  ${cert_type}

    # Description of Arguments(s):
    # cert_type      Certificate type (e.g. "Client" or  "CA").

    IF  '${cert_type}' == 'Client' or '${cert_type}' == 'Server'
      ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate Valid Privatekey
    ELSE IF  '${cert_type}' == 'CA'
      ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate
    END

    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    RETURN  ${file_data}


Test Setup Execution
    [Documentation]  Do test case setup tasks.
    # Check if Generate CSR is open, if open close it.

    ${generate_csr_open}=    Run Keyword And Return Status    Element Should Be Visible
    ...    ${xpath_close_generate_csr}
    IF  ${generate_csr_open}
        Click Element    ${xpath_close_generate_csr}
    END
    Click Element  ${xpath_security_and_access_menu}
    Click Element  ${xpath_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  certificates
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


Suite Setup Execution
    [Documentation]  Do test case suite setup tasks.

    # Remove brackets from OPENBMC_HOST for IPv6 addresses (static IPv6 or SLAAC).
    ${OPENBMC_HOST}=  Evaluate  "${OPENBMC_HOST}".replace("[","").replace("]","")
    Set Suite Variable  ${OPENBMC_HOST}

    Launch Browser And Login GUI
    Create Directory  certificate_dir


Install CA Certificate
    [Documentation]  Install CA certificate via redfish.

    Redfish.Login
    Delete All CA Certificate Via Redfish

    # Install CA certificate via Redfish.
    ${file_data}=  Generate Certificate File Data  CA
    Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok

    # Refresh GUI and verify CA certificate availability in GUI.
    Refresh GUI
    Click Element    ${xpath_security_and_access_menu}
    Click Element    ${xpath_certificates_sub_menu}
    Wait Until Page Contains  CA Certificate  timeout=10


Cleanup And Restore Single CA Certificate
    [Documentation]  Clean up all CA certificates and restore one for other tests.

    Redfish.Login
    Delete All CA Certificate Via Redfish
    Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok  ${FALSE}
    Redfish.Logout


Get CA Certificate Count Via Redfish
    [Documentation]  Get CA certificate count from BMC via Redfish.

    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates
    ${cert_count}=  Get Length  ${cert_list}

    RETURN  ${cert_count}


Install Multiple CA Certificates
    [Documentation]  Install multiple CA certificates with error handling.
    [Arguments]  ${start_count}  ${target_count}

    # Description of argument(s):
    # start_count    Initial certificate count.
    # target_count   Target number of certificates to reach.

    FOR  ${INDEX}  IN RANGE  ${start_count}  ${target_count}
      TRY
        Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok  ${FALSE}
      EXCEPT
        Log  Failed to install certificate at index ${INDEX}  level=ERROR
        FAIL  Certificate installation failed at index ${INDEX}
      END
    END


Verify Certificate Count Via Redfish
    [Documentation]  Verify certificate count via Redfish matches expected count.
    [Arguments]  ${expected_count}

    # Description of argument(s):
    # expected_count    Expected number of certificates.

    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates
    ${actual_count}=  Get Length  ${cert_list}
    Should Be Equal As Integers  ${actual_count}  ${expected_count}
    ...  msg=Expected ${expected_count} certificates but found ${actual_count}


Verify CA Certificate Count In GUI
    [Documentation]  Verify CA certificate count in GUI matches expected count.
    [Arguments]  ${expected_count}

    # Description of argument(s):
    # expected_count    Expected number of CA certificates in GUI.

    Refresh GUI
    Wait Until Page Contains  CA Certificate  timeout=10
    ${gui_cert_count}=  Get Element Count  ${xpath_ca_certificate_rows}
    Should Be Equal As Integers  ${gui_cert_count}  ${expected_count}
    ...  msg=Expected ${expected_count} CA certificates in GUI but found ${gui_cert_count}


Get CA Certificate Content And Verify Count
    [Documentation]  Get CA certificate content and verify count.
    [Arguments]  ${expected_count}

    # Description of argument(s):
    # expected_count    Expected number of certificates.

    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates
    Should Not Be Empty  ${cert_list}  msg=No CA certificates found
    ${actual_count}=  Get Length  ${cert_list}
    Should Be Equal As Integers  ${actual_count}  ${expected_count}
    ...  msg=Expected ${expected_count} certificate(s) but found ${actual_count}

    ${cert_id}=  Get From List  ${cert_list}  0
    ${cert_id}=  Fetch From Right  ${cert_id}  /
    Should Not Be Empty  ${cert_id}  msg=Failed to extract certificate ID

    ${cert_dict}=  Redfish.Get Properties  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates/${cert_id}
    ${cert_string}=  Get From Dictionary  ${cert_dict}  CertificateString

    RETURN  ${cert_string}


Verify Certificate Content Changed
    [Documentation]  Verify that certificate content has changed.
    [Arguments]  ${original_content}  ${new_content}

    # Description of argument(s):
    # original_content    Original certificate content.
    # new_content         New certificate content.

    Should Not Be Equal  ${original_content}  ${new_content}
    ...  msg=Certificate content did not change after replacement
