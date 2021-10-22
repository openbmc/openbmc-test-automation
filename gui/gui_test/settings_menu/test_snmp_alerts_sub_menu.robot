*** Settings ***

Documentation   Test OpenBMC GUI "SNMP Alerts" sub-menu of "Settings".

Resource        ../../lib/gui_resource.robot
Resource        ../../lib/snmp/resource.robot
Resource        ../../lib/snmp/redfish_snmp_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_snmp_alerts_sub_menu}                     //*[@data-test-id='nav-item-snmp-alerts']
${xpath_snmp_alerts_heading}                      //h1[text()="SNMP Alerts"]
${xpath_select_all_snmp}                          //*[@data-test-id='snmpAlerts-checkbox-selectAll']
${xpath_add_destination}                          //button[contains(text(),'Add destination')]
${xpath_snmp_alert_destination_heading}           //h5[contains(text(),'Add SNMP alert destination')]
${xpath_ip_address_input_button}                  //*[@data-test-id='snmpAlerts-input-ipAddress']
${xpath_port_optional_input_button}               //*[@data-test-id='snmpAlerts-input-port']
${xpath_snmp_add_destination_button}              //*[@data-test-id='snmpAlerts-button-ok']
${xpath_cancel_button}                            //button[contains(text(),'Cancel')]
${xpath_delete_button}                            //*[@data-test-id='snmpAlerts-button-deleteRow-undefined']
${xpath_delete_destination}                       //button[contains(text(),'Delete destination')]


*** Test Cases ***

Verify Navigation To SNMP Alerts Page
    [Documentation]  Verify navigation to SNMP alerts page.
    [Tags]  Verify_Navigation_To_SNMP_Alerts_Page

    Page Should Contain Element  ${xpath_snmp_alerts_heading}


Verify Existence Of All Input Boxes In SNMP Alerts Page
    [Documentation]  Verify existence of all sections in SNMP alerts page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_SNMP_Alerts_Page

    Page Should Contain Checkbox  ${xpath_select_all_snmp}


Verify Existence Of All Buttons In SNMP Alerts Page
    [Documentation]  Verify existence of all buttons in SNMP alerts page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_SNMP_Alerts_Page

    Page should Contain Button  ${xpath_add_destination}


Verify Existence Of All Fields In Add Destination
    [Documentation]  Verify existence of all buttons and fields in add destination page.
    [Tags]  Verify_Existence_Of_All_Button_And_Fields_In_Add_Destination
    [Teardown]  Run Keywords  Click Button  ${xpath_cancel_button}  AND
    ...  Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Refresh GUI And Verify Element Value  ${xpath_snmp_alerts_heading}  SNMP Alerts

    Click Element  ${xpath_add_destination}
    Wait Until Page Contains Element  ${xpath_snmp_alert_destination_heading}
    Page Should Contain Element  ${xpath_ip_address_input_button}
    Page Should Contain Element  ${xpath_port_optional_input_button}
    Page Should Contain Element  ${xpath_cancel_button}
    Page Should Contain Element  ${xpath_snmp_add_destination_button}


Configure SNMP Settings On BMC With NON Default Port Via GUI And Verify
    [Documentation]  Configure SNMP settings on BMC with non default port via GUI and verify.
    [Tags]  Configure_SNMP_Settings_On_BMC_With_Non_Default_Port_Via_GUI_And_Verify
    [Teardown]  Delete SNMP Manager Via GUI

    Configure SNMP Manager Via GUI  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}

    Wait Until Page Contains  ${SNMP_MGR1_IP}  timeout=30s

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${NON_DEFAULT_PORT1}


Configure SNMP Settings On BMC Via GUI And Verify
    [Documentation]  Configure SNMP settings on BMC via GUI and verify.
    [Tags]  Configure_SNMP_Settings_On_BMC_Via_GUI_And_Verify
    [Teardown]  Delete SNMP Manager Via GUI

    Configure SNMP Manager Via GUI  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}

    Wait Until Page Contains  ${SNMP_MGR1_IP}  timeout=30s

    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}


Configure SNMP Settings On BMC With Empty Port Via GUI And Verify
    [Documentation]  Configure SNMP settings on BMC with empty port via GUI and verify.
    [Tags]  Configure_SNMP_Settings_On_BMC_With_Empty_Port_Via_GUI_And_Verify
    [Teardown]  Delete SNMP Manager Via GUI

    Configure SNMP Manager Via GUI  ${SNMP_MGR1_IP}  ${empty_port}

    Wait Until Page Contains  ${SNMP_MGR1_IP}  timeout=30s

    # SNMP Manager IP is set with default port number when no port number is provided.
    Verify SNMP Manager Configured On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}


Configure Invalid SNMP Settings On BMC Via GUI And Verify

    [Documentation]  Configure invalid SNMP settings on BMC via GUI and verify.
    [Tags]  Configure_Invalid_SNMP_Settings_On_BMC_Via_GUI_And_Verify
    [Template]  Configure SNMP Manager On BMC With Invalid Setting Via GUI And Verify

    # snmp_manager_ip   snmp_manager_port        Expected status
    ${SNMP_MGR1_IP}     ${out_of_range_port}     Value must be between 0 – 65535
    ${SNMP_MGR1_IP}     ${alpha_port}            Value must be between 0 – 65535
    ${SNMP_MGR1_IP}     ${negative_port}         Value must be between 0 – 65535
    ${out_of_range_ip}  ${NON_DEFAULT_PORT1}     Invalid format
    ${alpha_ip}         ${NON_DEFAULT_PORT1}     Invalid format


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI

    Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_snmp_alerts_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  snmp-alerts


Configure SNMP Manager Via GUI
    [Documentation]  Configure SNMP manager via GUI.
    [Arguments]  ${snmp_ip}  ${port}

    # Description of argument(s):
    # snmp_ip  SNMP manager IP address.
    # port     SNMP manager port.

    Click Element  ${xpath_add_destination}
    Wait Until Page Contains Element  ${xpath_snmp_alert_destination_heading}
    Input Text  ${xpath_ip_address_input_button}  ${snmp_ip}
    Wait Until Keyword Succeeds  30 sec  5 sec  Get Value  ${xpath_ip_address_input_button}
    Input Text  ${xpath_port_optional_input_button}  ${port}
    Click Element  ${xpath_snmp_add_destination_button}


Delete SNMP Manager Via GUI
    [Documentation]  Delete SNMP manager via GUI.

    Click Element At Coordinates  ${xpath_select_all_snmp}  0  0
    Wait Until Keyword Succeeds  30 sec  5 sec  Click Element  ${xpath_delete_button}
    Wait Until Page Contains  Delete SNMP alert destination
    Click Element  ${xpath_delete_destination}
    Wait Until Keyword Succeeds  30 sec  10 sec  Refresh GUI And Verify Element Value
    ...  ${xpath_snmp_alerts_heading}  SNMP Alerts


Configure SNMP Manager On BMC With Invalid Setting Via GUI And Verify

    [Documentation]  Configure SNMP manager on BMC with invalid setting via GUI and verify.
    [Arguments]  ${snmp_manager_ip}  ${snmp_manager_port}  ${expected_error}
    [Teardown]  Click Element  ${xpath_cancel_button}

    # Description of argument(s):
    # snmp_manager_ip     SNMP manager IP address.
    # snmp_manager_port   SNMP manager port.
    # expected_error      Expected error optionally provided in testcase
    # ....                (e.g. Invalid format / Value must be between 0 – 65535).

    Configure SNMP Manager Via GUI  ${snmp_manager_ip}  ${snmp_manager_port}
    Wait Until Page Contains   ${expected_error}
    ${status}=  Run Keyword And Return Status
    ...  Verify SNMP Manager Configured On BMC  ${snmp_manager_ip}  ${snmp_manager_port}
    Should Be Equal As Strings  ${status}  False
    ...  msg=BMC is allowing to configure with invalid SNMP settings.
