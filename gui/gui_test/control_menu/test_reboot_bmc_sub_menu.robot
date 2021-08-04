*** Settings ***

Documentation  Test OpenBMC GUI "Reboot BMC" sub-menu of "Server control".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_reboot_bmc_heading}      //h1[text()="Reboot BMC"]
${xpath_reboot_bmc_button}       //button[contains(text(),'Reboot BMC')]
${xpath_reboot_cancel_button}    //button[contains(text(),'Cancel')]
${xpath_reboot_confirm_button}   //button[contains(text(),'Confirm')]


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


Verify Confirming Operation On BMC Reboot
    [Documentation]  Verify Confirming Operation On BMC Reboot operation
    [Tags]  Verify_Confirming_Operation_On_BMC_Reboot_Operation

    Click Element  ${xpath_reboot_bmc_button}
    Click Element  ${xpath_reboot_confirm_button}
    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_reboot_bmc_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  reboot-bmc


Wait For Host To Ping
    [Documentation]  Wait for the given host to ping.
    [Arguments]  ${host}  ${timeout}=${OPENBMC_REBOOT_TIMEOUT}min
    ...          ${interval}=5 sec

    # Description of argument(s):
    # host      The host name or IP of the host to ping.
    # timeout   The amount of time after which ping attempts cease.
    #           This should be expressed in Robot Framework's time format
    #           (e.g. "10 seconds").
    # interval  The amount of time in between attempts to ping.
    #           This should be expressed in Robot Framework's time format
    #           (e.g. "5 seconds").

    Wait Until Keyword Succeeds  ${timeout}  ${interval}  Ping Host  ${OPENBMC_HOST}
