*** Settings ***

Documentation  Test Open BMC GUI server configuration firmware update.

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***

${xpath_firmware_heading}         //h1[text()="Firmware"]
${xpath_change_image_and_reboot}  //button[text()[contains(.,"Change image and reboot BMC")]]
${xpath_upload_image_and_reboot}  //button[text()[contains(.,"Upload and reboot BMC")]]

*** Test Cases ***

Verify Navigation To Firmware Page
	[Documentation]  Verify navigation to firmware page.
	[Tags]  Verify_Navigation_To_Firmware_Page

    Page Should Contain Element  ${xpath_firmware_heading}


Verify Existence Of All Sections In Firmware Page
    [Documentation]  Verify existence of all sections in firmware page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Firmware_Page

    Page Should Contain  Firmware on system
    Page Should Contain  Change to backup image
    Page Should Contain  Update code


Verify Existence Of All Buttons In Firmware Page
    [Documentation]  Verify existence of all buttons in firmware page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page

    Page Should Contain Element  ${xpath_change_image_and_reboot}
    Page Should Contain Element  ${xpath_upload_image_and_reboot}

