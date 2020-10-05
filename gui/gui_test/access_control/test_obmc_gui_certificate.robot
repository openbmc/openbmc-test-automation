*** Settings ***

Documentation  Test OpenBMC GUI "SSL Certificates" sub-menu of "Access control".

Resource        ../../lib/resource.robot
Resource        ../../../lib/certificate_utils.robot

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
    [Documentation]  Install CA certificate and verify the same via GUI.
    [Tags]  Verify_Installed_CA_Certificate

    Delete All CA Certificate Via Redfish

    # Install CA certificate via Redfish.
    ${file_data}=  Generate Certificate File Data
    Install Certificate File On BMC  ${REDFISH_CA_CERTIFICATE_URI}  ok  data=${file_data}

    # Verify CA certificate availability in GUI.
    Page Should Contain  CA Certificate


*** Keywords ***

Generate Certificate File Data
    [Documentation]  Generate data of certificate file.

    ${cert_file_path}=  Generate Certificate File Via Openssl  Valid Certificate  365
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    [return]  ${file_data}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ssl_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  ssl-certificates


Suite Setup Execution
    [Documentation]  Do test case suite setup tasks.

    Launch Browser And Login GUI
    Create Directory  certificate_dir
