*** Settings ***

Documentation  Test OpenBMC GUI "Virtual Media" sub-menu of "Control" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_virtual_media_heading}     //h1[text()="Virtual media"]
${xpath_virtual_media_input}       //input[@id='Virtual media device']
${xpath_start_virtual_media}       //button[contains(text(),'Start')]


*** Test Cases ***

Verify Navigation To Virtual Media
    [Documentation]  Verify navigation to Virtual Media.
    [Tags]  Verify_Navigation_To_Virtual_Media

    Page Should Contain Element  ${xpath_virtual_media_heading}


Verify Existence Of All Sections In Virtual Media
    [Documentation]  Verify existence of all sections in Virtual Media.
    [Tags]  Verify_Existence_Of_All_Sections_In_Virtual_Media

    Page Should Contain  Save image in a web browser
    Page Should Contain  Virtual media device


Verify Existence Of All Buttons In Virtual media Page
    [Documentation]  Verify existence of all buttons in Virtual media page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Virtual_media_Page

    Page Should Contain Element  ${xpath_virtual_media_input}
    Page Should Contain Element  ${xpath_start_virtual_media}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_virtual_media_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  virtual-media
