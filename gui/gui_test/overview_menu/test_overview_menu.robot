*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot
Resource        ../../../lib/logging_utils.robot
Resource        ../../../lib/list_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}          //h1[contains(text(), "Overview")]
${xpath_edit_network_settings_button}  //*[@data-test-id='overviewQuickLinks-button-networkSettings']
${view_all_event_logs}                 //*[@data-test-id='overviewEvents-button-eventLogs']

*** Test Cases ***

Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


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
    ...  ${REDFISH_CHASSIS_URI}motherboard  Manufacturer

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
    Wait Until Page Contains  xyz.openbmc_project.Common.Error.InternalFailure  timeout=30s


Verify View All Event Logs Button
    [Documentation]  Verify view all event log button in overview page.
    [Tags]  Verify_View_All_Event_Logs_Button

    Generate Test Error Log
    Page Should Contain Element  ${view_all_event_logs}  timeout=30
    Click Element  ${view_all_event_logs}
    Wait Until Page Contains Element  ${xpath_event_header}  timeout=30


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

