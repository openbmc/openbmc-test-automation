*** Settings ***

Documentation  Test OpenBMC GUI "Sensors" sub-menu.
Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
${xpath_sensors_filter}         //button[contains(text(),'Filter')]
${xpath_sensors_search}         //input[contains(@class,"search-input form-control")]

*** Test Cases ***

Verify Existence Of All Sections In Sensor Page
    [Documentation]  Verify existence of all sections in sensor page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Sensor_Page

    Page Should Contain  Sensors
    Page Should Contain  Name
    Page Should Contain  Status


Verify Existence Of All Buttons In Sensor Page
    [Documentation]  Verify existence of all buttons in sensor page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Sensor_Page

    Page Should Contain Element  ${xpath_sensors_filter}
    Click Element  ${xpath_sensors_filter}
    Page Should Contain  OK
    Page Should Contain  Warning
    Page Should Contain  Critical

    #Search field
    Page Should Contain Element  ${xpath_sensors_search}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    # Navigate to https://xx.xx.xx.xx/#/health/sensors  Sensor page.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_sensor_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  sensors