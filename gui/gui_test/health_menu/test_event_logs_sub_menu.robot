*** Settings ***

Documentation  Test OpenBMC GUI "Event logs" sub-menu.

Resource        ../../lib/resource.robot
Variables       ../../data/resource_variables.py

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***


*** Test Cases ***

Verify Existence Of All Sections In Event Logs Page
    [Documentation]  Verify existence of all sections in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Event_Logs_Page

    Page Should Contain  Event logs


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_event_logs_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  event-logs
