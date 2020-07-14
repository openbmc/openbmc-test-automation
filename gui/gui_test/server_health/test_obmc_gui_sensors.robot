*** Settings ***

Documentation  Test OpenBMC GUI "Sensors" sub-menu of "Server health".

Resource        ../../lib/resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***
${xpath_sensors_export}         //a[contains(text(), "Export")]
${xpath_sensors_search}         //*[@placeholder="Search for sensors"]

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


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Button  ${xpath_health_menu}
    Click Element  ${xpath_sensor_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  sensors
