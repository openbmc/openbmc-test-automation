*** Settings ***
Documentation  This test suite will validate the "OpenBMC ASMI Menu ->
...            Server Overview" module.

Resource         ../../lib/resource.robot
Resource         ../../../lib/bmc_network_utils.robot
Test Setup       Test Setup Execution  ${OBMC_PowerOff_state}
Test Teardown    Test Teardown Execution

*** Variables ***
${xpath_select_overview_1}         //*[@id="nav__top-level"]/li[1]/a/span
${string_content}                  witherspoon
${string_server_info}              Server information
${string_high_priority_events}     High priority events
${string_BMC_info}                 BMC information
${string_power_info}               Power information
${xpath_high_priority_events}      //a[@href='#/server-health/event-log']
${string_event_log}                Event log
${xpath_launch_serial_over_lan}    //a[@class='no-icon quick-links__item']
${string_launch_serial_over_lan}   Serial over LAN console

*** Test Case ***
# OpenBMC @ Power Off state test cases.

Verify Title Text Content At OBMC Power Off State
    [Documentation]  Verify display of title text from "Server Overview"
    ...  module of OpenBMC GUI.
    [Tags]  Verify_Title_Text_Content_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_state

    Select Server Overview Menu
    Verify Display Content  ${string_content}

Verify Display Text Server Information At OBMC Power Off State
    [Documentation]  Verify existence of text "Server information".
    [Tags]  Verify_Display_Text_Server_Information_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_state

    Select Server Overview Menu
    Verify Display Content  ${string_server_info}

Verify BMC Information Should Display At OBMC Power Off State
    [Documentation]  Verify existence of text "BMC information".
    [Tags]  Verify_BMC_Information_Should_Display_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_State

    Select Server Overview Menu
    Verify Display Content  ${string_BMC_info}

Verify POWER Information Should Display At OBMC Power Off State
    [Documentation]  Verify existence of text "Power information".
    [Tags]  Verify_Power_Information_Should_Display_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_State

    Select Server Overview Menu
    Verify Display Content  ${string_power_info}

Verify High Priority Events Should Display At OBMC Power Off State
    [Documentation]  Verify the text display.
    [Tags]  Verify_High_Priority_Events_Should_Display_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_State

    Select Server Overview Menu
    Verify Display Content  ${string_high_priority_events}

Verify High Priority Events Can Be Operated At OBMC Power Off State
    [Documentation]  Will open the "High Priority Events".
    ...  menu to view and operate.
    [Tags]  Verify_High_Priority_Events_Can_Be_Operated_At_OBMC_Power_Off_State
    ...   OBMC_PowerOff_state

    Select Server Overview Menu
    Click Link  ${xpath_high_priority_events}
    Verify Display Content  ${string_event_log}

Verify Launching Of Serial Over LAN Console At OBMC Power Off State
    [Documentation]  Will open the serial over the lan command prompt window.
    [Tags]  Verify_Launching_Of_Serial_Over_LAN_Console_At_OBMC_Power_Off_State
    ...  OBMC_PowerOff_State

    Select Server Overview Menu
    Click Element  ${xpath_launch_serial_over_lan}
    Verify Display Content  ${string_launch_serial_over_lan}


# OpenBMC @ Power Running state test cases.

Verify Information Under BMC Information
    [Documentation]  Verify existence of information below the BMC area
    [Tags]  Verify_Information_Under_BMC_Information

    Select Server Overview Menu
    ${version}=  Get BMC Version
    ${version}=  Remove String  ${version}  "
    Verify Display Content  ${version}
    ${iplist}=  Get BMC IP Info
    :FOR  ${ip}  IN  @{iplist}
    \  ${ip}=  Fetch From Left  ${ip}  /
    \  Verify Display Content  ${ip}
    ${mac}=  Get BMC MAC Address
    Verify Display Content  ${mac}    

Verify High Priority Events Can Be Operated At OBMC Power Running State
    [Documentation]  Will open the "High Priority Events"
    ...  menu to view and operate.
    [Tags]  Verify_High_Priority_Events_Can_Be_Operated_At_OBMC_Power_Running_State
    ...  OBMC_PowerRunning_state
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Overview Menu
    Click Link  ${xpath_high_priority_events}
    Verify Display Content  ${string_event_log}

Verify Launching Of Serial Over LAN Console At OBMC Power Running State
    [Documentation]  Will open the serial over the lan command prompt window.
    [Tags]  Verify_Launching_Of_Serial_Over_LAN_Console_At_OBMC_Power_Running_State
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Overview Menu
    Click Element  ${xpath_launch_serial_over_lan}
    Verify Display Content  ${string_launch_serial_over_lan}

*** Keywords ***
Select Server Overview Menu
    [Documentation]  Selecting of OpenBMC "Server overview" menu.

    Click Button  ${xpath_select_overview_1}

Verify Display Content
    [Documentation]  Verify text content display.
    [Arguments]  ${display_text}
    # Description of argument(s):
    # display_text   The display text on web page.

    Page Should Contain  ${display_text}
