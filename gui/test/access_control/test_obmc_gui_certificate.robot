*** Settings ***

Documentation  Test OpenBMC GUI "Certificate management" sub-menu of
...            "Server configuration".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_select_certificate_management}  //a[@href='#/access-control/ssl-certificates']
${xpath_select_access_control}          //*[@id="nav__top-level"]/li[5]/button
${xpath_add_certificate_button}         //*[contains(text(), "Add new certificate")]

*** Test Cases ***

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

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_access_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_certificate_management}
    Wait Until Page Contains  SSL certificates
