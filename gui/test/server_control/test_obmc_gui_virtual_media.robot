*** Settings ***

Documentation  Test OpenBMC GUI "Virtual Media" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_start_button}        //*[@class='vm__upload-start']
${xpath_choose_file_button}  //*[@class='vm__upload-choose-label']


*** Test Cases ***

Verify Existence Of All Sections In Virtaul Media Page
    [Documentation]  Verify existence of all sections in virtaul media page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Virtaul_Media_Page

    Page Should Contain  Virtual media device


Verify Existence Of All Buttons In Virtaul Media Page
    [Documentation]  Verify existence of all buttons in virtual media page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Virtaul_Media_Page

    Page Should Contain Element  ${xpath_start_button}
    Page Should Contain Element  ${xpath_choose_file_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_virtual_media}
    Wait Until Page Contains  Virtual media
