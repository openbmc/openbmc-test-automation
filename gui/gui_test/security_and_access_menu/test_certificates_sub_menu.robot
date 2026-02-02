*** Settings ***

Documentation  Test OpenBMC GUI "Certificates" sub-menu of "Security and access".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/certificate_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers
Test Setup      Test Setup Execution

Test Tags      Certificates_Sub_Menu

*** Variables ***

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
${xpath_generate_csr_submit}       //button[contains(normalize-space(.),"Generate CSR")]
${xpath_csr_cancel_button}         //button[contains(normalize-space(.),"Cancel")]
${xpath_select_algorithm_button}   //*[@data-test-id='modalGenerateCsr-select-keyPairAlgorithm']
${xpath_delete_ca_certificate}     (//*[@title="Delete certificate"])[2]
${xpath_delete_ldap_certificate}   (//*[@title="Delete certificate"])[3]
${xpath_delete_https_certificate}  (//*[@title="Delete certificate"])[4]
${xpath_delete_button}             //button[contains(normalize-space(.),"Delete")]
${xpath_cancel_button}             //button[contains(normalize-space(.),"Cancel")]
#${xpath_confirm_delete_button}  to confirm the deletion of ceriticate.
${xpath_confirm_delete_button}   //button[@class='btn btn-md btn-primary' and contains(normalize-space(.), 'Delete')]
#${xpath_cancel_delete_button} to cancel the deletion of ceriticate.
${xpath_cancel_delete_button}    //div[@id='__BVID__162719___BV_modal__']//button[@type='button'][normalize-space()='Cancel']
#${xpath_close_generate_csr"} to close the Generate CSR page if its open , before opening any other sub menus
${xpath_close_generate_csr}       ////button[@class="btn-close"]

*** Test Cases ***

Verify Navigation To Certificate Page
    [Documentation]  Verify navigation to certificate page.
    [Tags]  Verify_Navigation_To_Certificate_Page

    Page Should Contain Element  ${xpath_certificate_heading}


Verify Existence Of All Sections In Certificate Page
    [Documentation]  Verify existence of all sections in certificate page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Certificate_Page

    Page should contain  Certificate
    Page should contain  Issued by
    Page should contain  Issued to
    Page should contain  Valid from
    Page should contain  Valid until


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
    [Setup]  Install CA Certificate

    Element Should Be Disabled  ${xpath_delete_ldap_certificate}
    Element Should Be Disabled  ${xpath_delete_https_certificate}


Verify Installed CA Certificate
    [Documentation]  Install CA certificate and verify the same via GUI.
    [Tags]  Verify_Installed_CA_Certificate
    #Added Test Setup Execution in Setup to navigate to Certificates page.
    [Setup]    Run Keywords  Delete All CA Certificate Via Redfish  AND
    ...  Test Setup Execution

    # Install CA certificate via Redfish.
    ${file_data}=  Generate Certificate File Data  CA
    Install And Verify Certificate Via Redfish  CA  Valid Certificate  ok

    # Refresh GUI and verify CA certificate availability in GUI.
    Refresh GUI
    Wait Until Page Contains  CA Certificate  timeout=10


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
     Page Should Not Contain Element  Click Element  ${xpath_cancel_delete_button}


Verify Certificate Page With Readonly User
    [Documentation]  Verify Certificate page with readonly user.
    [Tags]  Verify_Certificate_Page_With_Readonly_User
    [Setup]  Run Keywords  Logout GUI  AND  Create Readonly User And Login To GUI
    ...      AND  Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}
    ...      ${xpath_certificates_sub_menu}  certificates
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Page Should Contain  No items available


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
    #Check if Generate CSR is open, if open close it.
    ${generate_csr_open}=    Run Keyword And Return Status    Element Should Be Visible
    ...    ${xpath_close_generate_csr}
    Run Keyword If    ${generate_csr_open}    Click Element    ${xpath_close_generate_csr}
    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  certificates
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


Suite Setup Execution
    [Documentation]  Do test case suite setup tasks.

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
    Click Element    ${xpath_secuity_and_accesss_menu}
    Click Element    ${xpath_certificates_sub_menu}
    Wait Until Page Contains  CA Certificate  timeout=10

