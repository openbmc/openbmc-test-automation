*** Settings ***

Documentation  Test OpenBMC GUI "Reboot BMC" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_reboot_bmc_heading}      //h1[text()="Reboot BMC"]
${xpath_reboot_bmc_button}       //button[contains(text(),'Reboot BMC')]
${xpath_reboot_cancel_button}    //button[contains(text(),'Cancel')]

*** Test Cases ***

Verify Navigation To Reboot BMC Page
    [Documentation]  Verify navigation to reboot BMC page.
    [Tags]  Verify_Navigation_To_Reboot_BMC_Page

    Page Should Contain Element  ${xpath_reboot_bmc_heading}


Verify Existence Of All Buttons In Reboot BMC Page
    [Documentation]  Verify existence of all buttons in reboot BMC page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Reboot_BMC_Page

    Page Should Contain Element  ${xpath_reboot_bmc_button}


Verify Existence Of All Sections In Reboot BMC Page
    [Documentation]  Verify Existence Of All Sections In Reboot BMC Page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Reboot_BMC_Page

    Page Should Contain  Last BMC reboot


Verify Canceling Operation On BMC Reboot Operation
    [Documentation]  Verify Canceling Operation On BMC Reboot operation
    [Tags]  Verify_Canceling_Operation_On_BMC_Reboot_Operation

    Click Element  ${xpath_reboot_bmc_button}
    Click Element  ${xpath_reboot_cancel_button}
    Wait Until Element Is Not Visible  ${xpath_reboot_cancel_button}  timeout=15


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_reboot_bmc_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  reboot-bmc
