*** Settings ***

Documentation  Test suit for OpenBMC GUI "Field core override" sub-menu of "Resource Management".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_field_core_sub_menu}            //*[@data-test-id='nav-item-field-core-override']
${xpath_field_core_override_header }    //h1[text()="Field core override"]

*** Test Cases ***

Verify Navigate To Field Core Override Page
    [Documentation]  Login to GUI and perform page navigation to
    ...  field core override page and verify it loads successfully.
    [Tags]  Verify_Navigate_To_Field_Core_Override_Page

    Page Should Contain Element  ${xpath_field_core_override_header}


Verify Existence Of All Sections In Field Core Override Page
    [Documentation]  Login to GUI and perform page navigation to field core override page
    ...  and check if all visible sections is actually loaded successfully.
    [Tags]  Verify_Existence_Of_All_Sections_In_Field_Core_Override

    Page Should Contain  Current configuration
    Page Should Contain  Change configuration


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_resource_management_menu}
    Click Element  ${xpath_field_core_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  field-core-override

