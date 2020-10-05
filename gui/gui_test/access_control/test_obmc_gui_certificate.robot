*** Settings ***

Documentation  Test OpenBMC GUI "SSL Certificates" sub-menu of "Access control".

Resource        ../../lib/resource.robot
Resource        ../../../lib/certificate_utils.robot

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


Verify Installed CA Certificate
    [Documentation]  Install CA certificate and verify the installed certificate in GUI.
    [Tags]  Verify_Installed_CA_Certificate

    # install CA certificate
    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate  365
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8
    Install Certificate File On BMC  ${REDFISH_CA_CERTIFICATE_URI}  ok  data=${file_data}

    # Verify certificate is available in GUI
    Page Should Contain  CA Certificate


Verify Installed HTTPS Certificate
    [Documentation]  Install https certificate and verify the installed certificate in GUI.
    [Tags]  Verify_Installed_HTTPS_Certificate

    # install HTTPS certificate.
    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate  365
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8
    Install Certificate File On BMC  ${REDFISH_HTTPS_CERTIFICATE_URI}  ok  data=${file_data}

    # Verify certificate is available in GUI.
    Page Should Contain  HTTPS Certificate


Verify Installed LDAP Certificate
    [Documentation]  Install ldap certificate and verify the installed certificate in GUI.
    [Tags]  Verify_Installed_LDAP_Certificate

    # install HTTPS certificate.
    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate  365
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8
    Install Certificate File On BMC  ${REDFISH_LDAP_CERTIFICATE_URI}  ok  data=${file_data}

    # Verify certificate is available in GUI.
    Page Should Contain  LDAP Certificate


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Create Directory  certificate_dir
    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ssl_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ssl-certificates
