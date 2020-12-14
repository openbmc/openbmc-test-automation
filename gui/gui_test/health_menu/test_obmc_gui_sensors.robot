*** Settings ***

Documentation   Test OpenBMC GUI "Sensors" sub-menu.
Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
${xpath_sensor_heading}      //h1[text()="Sensors"]
${xpath_sensors_filter}      //button[contains(text(),'Filter')]
${xpath_sensors_search}      //input[contains(@class,"search-input")]
${xpath_filter_ok}           //*[@data-test-id='tableFilter-checkbox-OK']
${xpath_filter_warning}      //*[@data-test-id='tableFilter-checkbox-Warning']
${xpath_filter_critical}     //*[@data-test-id='tableFilter-checkbox-Critical']
${xpath_filter_clear_all}    //*[@data-test-id='tableFilter-button-clearAll']
${xpath_selected_severity}   //*[@class="d-inline-block mb-0"]

*** Test Cases ***

Verify Navigation To Sensors Page
    [Documentation]  Verify navigation to Sensors page.
    [Tags]  Verify_Navigation_To_Sensors_Page

    Page Should Contain Element  ${xpath_sensor_heading}


Verify Existence Of All Sections In Sensor Page
    [Documentation]  Verify existence of all sections in sensor page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Event_Logs_Page

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

    Wait Until Page Contains Element  ${xpath_sensors_search}
    Input Text  ${xpath_sensors_search}  ambi
    Wait Until Page Contains  ambient  timeout=15


Verify Sensors Filter From Server Health Clickable
    [Documentation]  Verify sensors filter from server health clickable
    [Tags]  Verify_Sensors_Filter_From_Server_Health_Clickable

    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    Page Should Contain Element  ${xpath_filter_ok}
    Page Should Contain Element  ${xpath_filter_warning}
    Page Should Contain Element  ${xpath_filter_critical}
    Page Should Contain Element  ${xpath_filter_clear_all}


Verify Clear All In Filters
    [Documentation]  Select all severity and verify clear all button de-selects all severity.
    [Tags]  Verify_Clear_All_In_Filters

    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    # Select all severity from filter.
    Click Element At Coordinates    ${xpath_filter_ok}    0    0
    Click Element At Coordinates    ${xpath_filter_warning}    0    0
    Click Element At Coordinates    ${xpath_filter_critical}    0    0

    # De-select all severity using clear all button in filter.

    Click Element At Coordinates    ${xpath_filter_clear_all}    0    0
    Click Element  ${xpath_sensors_filter}

    Element Should Not Be Visible  ${xpath_selected_severity}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_sensor_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  sensors
