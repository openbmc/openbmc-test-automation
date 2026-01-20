*** Settings ***

Documentation   Test OpenBMC GUI "Sensors" sub-menu.
Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

Test Tags      Sensors_Sub_Menu

*** Variables ***

${xpath_sensor_heading}      //h1[text()="Sensors"]
${xpath_sensors_filter}      //button[contains(normalize-space(.),'Filter')]
${xpath_sensors_search}      //input[contains(@class,"search-input")]
${xpath_filter_ok}           //*[@data-test-id='tableFilter-checkbox-OK']
${xpath_filter_warning}      //*[@data-test-id='tableFilter-checkbox-Warning']
${xpath_filter_critical}     //*[@data-test-id='tableFilter-checkbox-Critical']
${xpath_filter_clear_all}    //button[contains(normalize-space(.),'Clear all')]
${xpath_selected_severity}   //*[@class="d-inline-block mb-0"]
${xpath_clear_search_input}  //*[@title="Clear search input"]

*** Test Cases ***

Verify Navigation To Sensors Page
    [Documentation]  Verify navigation to Sensors page.
    [Tags]  Verify_Navigation_To_Sensors_Page

    Page Should Contain Element  ${xpath_sensor_heading}


Verify Existence Of All Sections In Sensor Page
    [Documentation]  Verify existence of all sections in sensor page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Sensor_Page

    Page Should Contain  Sensors


Verify Existence Of All Buttons And Input Boxes In Sensor Page
    [Documentation]  Verify existence of all buttons and input boxes in sensor page.
    [Tags]  Verify_Existence_Of_All_Buttons_And_Input_Boxes_In_Sensor_Page

    Page Should Contain Element  ${xpath_sensors_filter}
    Click Element  ${xpath_sensors_filter}

    #Search field
    Page Should Contain Element  ${xpath_sensors_search}


Verify Search Text Entered
    [Documentation]  Verify search text input allowed from "Sensors" page.
    [Tags]  Verify_Search_Text_Entered
    [Teardown]  Click Element  ${xpath_clear_search_input}

    Wait Until Page Contains Element  ${xpath_sensors_search}
    Input Text  ${xpath_sensors_search}  ambi
    Wait Until Page Contains  Ambient  timeout=120s


Verify Sensors Filter From Server Health Clickable
    [Documentation]  Verify sensors filter from server health clickable
    [Tags]  Verify_Sensors_Filter_From_Server_Health_Clickable

    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    Page Should Contain Element  ${xpath_filter_ok}
    Page Should Contain Element  ${xpath_filter_warning}
    Page Should Contain Element  ${xpath_filter_critical}
    Page Should Contain Element  ${xpath_filter_clear_all}


Verify Invalid Text In Filter Sensors Search
    [Documentation]  Input invalid text in sensor search and verify error message.
    [Tags]  Verify_Invalid_Text_In_Filter_Sensors_Search
    [Teardown]  Click Element  ${xpath_clear_search_input}

    Wait Until Page Contains Element  ${xpath_sensors_search}
    Input Text  ${xpath_sensors_search}  abcd123

    Page Should Contain  No items match the search query


Verify Clear All Button In Sensor Page
    [Documentation]  Select all severity and verify clear all button de-selects all severity.
    [Tags]  Verify_Clear_All_Button_In_Sensor_Page
    [Teardown]  Click Element  ${xpath_sensors_filter}

    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    # Select all severity from filter.
    Click Element At Coordinates  ${xpath_filter_ok}  0  0
    Click Element At Coordinates  ${xpath_filter_warning}  0  0
    Click Element At Coordinates  ${xpath_filter_critical}  0  0
    Element Should Be Visible  ${xpath_selected_severity}
    ${text}=    Get Text    ${xpath_selected_severity}
    Should Not Be Empty    ${text}

    # De-select all severity using clear all button in filter.
    Click Element At Coordinates  ${xpath_filter_clear_all}  0  0
    Click Element  ${xpath_sensors_filter}
    
    ${text}=    Get text    ${xpath_selected_severity}
    Should Be Empty    ${text}
    
    
Verify Filter By Severity Button OK
    [Documentation]  Select severity button OK from filter and verify.
    [Tags]  Verify_Filter_By_Severity_Button_OK
    [Teardown]  Clean Up Filter Values

    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    # Select OK severity from filter.
    Wait Until Page Contains Element  ${xpath_filter_ok}  timeout=5s

    Click Element At Coordinates  ${xpath_filter_ok}  0  0
    Click Element  ${xpath_sensors_filter}

    Element Should Contain  ${xpath_selected_severity}  OK
    Element Should Not Contain  ${xpath_selected_severity}  Warning
    Element Should Not Contain  ${xpath_selected_severity}  Critical


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_hardware_status_menu}
    Click Element  ${xpath_sensor_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  sensors

    # Added delay for sensor page to load completely by waiting for disapperance of progress bar.
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=15min


Clean Up Filter Values
    [Documentation]  Do clean up filter values after test execution
    Click Element  ${xpath_sensors_filter}
    Click Element  ${xpath_filter_clear_all}
