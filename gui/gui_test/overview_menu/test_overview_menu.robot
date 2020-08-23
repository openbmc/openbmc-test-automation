*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}      //h1[contains(text(), "Overview")]
${string_launch_serial_over_lan}   Access the Serial over LAN console
${xpath_launch_serial_over_lan}    //a[@href='#/control/serial-over-lan']

*** Test Cases ***

Verify Launching Of Serial Over LAN Console At OBMC Power Off State
    [Documentation]  Will open the serial over the lan command prompt window.
    [Tags]  Verify_Launching_Of_Serial_Over_LAN_Console_At_OBMC_Power_Off_State

    Click Element  ${xpath_launch_serial_over_lan}
    Verify Display Content  ${string_launch_serial_over_lan}


Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


*** Keywords ***

Verify Display Content
    [Documentation]  Verify text content display.
    [Arguments]  ${display_text}
    # Description of argument(s):
    # display_text   The display text on web page.

    Page Should Contain  ${display_text}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

