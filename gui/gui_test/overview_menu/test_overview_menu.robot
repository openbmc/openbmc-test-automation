*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot
Resource        ../../../lib/list_utils.robot
Resource        ../../../lib/bmc_network_utils.robot

Library         String

Suite Setup     Run Keywords  Launch Browser And Login GUI  AND  Redfish.Login
Suite Teardown  Run Keywords  Close Browser  AND  Redfish.Logout
Test Setup      Test Setup Execution

Test Tags      Overview_Menu

*** Variables ***

${xpath_overview_page_header}                    //h1[contains(text(), "Overview")]
${xpath_server_information_view_more_button}     (//*[text()="View more"])[1]
${xpath_firmware_information_view_more_button}   (//*[text()="View more"])[2]
${xpath_network_information_view_more_button}    (//*[text()="View more"])[3]
${xpath_power_information_view_more_button}      (//*[text()="View more"])[4]
${xpath_event_logs_view_more_button}             (//*[text()="View more"])[5]
${xpath_inventory_and_leds_view_more_button}     (//*[text()="View more"])[6]
${xpath_launch_host_console}                     //*[@data-test-id='overviewQuickLinks-button-hostConsole']
${xpath_led_button}                              //*[@for="identifyLedSwitch"]
${xpath_dumps_view_more_button}                  (//*[text()="View more"])[7]
${xpath_critical_logs_count}                     //dt[contains(normalize-space(.),'Critical')]/following-sibling::dd[1]
${xpath_warning_logs_count}                      //dt[contains(normalize-space(.),'Warning')]/following-sibling::dd[1]
${xpath_asset_tag}                               //dt[contains(text(),'Asset tag')]/following-sibling::dd[1]
${xpath_operating_mode}                          //dt[contains(text(),'Operating mode')]/following-sibling::dd[1]
${xpath_machine_model}                           //dt[contains(text(),'Model')]/following-sibling::dd[1]
${xpath_serial_number}                           //dt[contains(text(),'Serial number')]/following-sibling::dd[1]
${xpath_hostname}                                //dt[contains(text(),'Hostname')]/following-sibling::dd[1]
${xpath_overview_data_time}                      //dd[contains(@data-test-id,'overviewQuickLinks-text-bmcTime')]
${xpath_overview_power_consumption}              //dt[contains(text(),'Power consumption')]/following-sibling::dd[1]
${xpath_overview_idle_power_saver}               //dt[contains(text(),'Idle power saver')]/following-sibling::dd[1]
${xpath_overview_power_cap}                      //dt[contains(text(),'Power cap')]/following-sibling::dd[1]
${xpath_overview_power_mode}                     //dt[contains(text(),'Power mode')]/following-sibling::dd[1]
${ENV_METRICS_URI}                               ${REDFISH_CHASSIS_URI}/${CHASSIS_ID}/EnvironmentMetrics
${xpath_dumps_count}                             //dt[contains(text(),'Total')]/following-sibling::dd[1]
${xpath_asset_tag_edit_button}                   //button//*[local-name()='svg' and @title='Edit asset tag']
${xpath_asset_tag_input}                         //input[@id="asset-tag"]
${xpath_asset_tag_save_button}                   //button[normalize-space()="Save"]
${xpath_asset_tag_cancel_button}                 //button[normalize-space()="Cancel"]


*** Test Cases ***

Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC date and time
    Page Should Contain  Firmware information
    Page Should Contain  Server information
    Wait Until Page Contains  Network information  timeout=10
    Page Should Contain  Power information
    Page Should Contain  Event logs
    Page Should Contain  Inventory and LEDs
    Page Should Contain  Dumps


Verify Network Information In Overview Page
    [Documentation]  Verify values under network information section.
    [Tags]  Verify_Network_Information_In_Overview_Page

    ${hostname}=  Get BMC Hostname
    Page Should Contain  ${hostname}

    # Get all IP addresses and prefix lengths on system.

    ${resp}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/eth0  IPv4StaticAddresses
    ${ip_addr}=  Set Variable  ${resp[0]['Address']}
    Page Should Contain  ${ip_addr}


Verify Server Information Section
    [Documentation]  Verify values under server information section in overview page.
    [Tags]  Verify_Server_Information_Section

    # Model.
    ${redfish_machine_model}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  Model
    Element Should Contain  ${xpath_machine_model}  ${redfish_machine_model}

    # Serial Number.
    ${redfish_serial_number}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  SerialNumber
    Element Should Contain  ${xpath_serial_number}  ${redfish_serial_number}

    # Asset Tag.
    ${redfish_asset_tag}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  AssetTag
    Element Should Contain  ${xpath_asset_tag}  ${redfish_asset_tag}

    # Operating mode.
    ${redfish_operating_mode}=  Redfish.Get Attribute  ${BIOS_ATTR_URI}  Attributes
    Element Should Contain  ${xpath_operating_mode}  ${redfish_operating_mode['pvm_system_operating_mode']}


Verify BMC Information Section
    [Documentation]  Verify BMC information section in overview page.
    [Tags]  Verify_BMC_Information_Section

    ${firmware_version}=  Redfish Get BMC Version
    Page Should Contain  ${firmware_version}


Verify Edit Network Setting Button
    [Documentation]  Verify navigation to network setting page after clicking the button in overview page.
    [Tags]  Verify_Edit_Network_Setting_Button

    Click Element  ${xpath_network_information_view_more_button}
    Wait Until Page Contains Element  ${xpath_network_heading}


Verify Event Under Critical Event Logs Section
    [Documentation]  Verify event under critical event logs section in case of any event.
    [Tags]  Verify_Event_Under_Critical_Event_Logs_Section
    [Setup]  Redfish Purge Event Log
    [Teardown]  Redfish Purge Event Log

    Redfish Purge Event Log
    Click Element  ${xpath_refresh_button}
    Generate Test Error Log
    Click Element  ${xpath_refresh_button}
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    ${log_count}=  Get Text  ${xpath_critical_logs_count}
    Should Be True  '${log_count}' == '${1}'


Verify Event Under Warning Event Logs Section
    [Documentation]  Verify event under warning event logs section in case of any event.
    [Tags]  Verify_Event_Under_Warning_Event_Logs_Section
    [Teardown]  Redfish Purge Event Log

    Redfish Purge Event Log
    Click Element  ${xpath_refresh_button}

    # Generate a predictable error for testing purpose.
    BMC Execute Command  ${CMD_PREDICTIVE_ERROR}

    Click Element  ${xpath_refresh_button}
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30

    ${log_count}=  Get Text  ${xpath_warning_logs_count}
    Should Be Equal As Integers  ${log_count}  1


Verify View More Event Logs Button
    [Documentation]  Verify view more event log button in overview page.
    [Tags]  Verify_View_More_Event_Logs_Button

    Generate Test Error Log
    Page Should Contain Element  ${xpath_event_logs_view_more_button}  timeout=30
    Click Element  ${xpath_event_logs_view_more_button}
    Wait Until Page Contains Element  ${xpath_event_logs_heading}  timeout=30


Verify Host Console Button In Overview Page
    [Documentation]  Click host console button and verify page navigation to host console page.
    [Tags]  Verify_Host_Console_Button_In_Overview_Page

    Click Element  ${xpath_launch_host_console}
    Wait Until Page Contains Element  ${xpath_host_console_heading}


Verify Server LED Turn On
    [Documentation]  Turn on server LED via GUI and verify its status via Redfish.
    [Tags]  Verify_Server_LED_Turn_On

    # Turn Off the server LED via Redfish and refresh GUI.
    # Set IndicatorLED State  Off
    Set IndicatorLED State  True
    Refresh GUI

    # Turn ON the LED via GUI.
    Click Element  ${xpath_led_button}

    # Cross check that server LED ON state via Redfish.
    Verify Identify LED State Via Redfish  True


Verify Server LED Turn Off
    [Documentation]  Turn off server LED via GUI and verify its status via Redfish.
    [Tags]  Verify_Server_LED_Turn_Off

    # Turn On the server LED via Redfish and refresh GUI.
    Set IndicatorLED State  true
    Refresh GUI

    # Turn OFF the LED via GUI.
    Click Element  ${xpath_led_button}

    # Cross check that server LED off state via Redfish.
    Verify Identify LED State Via Redfish  False


Verify BMC Time In Overview Page
    [Documentation]  Verify that BMC date from GUI matches with BMC time via Redfish.
    [Tags]  Verify_BMC_Time_In_Overview_Page

    ${date_time}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}  DateTime
    ${converted_date}=  Convert Date  ${date_time}  result_format=%Y-%m-%d

    Page Should Contain  ${converted_date}


Verifying RTC Synchronization On BMC Time And Overview Page
    [Documentation]  Verify RTC synchronization on BMC time and overview page.
    [Tags]    Verifying_RTC_Synchronization_On_BMC_Time_And_Overview_Page

    # Get the time from overview page.
    Wait Until Page Contains Element  ${xpath_overview_data_time}
    ${bmc_datetime_web}=  Get Text  ${xpath_overview_data_time}

    # Get the RTC date from BMC console,
    # And compare with overview page date.
    ${rtc_date_time}=  Get RTC Date And Time From BMC Console

    ${bmc_converted_date}=  Convert Date  ${bmc_datetime_web}  result_format=%Y-%m-%d
    ${rtc_converted_date}=  Convert Date  ${rtc_date_time}  result_format=%Y-%m-%d
    Should Be Equal  ${bmc_converted_date}  ${rtc_converted_date}

    # Get the redfish date time and compare with RTC date.
    ${redfish_date_time}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}  DateTime
    ${redfish_converted_date}=  Convert Date  ${redfish_date_time}  result_format=%Y-%m-%d
    Should Be Equal  ${redfish_converted_date}  ${rtc_converted_date}


Verify View More Button For Dumps
    [Documentation]  Verify view more button for dumps button in overview page.
    [Tags]  Verify_View_More_Button_For_Dumps

    Wait Until Page Contains Element  ${xpath_dumps_view_more_button}  timeout=30
    Click Element  ${xpath_dumps_view_more_button}
    Wait Until Page Contains Element  ${xpath_dumps_header}  timeout=30


Verify View More Button Under Server Information Section
    [Documentation]  Verify view more button under server information section in overview page.
    [Tags]  Verify_View_More_Button_Under_Server_Information_Section

    Wait Until Page Contains Element  ${xpath_server_information_view_more_button}  timeout=30
    Click Element   ${xpath_server_information_view_more_button}
    Wait Until Page Contains Element  ${xpath_inventory_and_leds_heading}  timeout=30


Verify View More Button Under Firmware Information Section
    [Documentation]  Verify view more button under firmware information section in overview page.
    [Tags]  Verify_View_More_Button_Under_Firmware_Information_Section

    Wait Until Page Contains Element  ${xpath_firmware_information_view_more_button}  timeout=30
    Click Element  ${xpath_firmware_information_view_more_button}
    Wait Until Page Contains Element  ${xpath_firmware_heading}  timeout=30


Verify View More Button Under Network Information Section
    [Documentation]  Verify view more button under network information section in overview page.
    [Tags]  Verify_View_More_Button_Under_Network_Information_Section

    Wait Until Page Contains Element  ${xpath_network_information_view_more_button}  timeout=30
    Click Element  ${xpath_network_information_view_more_button}
    Wait Until Page Contains Element  ${xpath_network_heading}  timeout=30


Verify View More Button Under Power Information Section
    [Documentation]  Verify view more button under power information section in overview page.
    [Tags]  Verify_View_More_Button_Under_Power_Information_Section

    Wait Until Page Contains Element  ${xpath_power_information_view_more_button}  timeout=30
    Click Element  ${xpath_power_information_view_more_button}
    Wait Until Page Contains Element  ${xpath_power_heading}  timeout=30


Verify View More Button Under Event Logs Section
    [Documentation]  Verify view more button under event logs section in overview page.
    [Tags]  Verify_View_More_Button_Under_Event_Logs_Section

    Wait Until Page Contains Element  ${xpath_event_logs_view_more_button}  timeout=30
    Click Element  ${xpath_event_logs_view_more_button}
    Wait Until Page Contains Element  ${xpath_event_logs_heading}  timeout=30


Verify View More Button Under Inventory And LEDs Section
    [Documentation]  Verify view more button under inventory and leds section in overview page.
    [Tags]  Verify_View_More_Button_Under_Inventory_And_LEDs_Section

    Wait Until Page Contains Element  ${xpath_inventory_and_leds_view_more_button}  timeout=30
    Click Element  ${xpath_inventory_and_leds_view_more_button}
    Wait Until Page Contains Element  ${xpath_inventory_and_leds_heading}  timeout=30


Verify Text Under Server Information Section
    [Documentation]  Verify text under server information section in overview page.
    [Tags]  Verify_Text_Under_Server_Information_Section

    Page Should Contain  Model
    Page Should Contain  Operating mode
    Page Should Contain  Serial number
    Page Should Contain  Service login
    Page Should Contain  Asset tag


Verify Text Under Firmware Information Section
    [Documentation]  Verify text under firmware information section in overview page.
    [Tags]  Verify_Text_Under_Firmware_Information_Section

    Page Should Contain  Running
    Page Should Contain  Backup
    Page Should Contain  Access key expiration


Verify Text Under Network Information Section
    [Documentation]  Verify text under network information section in overview page.
    [Tags]  Verify_Text_Under_Network_Information_Section

    Page Should Contain  Hostname
    Page Should Contain  IPv4
    Page Should Contain  DHCPv4


Verify Text Under Power Information Section
    [Documentation]  Verify text under power information section in overview page.
    [Tags]  Verify_Text_Under_Power_Information_Section

    Page Should Contain  Power consumption
    Page Should Contain  Idle power saver
    Page Should Contain  Power cap
    Page Should Contain  Power mode


Verify Text Under Event Logs Section
    [Documentation]  Verify text under event logs section in overview page.
    [Tags]  Verify_Text_Under_Event_Logs_Section

    Page Should Contain  Critical
    Page Should Contain  Warning


Verify Text Under Inventory And LEDs Section
    [Documentation]  Verify text under inventory and leds section in overview page.
    [Tags]  Verify_Text_Under_Inventory_And_LEDs_Section

    Page Should Contain  System identify LED


Verify Text Under Dumps Section
    [Documentation]  Verify text under Dumps section in overview page.
    [Tags]  Verify_Text_Under_Dumps_Section
    [Teardown]  Logout GUI

    Page Should Contain  Total


Verify Server LED Turn Off And On With Readonly User
    [Documentation]  Turn off and on server LED via GUI with Readonly user.
    [Tags]  Verify_Server_LED_Turn_Off_And_On_With_Readonly_User
    [Setup]  Create Readonly User And Login To GUI
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    # Turn On the server LED via Redfish and refresh GUI.
    Set IndicatorLED State  Lit
    Refresh GUI

    # Turn OFF the LED via GUI.
    Click Element  ${xpath_led_button}
    Verify Error And Unauthorized Message On GUI

    # Turn ON the LED via GUI.
    Set IndicatorLED State   false
    Refresh GUI
    Click Element  ${xpath_led_button}
    Verify Error And Unauthorized Message On GUI


Verify Dumps Total Count Under Dumps Section
    [Documentation]  Verify total dumps count matches Redfish vs GUI.
    [Tags]  Verify_Dumps_Total_Count_Under_Dumps_Section

    ${redfish_dump_count}=  Redfish.Get Attribute  ${REDFISH_DUMP_URI}  Members@odata.count
    ${gui_dump_count}=  Get Text  ${xpath_dumps_count}

    Should Be Equal As Integers  ${gui_dump_count}  ${redfish_dump_count}


Verify Asset Tag Save Button On Overview Page
    [Documentation]  Verify that asset tag is successfully updated using save action.
    [Tags]  Verify_Asset_Tag_Save_Button_on_Overview_Page

    Verify Asset Tag Update On Overview Page    save


Verify Asset Tag Cancel Button On Overview Page
    [Documentation]  Verify that asset tag update is discarded using cancel action.
    [Tags]  Verify_Asset_Tag_Cancel_Button_On_Overview_Page

    Verify Asset Tag Update On Overview Page    cancel


###  Power Off Test Cases  ###

Verify BMC Information At Host Power Off State
    [Documentation]  Verify that BMC information is displayed at host power off state.
    [Tags]  Verify_BMC_Information_At_Host_Power_Off_State
    [Setup]  Run Keywords  Power Off Server  AND  Test Setup Execution

    ${firmware_version}=  Redfish Get BMC Version
    Page Should Contain  ${firmware_version}


Verify Overview Hostname Matches Redfish Hostname
    [Documentation]    Verify GUI Overview hostname matches Redfish hostname.
    [Tags]  Verify_Overview_Hostname_Matches_Redfish_Hostname

    # Get GUI Overview hostname and Redfish hostname.
    ${overview_hostname}=  Get Text  ${xpath_hostname}
    ${redfish_hostname}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  HostName

    # Verify GUI Overview hostname matches Redfish hostname.
    Should Be Equal  ${overview_hostname}  ${redfish_hostname}


Verify Power Information Should Display At Host Power Off State
    [Documentation]  Verify Power Information is displayed at host power off state.
    [Tags]  Verify_Power_Information_Should_Display_At_Host_Power_Off_State
    [Setup]  Run Keywords  Power Off Server  AND  Test Setup Execution

    Verify Power Information Section  PowerOff


###  Readonly User  ###

Verify Asset Tag Update With Readonly User
    [Documentation]  Verify that readonly user fails to update asset tag
    ...  and verify the error and unauthorized messages.
    [Tags]  Verify_Asset_Tag_Update_With_Readonly_User
    [Setup]  Create Readonly User And Login To GUI
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Asset Tag Update On Overview Page  save  readonly


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


Verify Identify LED State Via Redfish
    [Documentation]  Verify that Redfish identify LED system with given state.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state    Expected value of Identify LED.

    ${led_state}=  Redfish.Get Attribute  /redfish/v1/Systems/${SYSTEM_ID}  LocationIndicatorActive
    Should Be True  '${led_state}' == '${expected_state}'


Set IndicatorLED State
    [Documentation]  Perform redfish PATCH operation.
    [Arguments]  ${led_state}  ${expect_resp_code}=[200, 204]

    # Description of argument(s):
    # led_state            IndicatorLED state to "off", "Lit" etc.
    # expect_resp_code     Expected HTTPS response code. Default [200, 204]


    Redfish.Patch  /redfish/v1/Systems/${SYSTEM_ID}  body={"LocationIndicatorActive": ${led_state}}
    ...  valid_status_codes=${expect_resp_code}


Get RTC Date And Time From BMC Console
    [Documentation]    Returns the RTC date and time from timedatectl BMC console output.
    # Example return value: "Fri 2016-05-20 16:34:03 UTC".

    # Get the RTC date and time from BMC console and return it.
    ${bmc_time}=  Get BMC Date Time
    ${rtc_time}=  Strip String  ${bmc_time['rtc_time']}

    RETURN  ${rtc_time}


Verify Power Information Section
    [Documentation]  Verify values under power information section in overview page.
    [Arguments]  ${power_status}

    # Description of argument(s):
    # power_status     Server power state (PowerOn/PowerOff).

    # Verify power consumption value.
    ${power_value}=  Get Text  ${xpath_overview_power_consumption}
    IF  '${power_status}' == 'PowerOn'
        Click Element  ${xpath_power_information_view_more_button}
        Wait Until Page Contains Element  ${xpath_power_heading}  timeout=30
        ${power_tab_value}=  Get Text  ${xpath_power_tab_power_consumption}
        Should Be Equal As Strings  ${power_value}  ${power_tab_value}
    ELSE
        Should Be Equal As Strings  ${power_value}  Not available
    END

    # Verify power cap value.
    ${redfish_power_cap}=  Redfish.Get Attribute  ${ENV_METRICS_URI}  PowerLimitWatts
    Element Should Contain  ${xpath_overview_power_cap}  ${redfish_power_cap['SetPoint']}

    # Verify idle power saver.
    ${redfish_idle_power_saver}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  IdlePowerSaver
    ${idle_power_saver_enabled_status}=  Get From Dictionary  ${redfish_idle_power_saver}  Enabled
    IF  ${idle_power_saver_enabled_status}
        Element Should Contain  ${xpath_overview_idle_power_saver}  Enabled
    ELSE
        Element Should Contain  ${xpath_overview_idle_power_saver}  Disabled
    END

    # Verify power mode value.
    ${redfish_power_mode}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  PowerMode
    ${power_mode_type}=  IF  '${redfish_power_mode}' == 'MaximumPerformance'
    ...  Set Variable  Maximum performance
    ...  ELSE IF  '${redfish_power_mode}' == 'EfficiencyFavorPower'
    ...  Set Variable  Energy efficient
    ...  ELSE IF  '${redfish_power_mode}' == 'PowerSaving'
    ...  Set Variable  Maximum energy saver
    ...  ELSE  Set Variable  ${redfish_power_mode}
    Element Should Contain  ${xpath_overview_power_mode}  ${power_mode_type}

    # Verify View more link and navigation to Power page.
    Wait Until Page Contains Element  ${xpath_power_information_view_more_button}  timeout=30
    Click Element  ${xpath_power_information_view_more_button}
    Wait Until Page Contains Element  ${xpath_power_heading}  timeout=30


Verify Asset Tag Update On Overview Page
    [Documentation]  Verify asset tag update with options such as save, cancel
    ...              for user with readonly or admin privilege
    [Arguments]  ${action}  ${user_type}=normal

    # Description of argument(s):
    # action      Perform actions as Save,Cancel.
    # user_type   Readonly and admin users.

    # Click edit button.
    Wait And Click Element  ${xpath_asset_tag_edit_button}

    Wait Until Element Is Visible  ${xpath_asset_tag_input}  timeout=10
    ${overview_asset_tag}=  Get Text  ${xpath_asset_tag}
    ${new_asset_tag}=  Set Variable  ${overview_asset_tag}_new

    # Input asset tag with new value.
    Input Text  ${xpath_asset_tag_input}  ${new_asset_tag}

    # Perform Action and Validations.
    IF  '${action}' == 'save'
       Click Element  ${xpath_asset_tag_save_button}
       IF  '${user_type}' == 'readonly'
           Verify Error And Unauthorized Message On GUI
       ELSE
           Verify Success Message On BMC GUI Page
       END
    ELSE
      Click Element  ${xpath_asset_tag_cancel_button}
    END
    Page Should Not Contain  ${xpath_asset_tag_cancel_button}
    Element Should Contain  ${xpath_asset_tag}  ${overview_asset_tag}