*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot
Resource        ../../../lib/list_utils.robot
Resource        ../../../lib/bmc_network_utils.robot

Library         String

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}          //h1[contains(text(), "Overview")]
${xpath_edit_network_settings_button}  //*[@data-test-id='overviewQuickLinks-button-networkSettings']
${view_all_event_logs}                 //*[@data-test-id='overviewEvents-button-eventLogs']
${xpath_launch_serial_over_lan}        //*[@data-test-id='overviewQuickLinks-button-solConsole']
${xpath_led_button}                    //*[@data-test-id='overviewQuickLinks-checkbox-serverLed']


*** Test Cases ***

Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


Verify Network Information In Overview Page
    [Documentation]  Verify values under network information section.
    [Tags]  Verify_Network_Information_In_Overview_Page

    ${hostname}=  Get BMC Hostname
    Page Should Contain  ${hostname}

    # Get all IP addresses and prefix lengths on system.

    ${ip_addr_list}=  Get BMC IP Info
    FOR  ${ip_address}  IN  @{ip_addr_list}
      ${ip}=  Fetch From Left  ${ip_address}  \/
      Page Should Contain  ${ip}
    END

    ${macaddr}=  Get BMC MAC Address
    Page Should Contain  ${macaddr}


Verify Message In High Priority Events Section For No Events
    [Documentation]  Verify message under high priority events section in case of no events.
    [Tags]  Verify_Message_In_High_Priority_Events_Section_For_No_Events

    Redfish Purge Event Log
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  no high priority events to display  timeout=10


Verify Server Information Section
    [Documentation]  Verify values under server information section in overview page.
    [Tags]  Verify_Server_Information_Section

    ${redfish_machine_model}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  Model
    Page Should Contain  ${redfish_machine_model}

    ${redfish_serial_number}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  SerialNumber
    Page Should Contain  ${redfish_serial_number}

    ${redfish_motherboard_manufacturer}=  Redfish.Get Attribute
    ...  /redfish/v1/Systems/system/  Manufacturer

    Page Should Contain  ${redfish_motherboard_manufacturer}


Verify BMC Information Section
    [Documentation]  Verify BMC information section in overview page.
    [Tags]  Verify_BMC_Information_Section

    ${firmware_version}=  Redfish Get BMC Version
    Page Should Contain  ${firmware_version}


Verify Edit Network Setting Button
    [Documentation]  Verify navigation to network setting page after clicking the button in overview page.
    [Tags]  Verify_Edit_Network_Setting_Button

    Click Element  ${xpath_edit_network_settings_button}
    Wait Until Page Contains Element  ${xpath_network_page_header}


Verify Event Under High Priority Events Section
    [Documentation]  Verify event under high priority events section in case of any event.
    [Tags]  Verify_Event_Under_High_Priority_Events_Section

    Redfish Purge Event Log
    Click Element  ${xpath_refresh_button}
    Generate Test Error Log
    Click Element  ${xpath_refresh_button}
    Wait Until Page Contains  xyz.openbmc_project.Common.Error.InternalFailure  timeout=30s


Verify View All Event Logs Button
    [Documentation]  Verify view all event log button in overview page.
    [Tags]  Verify_View_All_Event_Logs_Button

    Generate Test Error Log
    Page Should Contain Element  ${view_all_event_logs}  timeout=30
    Click Element  ${view_all_event_logs}
    Wait Until Page Contains Element  ${xpath_event_header}  timeout=30


Verify Serial Over LAN Console Button In Overview Page
    [Documentation]  Click serial over LAN button and verify page navigation to serial over LAN page.
    [Tags]  Verify_Serial_Over_LAN_Console_Button_In_Overview_Page

    Click Element  ${xpath_launch_serial_over_lan}
    Wait Until Page Contains Element  ${xpath_sol_console_heading}


Verify Server LED Turn On
    [Documentation]  Turn on server LED via GUI and verify its status via Redfish.
    [Tags]  Verify_Server_LED_Turn_On

    # Turn Off the server LED via Redfish and refresh GUI.
    Redfish.Patch  /redfish/v1/Systems/system  body={"IndicatorLED":"Off"}   valid_status_codes=[200, 204]
    Refresh GUI

    # Turn ON the LED via GUI.
    Click Element At Coordinates  ${xpath_led_button}  0  0

    # Cross check that server LED ON state via Redfish.
    ${led_status}=  Redfish.Get Attribute  /redfish/v1/Systems/system  IndicatorLED
    Should Be True  '${led_status}' == 'Lit'


Verify Server LED Turn Off
    [Documentation]  Turn off server LED via GUI and verify its status via Redfish.
    [Tags]  Verify_Server_LED_Turn_Off

    # Turn On the server LED via Redfish and refresh GUI.
    Redfish.Patch  /redfish/v1/Systems/system  body={"IndicatorLED":"Lit"}   valid_status_codes=[200, 204]
    Refresh GUI

    # Turn OFF the LED via GUI.
    Click Element At Coordinates  ${xpath_led_button}  0  0

    # Cross check that server LED off state via Redfish.
    ${led_status}=  Redfish.Get Attribute  /redfish/v1/Systems/system  IndicatorLED
    Should Be True  '${led_status}' == 'Off'


Verify BMC Time In Overview Page
    [Documentation]  Verify that BMC date from GUI matches with BMC time via Redfish.
    [Tags]  Verify_BMC_Time_In_Overview_Page

    ${date_time}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/bmc  DateTime
    ${converted_date}=  Convert Date  ${date_time}  result_format=%Y-%m-%d

    Page Should Contain  ${converted_date}


Verify BMC Information At Host Power Off State
    [Documentation]  Verify that BMC information is displayed at host power off state.
    [Tags]  Verify_BMC_Information_At_Host_Power_Off_State

    Redfish Power Off  stack_mode=skip
    ${firmware_version}=  Redfish Get BMC Version
    Page Should Contain  ${firmware_version}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}
