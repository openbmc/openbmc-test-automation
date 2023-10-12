*** Settings ***

Documentation  Test suite for Open BMC GUI "Notices" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

Force Tags      Notices_Menu

*** Variables ***

${xpath_notice_menu}      //*[@data-test-id='nav-item-notices']
${xpath_notices_header}   //h1[contains(text(), "Notices")]

*** Test Cases ***

Verify Navigate To Notices Page
    [Documentation]  Login to GUI and perform page navigation to
    ...  Notices page and verify it loads successfully.
    [Tags]  Verify_Navigate_To_Notices_Page

    Page Should Contain Element  ${xpath_notices_header}


Verify Existence Of All Licenses In Notices Page
    [Documentation]  Verify all required licenses are available on Notices page.
    [Tags]  Verify_Existence_Of_All_Licenses_In_Notices_Page

    Page Should Contain  Apache License
    Page Should Contain  Artistic License
    Page Should Contain  BSD license
    Page Should Contain  Boost Software License
    Page Should Contain  Bzip license
    Page Should Contain  GNU GENERAL PUBLIC LICENSE
    Page Should Contain  GCC RUNTIME LIBRARY EXCEPTION
    Page Should Contain  ISC License
    Page Should Contain  GNU LIBRARY GENERAL PUBLIC LICENSE
    Page Should Contain  GNU LESSER GENERAL PUBLIC LICENSE
    Page Should Contain  MIT License
    Page Should Contain  Mozilla Public License Version
    Page Should Contain  OpenLDAP Public License
    Page Should Contain  OpenSSL License
    Page Should Contain  PYTHON SOFTWARE FOUNDATION LICENSE
    Page Should Contain  zlib License


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_notice_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  notices
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
