*** Settings ***

Documentation  Test OpenBMC GUI "Certificates" sub-menu of "Security and access".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/certificate_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_certificate_heading}       //h1[text()="Certificates"]
${xpath_add_certificate_button}    //button[contains(text(),"Add new certificate")]
${xpath_generate_csr_button}       //*[@data-test-id='certificates-button-generateCsr']
${xpath_generate_csr_heading}      //h5[contains(text(), "Generate a Certificate Signing Request")]
${xpath_select_certificate_type}   //*[@data-test-id='modalGenerateCsr-select-certificateType']
${xpath_select_country}            //*[@data-test-id='modalGenerateCsr-select-country']
${xpath_input_state}               //*[@data-test-id='modalGenerateCsr-input-state']
${xpath_input_city}                //*[@data-test-id='modalGenerateCsr-input-city']
${xpath_input_company_name}        //*[@data-test-id='modalGenerateCsr-input-companyName']
${xpath_input_company_unit}        //*[@data-test-id='modalGenerateCsr-input-companyUnit']
${xpath_input_common_name}         //*[@data-test-id='modalGenerateCsr-input-commonName']
${xpath_input_challenge_password}  //*[@data-test-id='modalGenerateCsr-input-challengePassword']
${xpath_input_contact_person}      //*[@data-test-id='modalGenerateCsr-input-contactPerson']
${xpath_input_email_address}       //*[@data-test-id='modalGenerateCsr-input-emailAddress']
${xpath_generate_csr_submit}       //*[@data-test-id='modalGenerateCsr-button-ok']
${xpath_csr_cancel_button}         //button[contains(text(),"Cancel")]
${xpath_input_alternate_name}      //input[@id='alternate-name']
${xpath_select_algorithm_button}   //*[@data-test-id='modalGenerateCsr-select-keyPairAlgorithm']

*** Test Cases ***

Verify Navigation To Certificate Page
    [Documentation]  Verify navigation to certificate page.
    [Tags]  Verify_Navigation_To_Certificate_Page

    Page Should Contain Element  ${xpath_certificate_heading}


Verify Existence Of All Sections In Certificate Page
    [Documentation]  Verify existence of all sections in certificate page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Certificate_Page

    Page should contain  Certificate
    Page should contain  Valid from
    Page should contain  Valid until


Verify Existence Of Add Certificate Button
    [Documentation]  Verify existence of add certificate button.
    [Tags]  Verify_Existence_Of_Add_Certificate_Button

    Page Should Contain Element  ${xpath_add_certificate_button}

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
    Page Should Contain Element  ${xpath_input_challenge_password}
    Page Should Contain Element  ${xpath_input_contact_person}
    Page Should Contain Element  ${xpath_input_email_address}
    Page Should Contain Element  ${xpath_input_alternate_name}
    Page Should Contain Element  ${xpath_select_algorithm_button}
    Page Should Contain Element  ${xpath_generate_csr_submit}


Verify Installed CA Certificate
    [Documentation]  Install CA certificate and verify the same via GUI.
    [Tags]  Verify_Installed_CA_Certificate

    Delete All CA Certificate Via Redfish

    # Install CA certificate via Redfish.
    ${file_data}=  Generate Certificate File Data  CA
    Install Certificate File On BMC  ${REDFISH_CA_CERTIFICATE_URI}  ok  data=${file_data}

    # Refresh GUI and verify CA certificate availability in GUI.
    Refresh GUI
    Wait Until Page Contains  CA Certificate  timeout=10


Verify Installed HTTPS Certificate
    [Documentation]  Install HTTPS certificate via Redfish and verify it in GUI.
    [Tags]  Verify_Installed_HTTPS_Certificate

    # Replace HTTPS certificate.
    Replace Certificate Via Redfish  Server   Valid Certificate Valid Privatekey  ok

    # Verify certificate is available in GUI.
    Wait Until Page Contains  HTTPS Certificate  timeout=10


Verify Installed LDAP Certificate
    [Documentation]  Install LDAP certificate via Redfish and verify it in GUI.
    [Tags]  Verify_Installed_LDAP_Certificate

    Delete Certificate Via BMC CLI  Client

    # Install LDAP certificate.
    ${file_data}=  Generate Certificate File Data  Client
    Install Certificate File On BMC  ${REDFISH_LDAP_CERTIFICATE_URI}  ok  data=${file_data}

    # Refresh GUI and verify certificate is available in GUI.
    Refresh GUI
    Wait Until Page Contains  LDAP Certificate  timeout=10


*** Keywords ***

Generate Certificate File Data
    [Documentation]  Generate data of certificate file.

    [Arguments]  ${cert_type}

    # Description of Arguments(s):
    # cert_type      Certificate type (e.g. "Client" or  "CA").

    ${cert_file_path}=  Run Keyword If  '${cert_type}' == 'Client' or 'Server'
    ...    Generate Certificate File Via Openssl  Valid Certificate Valid Privatekey
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Generate Certificate File Via Openssl  Valid Certificate
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    [return]  ${file_data}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  certificates


Suite Setup Execution
    [Documentation]  Do test case suite setup tasks.

    Launch Browser And Login GUI
    Create Directory  certificate_dir
