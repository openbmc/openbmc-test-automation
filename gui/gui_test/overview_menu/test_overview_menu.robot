*** Settings ***
Documentation       Test OpenBMC GUI "Overview" menu.

Resource            ../../lib/gui_resource.robot
Resource            ../../../lib/logging_utils.robot
Resource            ../../../lib/list_utils.robot
Resource            ../../../lib/bmc_network_utils.robot
Library             String

Suite Setup         Run Keywords    Launch Browser And Login GUI    AND    Redfish.Login
Suite Teardown      Run Keywords    Close Browser    AND    Redfish.Logout
Test Setup          Test Setup Execution

Test Tags           overview_menu


*** Variables ***
${xpath_overview_page_header}                       //h1[contains(text(), "Overview")]
${xpath_server_information_view_more_button}        (//*[text()="View more"])[1]
${xpath_firmware_information_view_more_button}      (//*[text()="View more"])[2]
${xpath_network_information_view_more_button}       (//*[text()="View more"])[3]
${xpath_power_information_view_more_button}         (//*[text()="View more"])[4]
${xpath_event_logs_view_more_button}                (//*[text()="View more"])[5]
${xpath_inventory_and_leds_view_more_button}        (//*[text()="View more"])[6]
${xpath_launch_host_console}                        //*[@data-test-id='overviewQuickLinks-button-solConsole']
${xpath_led_button}                                 //*[@data-test-id='overviewInventory-checkbox-identifyLed']
${xpath_dumps_view_more_button}                     (//*[text()="View more"])[7]
${xpath_critical_logs_count}                        //dt[contains(text(),'Critical')]/following-sibling::dd[1]
${xpath_warning_logs_count}                         //dt[contains(text(),'Warning')]/following-sibling::dd[1]
${xpath_asset_tag}                                  //dt[contains(text(),'Asset tag')]/following-sibling::dd[1]
${xpath_operating_mode}                             //dt[contains(text(),'Operating mode')]/following-sibling::dd[1]
${xpath_machine_model}                              //dt[contains(text(),'Model')]/following-sibling::dd[1]
${xpath_serial_number}                              //dt[contains(text(),'Serial number')]/following-sibling::dd[1]


*** Test Cases ***
Verify Existence Of All Sections In Overview Page
    [Documentation]    Verify existence of all sections in Overview page.
    [Tags]    verify_existence_of_all_sections_in_overview_page

    Page Should Contain    BMC date and time
    Page Should Contain    Firmware information
    Page Should Contain    Server information
    Wait Until Page Contains    Network information    timeout=10
    Page Should Contain    Power information
    Page Should Contain    Event logs
    Page Should Contain    Inventory and LEDs
    Page Should Contain    Dumps

Verify Network Information In Overview Page
    [Documentation]    Verify values under network information section.
    [Tags]    verify_network_information_in_overview_page

    ${hostname}=    Get BMC Hostname
    Page Should Contain    ${hostname}

    # Get all IP addresses and prefix lengths on system.

    ${resp}=    Redfish.Get Attribute
    ...    /redfish/v1/Managers/${MANAGER_ID}/EthernetInterfaces/eth0
    ...    IPv4StaticAddresses
    ${ip_addr}=    Set Variable    ${resp[0]['Address']}
    Page Should Contain    ${ip_addr}

Verify Server Information Section
    [Documentation]    Verify values under server information section in overview page.
    [Tags]    verify_server_information_section

    # Model.
    ${redfish_machine_model}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    Model
    Element Should Contain    ${xpath_machine_model}    ${redfish_machine_model}

    # Serial Number.
    ${redfish_serial_number}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    SerialNumber
    Element Should Contain    ${xpath_serial_number}    ${redfish_serial_number}

    # Asset Tag.
    ${redfish_asset_tag}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    AssetTag
    Element Should Contain    ${xpath_asset_tag}    ${redfish_asset_tag}

    # Operating mode.
    ${redfish_operating_mode}=    Redfish.Get Attribute    ${BIOS_ATTR_URI}    Attributes
    Element Should Contain    ${xpath_operating_mode}    ${redfish_operating_mode['pvm_system_operating_mode']}

Verify BMC Information Section
    [Documentation]    Verify BMC information section in overview page.
    [Tags]    verify_bmc_information_section

    ${firmware_version}=    Redfish Get BMC Version
    Page Should Contain    ${firmware_version}

Verify Edit Network Setting Button
    [Documentation]    Verify navigation to network setting page after clicking the button in overview page.
    [Tags]    verify_edit_network_setting_button

    Click Element    ${xpath_network_information_view_more_button}
    Wait Until Page Contains Element    ${xpath_network_heading}

Verify Event Under Critical Event Logs Section
    [Documentation]    Verify event under critical event logs section in case of any event.
    [Tags]    verify_event_under_critical_event_logs_section

    Redfish Purge Event Log
    Click Element    ${xpath_refresh_button}
    Generate Test Error Log
    Click Element    ${xpath_refresh_button}
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30
    ${log_count}=    Get Text    ${xpath_critical_logs_count}
    Should Be True    '${log_count}' == '${1}'
    [Teardown]    Redfish Purge Event Log

Verify Event Under Warning Event Logs Section
    [Documentation]    Verify event under warning event logs section in case of any event.
    [Tags]    verify_event_under_warning_event_logs_section

    Redfish Purge Event Log
    Click Element    ${xpath_refresh_button}

    # Generate a predictable error for testing purpose.
    BMC Execute Command    ${CMD_PREDICTIVE_ERROR}

    Click Element    ${xpath_refresh_button}
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30

    ${log_count}=    Get Text    ${xpath_warning_logs_count}
    Should Be Equal As Integers    ${log_count}    1
    [Teardown]    Redfish Purge Event Log

Verify View More Event Logs Button
    [Documentation]    Verify view more event log button in overview page.
    [Tags]    verify_view_more_event_logs_button

    Generate Test Error Log
    Page Should Contain Element    ${xpath_event_logs_view_more_button}    timeout=30
    Click Element    ${xpath_event_logs_view_more_button}
    Wait Until Page Contains Element    ${xpath_event_logs_heading}    timeout=30

Verify Host Console Button In Overview Page
    [Documentation]    Click host console button and verify page navigation to host console page.
    [Tags]    verify_host_console_button_in_overview_page

    Click Element    ${xpath_launch_host_console}
    Wait Until Page Contains Element    ${xpath_host_console_heading}

Verify Server LED Turn On
    [Documentation]    Turn on server LED via GUI and verify its status via Redfish.
    [Tags]    verify_server_led_turn_on

    # Turn Off the server LED via Redfish and refresh GUI.
    Set IndicatorLED State    Off
    Refresh GUI

    # Turn ON the LED via GUI.
    Click Element    ${xpath_led_button}

    # Cross check that server LED ON state via Redfish.
    Verify Identify LED State Via Redfish    Lit

Verify Server LED Turn Off
    [Documentation]    Turn off server LED via GUI and verify its status via Redfish.
    [Tags]    verify_server_led_turn_off

    # Turn On the server LED via Redfish and refresh GUI.
    Set IndicatorLED State    Lit
    Refresh GUI

    # Turn OFF the LED via GUI.
    Click Element At Coordinates    ${xpath_led_button}    0    0

    # Cross check that server LED off state via Redfish.
    Verify Identify LED State Via Redfish    Off

Verify BMC Time In Overview Page
    [Documentation]    Verify that BMC date from GUI matches with BMC time via Redfish.
    [Tags]    verify_bmc_time_in_overview_page

    ${date_time}=    Redfish.Get Attribute    ${REDFISH_BASE_URI}Managers/${MANAGER_ID}    DateTime
    ${converted_date}=    Convert Date    ${date_time}    result_format=%Y-%m-%d

    Page Should Contain    ${converted_date}

Verify BMC Information At Host Power Off State
    [Documentation]    Verify that BMC information is displayed at host power off state.
    [Tags]    verify_bmc_information_at_host_power_off_state

    Redfish Power Off    stack_mode=skip
    ${firmware_version}=    Redfish Get BMC Version
    Page Should Contain    ${firmware_version}

Verify View More Button For Dumps
    [Documentation]    Verify view more button for dumps button in overview page.
    [Tags]    verify_view_more_button_for_dumps

    Wait Until Page Contains Element    ${xpath_dumps_view_more_button}    timeout=30
    Click Element    ${xpath_dumps_view_more_button}
    Wait Until Page Contains Element    ${xpath_dumps_header}    timeout=30

Verify View More Button Under Server Information Section
    [Documentation]    Verify view more button under server information section in overview page.
    [Tags]    verify_view_more_button_under_server_information_section

    Wait Until Page Contains Element    ${xpath_server_information_view_more_button}    timeout=30
    Click Element    ${xpath_server_information_view_more_button}
    Wait Until Page Contains Element    ${xpath_inventory_and_leds_heading}    timeout=30

Verify View More Button Under Firmware Information Section
    [Documentation]    Verify view more button under firmware information section in overview page.
    [Tags]    verify_view_more_button_under_firmware_information_section

    Wait Until Page Contains Element    ${xpath_firmware_information_view_more_button}    timeout=30
    Click Element    ${xpath_firmware_information_view_more_button}
    Wait Until Page Contains Element    ${xpath_firmware_heading}    timeout=30

Verify View More Button Under Network Information Section
    [Documentation]    Verify view more button under network information section in overview page.
    [Tags]    verify_view_more_button_under_network_information_section

    Wait Until Page Contains Element    ${xpath_network_information_view_more_button}    timeout=30
    Click Element    ${xpath_network_information_view_more_button}
    Wait Until Page Contains Element    ${xpath_network_heading}    timeout=30

Verify View More Button Under Power Information Section
    [Documentation]    Verify view more button under power information section in overview page.
    [Tags]    verify_view_more_button_under_power_information_section

    Wait Until Page Contains Element    ${xpath_power_information_view_more_button}    timeout=30
    Click Element    ${xpath_power_information_view_more_button}
    Wait Until Page Contains Element    ${xpath_power_heading}    timeout=30

Verify View More Button Under Event Logs Section
    [Documentation]    Verify view more button under event logs section in overview page.
    [Tags]    verify_view_more_button_under_event_logs_section

    Wait Until Page Contains Element    ${xpath_event_logs_view_more_button}    timeout=30
    Click Element    ${xpath_event_logs_view_more_button}
    Wait Until Page Contains Element    ${xpath_event_logs_heading}    timeout=30

Verify View More Button Under Inventory And LEDs Section
    [Documentation]    Verify view more button under inventory and leds section in overview page.
    [Tags]    verify_view_more_button_under_inventory_and_leds_section

    Wait Until Page Contains Element    ${xpath_inventory_and_leds_view_more_button}    timeout=30
    Click Element    ${xpath_inventory_and_leds_view_more_button}
    Wait Until Page Contains Element    ${xpath_inventory_and_leds_heading}    timeout=30

Verify Text Under Server Information Section
    [Documentation]    Verify text under server information section in overview page.
    [Tags]    verify_text_under_server_information_section

    Page Should Contain    Model
    Page Should Contain    Operating mode
    Page Should Contain    Serial number
    Page Should Contain    Service login
    Page Should Contain    Asset tag

Verify Text Under Firmware Information Section
    [Documentation]    Verify text under firmware information section in overview page.
    [Tags]    verify_text_under_firmware_information_section

    Page Should Contain    Running
    Page Should Contain    Backup
    Page Should Contain    Access key expiration

Verify Text Under Network Information Section
    [Documentation]    Verify text under network information section in overview page.
    [Tags]    verify_text_under_network_information_section

    Page Should Contain    Hostname
    Page Should Contain    IPv4
    Page Should Contain    DHCPv4

Verify Text Under Power Information Section
    [Documentation]    Verify text under power information section in overview page.
    [Tags]    verify_text_under_power_information_section

    Page Should Contain    Power consumption
    Page Should Contain    Idle power saver
    Page Should Contain    Power cap
    Page Should Contain    Power mode

Verify Text Under Event Logs Section
    [Documentation]    Verify text under event logs section in overview page.
    [Tags]    verify_text_under_event_logs_section

    Page Should Contain    Critical
    Page Should Contain    Warning

Verify Text Under Inventory And LEDs Section
    [Documentation]    Verify text under inventory and leds section in overview page.
    [Tags]    verify_text_under_inventory_and_leds_section

    Page Should Contain    System identify LED

Verify Text Under Dumps Section
    [Documentation]    Verify text under Dumps section in overview page.
    [Tags]    verify_text_under_dumps_section

    Page Should Contain    Total


*** Keywords ***
Test Setup Execution
    [Documentation]    Do test case setup tasks.

    Click Element    ${xpath_overview_menu}
    Wait Until Page Contains Element    ${xpath_overview_page_header}
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30

Verify Identify LED State Via Redfish
    [Documentation]    Verify that Redfish identify LED system with given state.
    [Arguments]    ${expected_state}
    # Description of argument(s):
    # expected_state    Expected value of Identify LED.

    ${led_state}=    Redfish.Get Attribute    /redfish/v1/Systems/${SYSTEM_ID}    IndicatorLED
    Should Be True    '${led_state}' == '${expected_state}'

Set IndicatorLED State
    [Documentation]    Perform redfish PATCH operation.
    [Arguments]    ${led_state}    ${expect_resp_code}=[200, 204]
    # Description of argument(s):
    # led_state    IndicatorLED state to "off", "Lit" etc.
    # expect_resp_code    Expected HTTPS response code. Default [200, 204]

    Redfish.Patch    /redfish/v1/Systems/${SYSTEM_ID}    body={"IndicatorLED": "${led_state}"}
    ...    valid_status_codes=${expect_resp_code}
