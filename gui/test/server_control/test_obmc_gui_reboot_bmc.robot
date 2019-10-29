*** Settings ***

Documentation  Test OpenBMC GUI "Reboot BMC" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_reboot_bmc_button}  //button[text()[contains(.,"Reboot BMC")]]


*** Test Cases ***

Verify Existence Of All Sections In Reboot BMC Page
    [Documentation]  Verify existence of all sections in reboot BMC page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Reboot_BMC_Page

    Page Should Contain  Current BMC boot status


Verify Existence Of All Buttons In Reboot BMC Page
    [Documentation]  Verify existence of all buttons in reboot BMC page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Reboot_BMC_Page

    Page Should Contain Element  ${xpath_reboot_bmc_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_reboot_bmc}
    Wait Until Page Contains  Reboot BMC
