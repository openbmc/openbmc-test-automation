*** Settings ***

Documentation    Test OpenBMC GUI "Policies" sub-menu of "Security and access" menu.

Resource         ../../lib/gui_resource.robot

Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_policies_heading}           //h1[text()="Policies"]
${xpath_bmc_ssh_toggle}             //*[@data-test-id='policies-toggle-bmcShell']
${xpath_network_ipmi_toggle}        //*[@data-test-id='polices-toggle-networkIpmi']


*** Test Cases ***

Verify Navigation To Policies Page
    [Documentation]  Verify navigation to Policies page.
    [Tags]  Verify_Navigation_To_Policies_Page

    Page Should Contain Element  ${xpath_policies_heading}


Verify Existence Of All Sections In Policies Page
    [Documentation]  Verify existence of all sections in policies page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Policies_Page

    Page Should Contain  Network services
    Page Should Contain  BMC shell (via SSH)
    Page Should Contain  Network IPMI (out-of-band IPMI)


Verify Existence Of All Buttons In Policies Page
    [Documentation]  Verify existence of All Buttons in policies page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Policies_Page

    Page Should Contain Element  ${xpath_bmc_ssh_toggle}
    Page Should Contain Element  ${xpath_network_ipmi_toggle}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_policies_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  policies
