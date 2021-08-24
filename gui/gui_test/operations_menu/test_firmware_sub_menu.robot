*** Settings ***

Documentation  Test OpenBMC Firmware Update" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***

${xpath_firmware_heading}         //h1[text()="Firmware"]
${xpath_change_image_and_reboot}  //button[contains(text(),'Change image and reboot BMC')]
${xpath_upload_image_and_reboot}  //button[contains(text(),'Upload and reboot BMC')]

*** Test Cases ***

Verify Navigation To Firmware Page
    [Documentation]  Verify navigation to firmware page.
    [Tags]  Verify_Navigation_To_Firmware_Page

    Page Should Contain Element  ${xpath_firmware_heading}


Verify Existence Of All Sections In Firmware Page
    [Documentation]  Verify existence of all sections in firmware page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Firmware_Page

    Page Should Contain  BMC and server
    Page Should Contain  Update firmware


Verify Existence Of All Buttons In Firmware Page
    [Documentation]  Verify existence of all buttons in firmware page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page

    Page Should Contain Element  ${xpath_change_image_and_reboot}
    Page Should Contain Element  ${xpath_upload_image_and_reboot}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_firmware_update_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  firmware
