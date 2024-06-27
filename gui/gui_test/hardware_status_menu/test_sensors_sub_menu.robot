*** Settings ***
Documentation       Test OpenBMC GUI "Sensors" sub-menu.

Resource            ../../lib/gui_resource.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Close Browser

Test Tags           sensors_sub_menu


*** Variables ***
${xpath_sensor_heading}         //h1[text()="Sensors"]
${xpath_sensors_filter}         //button[contains(text(),'Filter')]
${xpath_sensors_search}         //input[contains(@class,"search-input")]
${xpath_filter_ok}              //*[@data-test-id='tableFilter-checkbox-OK']
${xpath_filter_warning}         //*[@data-test-id='tableFilter-checkbox-Warning']
${xpath_filter_critical}        //*[@data-test-id='tableFilter-checkbox-Critical']
${xpath_filter_clear_all}       //*[@data-test-id='tableFilter-button-clearAll']
${xpath_selected_severity}      //*[@class="d-inline-block mb-0"]
${xpath_clear_search_input}     //*[@title="Clear search input"]


*** Test Cases ***
Verify Navigation To Sensors Page
    [Documentation]    Verify navigation to Sensors page.
    [Tags]    verify_navigation_to_sensors_page

    Page Should Contain Element    ${xpath_sensor_heading}

Verify Existence Of All Sections In Sensor Page
    [Documentation]    Verify existence of all sections in sensor page.
    [Tags]    verify_existence_of_all_sections_in_sensor_page

    Page Should Contain    Sensors

Verify Existence Of All Buttons And Input Boxes In Sensor Page
    [Documentation]    Verify existence of all buttons and input boxes in sensor page.
    [Tags]    verify_existence_of_all_buttons_and_input_boxes_in_sensor_page

    Page Should Contain Element    ${xpath_sensors_filter}
    Click Element    ${xpath_sensors_filter}

    # Search field
    Page Should Contain Element    ${xpath_sensors_search}

Verify Search Text Entered
    [Documentation]    Verify search text input allowed from "Sensors" page.
    [Tags]    verify_search_text_entered

    Wait Until Page Contains Element    ${xpath_sensors_search}
    Input Text    ${xpath_sensors_search}    ambi
    Wait Until Page Contains    Ambient    timeout=120s
    [Teardown]    Click Element    ${xpath_clear_search_input}

Verify Sensors Filter From Server Health Clickable
    [Documentation]    Verify sensors filter from server health clickable
    [Tags]    verify_sensors_filter_from_server_health_clickable

    Wait Until Page Contains Element    ${xpath_sensors_filter}    timeout=15s
    Click Element    ${xpath_sensors_filter}

    Page Should Contain Element    ${xpath_filter_ok}
    Page Should Contain Element    ${xpath_filter_warning}
    Page Should Contain Element    ${xpath_filter_critical}
    Page Should Contain Element    ${xpath_filter_clear_all}

Verify Invalid Text In Filter Sensors Search
    [Documentation]    Input invalid text in sensor search and verify error message.
    [Tags]    verify_invalid_text_in_filter_sensors_search

    Wait Until Page Contains Element    ${xpath_sensors_search}
    Input Text    ${xpath_sensors_search}    abcd123

    Page Should Contain    No items match the search query
    [Teardown]    Click Element    ${xpath_clear_search_input}

Verify Clear All Button In Sensor Page
    [Documentation]    Select all severity and verify clear all button de-selects all severity.
    [Tags]    verify_clear_all_button_in_sensor_page

    Wait Until Page Contains Element    ${xpath_sensors_filter}    timeout=15s
    Click Element    ${xpath_sensors_filter}

    # Select all severity from filter.
    Click Element At Coordinates    ${xpath_filter_ok}    0    0
    Click Element At Coordinates    ${xpath_filter_warning}    0    0
    Click Element At Coordinates    ${xpath_filter_critical}    0    0
    Element Should Be Visible    ${xpath_selected_severity}

    # De-select all severity using clear all button in filter.
    Click Element At Coordinates    ${xpath_filter_clear_all}    0    0
    Click Element    ${xpath_sensors_filter}

    Element Should Not Be Visible    ${xpath_selected_severity}
    [Teardown]    Click Element    ${xpath_sensors_filter}

Verify Filter By Severity Button OK
    [Documentation]    Select severity button OK from filter and verify.
    [Tags]    verify_filter_by_severity_button_ok

    Wait Until Page Contains Element    ${xpath_sensors_filter}    timeout=15s
    Click Element    ${xpath_sensors_filter}

    # Select OK severity from filter.
    Wait Until Page Contains Element    ${xpath_filter_ok}    timeout=5s

    Click Element At Coordinates    ${xpath_filter_ok}    0    0
    Click Element    ${xpath_sensors_filter}

    Element Should Contain    ${xpath_selected_severity}    OK
    Element Should Not Contain    ${xpath_selected_severity}    Warning
    Element Should Not Contain    ${xpath_selected_severity}    Critical
    [Teardown]    Clean Up Filter Values


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element    ${xpath_hardware_status_menu}
    Click Element    ${xpath_sensor_sub_menu}
    Wait Until Keyword Succeeds    30 sec    5 sec    Location Should Contain    sensors

    # Added delay for sensor page to load completely by waiting for disapperance of progress bar.
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=15min

Clean Up Filter Values
    [Documentation]    Do clean up filter values after test execution
    Click Element    ${xpath_sensors_filter}
    Click Element    ${xpath_filter_clear_all}
