*** Settings ***
Documentation  This test suite will validate the "OpenBMC ASMI Menu ->
...            Server Overview" module.

Resource         ../../lib/resource.robot
Test Setup       OpenBMC Test Setup  ${OBMC_PowerOff_state}
Test Teardown    OpenBMC Test Closure

*** Variables ***
${xpath_select_overview_1}      //*[@id="nav__top-level"]/li[1]/a/span
${xpath_select_overview_2}      //a[@href='#/overview/system']
${string_content}               IBM Power Witherspoon 2
${string_server_info}           Server information
${string_high_priority_events}  High priority events

*** Test Case ***
# Following test cases are executed at OpenBMC ready (Power Off) state.

Verify Title Text Content At OBMC Power Off State
    [Documentation]  Verify display of title text from "Server Overview".
    ...  module of OpenBMC GUI.
    [Tags]  Verify_Title_Text_Content_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_state

    Select Server Overview Menu
    Verify Display Content  ${string_content}

Verify Display Text Server Information At OBMC Power Off State
    [Documentation]  Verify existense of text "Server information".
    [Tags]  Verify_Display_Text_Server_Information_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_state

    Select Server Overview Menu
    Verify Display Content  ${string_server_info}


# Following test cases are executed at OpenBMC Running (Power Runniung) state.

High Priority Events Can Be Operated At OBMC Power Running State
    [Documentation]  Will open the "High Priority Events"
    ...  menu to view and operate.
    [Tags]  High_Priority_Events_Can_Be_Operated_At_OBMC_Power_Running_State
    ...  OBMC_PowerRunning_state
    [Setup]  OpenBMC Test Setup  ${OBMC_PowerRunning_state}

    Select Server Overview Menu
    Verify Display Content  ${string_HIGH_PRIORITY_EVENTS}

*** Keywords ***
Select Server Overview Menu
    [Documentation]  Selecting of OpenBMC "Server overview" menu.
    Click Button  ${xpath_select_overview_1}

Verify Display Content
    [Documentation]  Verify text content display.
    [Arguments]  ${display_text}=

    # Description of argument(s):
    # display_text   The display text on web page
    Click Button  ${xpath_select_overview_2}
    Page Should Contain  ${display_text}
