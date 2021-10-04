*** Settings ***

Documentation  Test OpenBMC GUI "SNMP Alerts" sub-menu of "Settings".
Resource       ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
${xpath_snmp_alerts_sub_menu}              //*[@data-test-id='nav-item-snmp-alerts']
${xpath_snmp_alerts_heading}               //h1[text()="SNMP Alerts"]
${xpath_select_user}                       //input[contains(@class,"custom-control-input")]
${xpath_add_destination}                   //button[contains(text(),'Add destination')]
${xpath_delete_destination}                //*[@data-test-id='snmpAlerts-button-deleteRow-undefined']
${xpath_snmp_alert_destination_heading}    //h5[contains(text(),'Add SNMP alert destination')]
${xpath_ip_address_input_button}           //*[@data-test-id='snmpAlerts-input-ipAddress']
${xpath_port_optional_input_button}        //*[@data-test-id='snmpAlerts-input-port']
${xpath_snmp_add_destination_button}       //*[@data-test-id='snmpAlerts-button-ok']
${xpath_cancel_button}                     //*[@class='btn btn-secondary']

*** Test Cases ***

Verify Navigation To SNMP Alerts Page
    [Documentation]  Verify navigation to snmp alerts page.
    [Tags]  Verify_Navigation_To_SNMP_Alerts_Page
    Page Should Contain Element  ${xpath_snmp_alerts_heading}


Verify Existence Of All Input Boxes In SNMP Alerts Page
    [Documentation]  Verify existence of all sections in snmp alerts page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_SNMP_Alerts_Page
    Page Should Contain Checkbox  ${xpath_select_user}


Verify Existence Of All Buttons In SNMP Alerts Page
    [Documentation]  Verify existence of all buttons in snmp alert page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_SNMP_Alerts_Page
    Page should contain Button  ${xpath_add_destination}
    Page Should Contain Element  ${xpath_delete_destination}


Verify Existence Of All Button And Fields In Add Destination
    [Documentation]  Verify existence of all buttons and fields in add destination page.
    [Tags]  Verify_Existence_Of_All_Button_And_Fields_In_Add_Destination
    [Teardown]  Click Element  ${xpath_cancel_button}

    Click Element  ${xpath_add_destination}
    Wait Until Page Contains Element  ${xpath_snmp_alert_destination_heading}
    Page Should Contain Element  ${xpath_ip_address_input_button}
    Page Should Contain Element  ${xpath_port_optional_input_button}
    Page Should Contain Element  ${xpath_cancel_button}
    Page Should Contain Element  ${xpath_snmp_add_destination_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_snmp_alerts_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  snmp-alerts

