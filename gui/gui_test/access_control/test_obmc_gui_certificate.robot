*** Settings ***

Documentation  Test OpenBMC GUI "SSL Certificates" sub-menu of "Access control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_certificate_heading}     //h1[text()="SSL certificates"]
${xpath_add_certificate_button}  //button[contains(text(),"Add new certificate")]

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


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ssl_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ssl-certificates
