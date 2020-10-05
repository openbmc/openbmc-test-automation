*** Settings ***

Documentation  Test OpenBMC GUI "SSL Certificates" sub-menu of "Access control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_certificate_heading}       //h1[text()="SSL certificates"]
${xpath_add_certificate_button}    //button[contains(text(),"Add new certificate")]
${xpath_generate_csr_button}       //*[@data-test-id='sslCertificates-button-generateCsr']
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
${xpath_input_alternate_name}      //input[@id='alternate-name']
${xpath_select_algorithm_button}   //*[@data-test-id='modalGenerateCsr-select-keyPairAlgorithm']

*** Test Cases ***

Verify Navigation To SSL Certificate Page
    [Documentation]  Verify navigation to SSL certificate page.
    [Tags]  Verify_Navigation_To_SSL_Certificate_Page

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


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ssl_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ssl-certificates
