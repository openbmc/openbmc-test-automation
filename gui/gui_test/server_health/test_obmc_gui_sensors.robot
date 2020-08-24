*** Settings ***

Documentation  Test OpenBMC GUI "Sensors" sub-menu of "Server health".

Resource        ../../lib/resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***
${xpath_sensors_export}         //a[contains(text(), "Export")]
${xpath_sensors_search}         //input[contains(@id,"searchInput")]
${xpath_sensors_filter}    //button[contains(text(),'Filter')]
${xpath_filter_ok}         //*[@data-test-id='tableFilter-checkbox-OK']
${xpath_filter_warning}    //*[@data-test-id='tableFilter-checkbox-Warning']
${xpath_filter_critical}   //*[@data-test-id='tableFilter-checkbox-Critical']
${xpath_filter_clear_all}  //*[@data-test-id='tableFilter-button-clearAll']

*** Test Cases ***
Verify Select Sensors From Server Health
    [Documentation]  Verify ability to select "Sensors" sub-menu option of
    ...  "Server health".
    [Tags]  Verify_Select_Sensors_From_Server_Health

    Page Should Contain  Sensors


Verify Search Text Enterable
    [Documentation]  Verify search text input allowed from "Sensors" page.
    [Tags]  Verify_Search_Text_Enterable

    Wait Until Page Contains Element  ${xpath_sensors_search}
    Input Text  ${xpath_sensors_search}  temp
    Wait Until Page Contains  p0 vcs temp  timeout=15


Verify Sensors Filter From Server Health Clickable
    [Documentation]  Verify sensors filter from server health clickable
    [Tags]  Verify_Sensors_Filter_From_Server_Health_Clickable

    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    Page Should Contain Element  ${xpath_filter_ok}
    Page Should Contain Element  ${xpath_filter_warning}
    Page Should Contain Element  ${xpath_filter_critical}
    Page Should Contain Element  ${xpath_filter_clear_all}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Button  ${xpath_health_menu}
    Click Element  ${xpath_sensor_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  sensors
