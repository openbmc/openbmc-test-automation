*** Settings ***

Documentation   Test OpenBMC GUI header.

Resource        ../../lib/gui_resource.robot

Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser

Test Tags      GUI_Header

*** Variables ***

${xpath_header_text}          //*[@data-test-id='appHeader-container-overview']
${xpath_power_info}           //*[text()='Power information']
${ENV_METRICS_URI}            ${REDFISH_CHASSIS_URI}/${CHASSIS_ID}/EnvironmentMetrics
${xpath_dumps}                //h3[text()='Dumps']

*** Test Cases ***

Verify GUI Header Text
    [Documentation]  Verify text in GUI header.
    [Tags]  Verify_GUI_Header_Text

    ${gui_header_text}=  Get Text  ${xpath_header_text}
    Should Contain  ${gui_header_text}  ASMI


Verify Server Health Button
    [Documentation]  Verify event log page on clicking health button.
    [Tags]  Verify_Server_Health_Button

    Wait Until Element Is Visible   ${xpath_server_health_header}
    Click Element  ${xpath_server_health_header}
    Wait Until Page Contains Element  ${xpath_event_logs_heading}  timeout=15s


Verify Server Power Button
    [Documentation]  Verify server power operations page on clicking power button.
    [Tags]  Verify_Server_Power_Button

    Wait Until Element Is Visible   ${xpath_server_power_header}
    Click Element  ${xpath_server_power_header}
    Wait Until Page Contains  Server power operations


Verify GUI Logout
    [Documentation]  Verify OpenBMC GUI logout.
    [Tags]  Verify_GUI_Logout

    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}  timeout=15s
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Close Browser

Verify System Serial And Model Number In GUI Header Page
    [Documentation]  Verify system serial and model number in GUI header page.
    [Tags]  Verify_System_Serial_And_Model_Number_In_GUI_Header_Page
    [Setup]  Run Keywords  Launch Browser And Login GUI  AND  Redfish Login
    [Teardown]  Run Keywords  Close Browser  AND  Redfish.Logout

   # Model.
   ${redfish_model_number}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  Model
   Element Should Be Visible  ${xpath_header_text}
   ...  /following-sibling::*/*[text()='${redfish_model_number}']

   # Serial Number.
   ${redfish_serial_number}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  SerialNumber
   Element Should Be Visible  ${xpath_header_text}
   ...  /following-sibling::*/*[text()='${redfish_serial_number}']


Verify Values Under Power Information Section
    [Documentation]  Verify values under power information section in overview page.
    [Tags]  Verify_Values_Under_Power_Information_Section
    [Setup]  Run Keywords  Launch Browser And Login GUI  AND  Redfish.Login
    [Teardown]  Run Keywords  Close Browser  AND  Redfish.Logout

    # Verify power information heading.
    Wait Until Page Contains Element  ${xpath_power_info}  timeout=15s
    Element Should Be Visible  ${xpath_power_info}

    # Verify power mode value.
    ${redfish_power_mode}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  PowerMode
    ${converted_redfish_power_mode}=  Replace String  ${redfish_power_mode}
    ...  MaximumPerformance  Maximum performance
    Element Should Be Visible  ${xpath_header_text}
    ...  /following-sibling::*/*[text()='${converted_redfish_power_mode}']

    # Verify power consumption value.
    ${power_consumption_value}=  Redfish.Get Attribute  ${ENV_METRICS_URI}  PowerWatts
    Element Should Be Visible  ${xpath_header_text}
    ...  /following-sibling::*/*[text(),'${power_consumption_value}']

    # Verify power cap value.
    ${power_cap_value}=  Redfish.Get Attribute  ${ENV_METRICS_URI}  PowerLimitWatts
    Element Should Be Visible  ${xpath_header_text}
    ...  /following-sibling::*/*[text(),'${power_cap_value}']

    # Verify idle power saver status.
    ${idle_power_saver}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  IdlePowerSaver
    ${status}=  Verify Idle Power Saver  ${idle_power_saver}

    # Verify View more link and navigation to Power page.
    Page Should Contain Link  View more
    Click Link  View more
    Wait Until Page Contains  Power  timeout=15s


Verify Dumps Information In Overiew Page
    [Documentation]  Verify dumps information in overiew page.
    [Tags]  Verify_Dumps_Information_In_Overiew_Page
    [Setup]  Run Keywords  Launch Browser And Login GUI  AND  Redfish.Login
    [Teardown]  Run Keywords  Close Browser  AND  Redfish.Logout

    # Verify dumps heading.
    Wait Until Page Contains Element  ${xpath_dumps}  timeout=15s
    Element Should Be Visible  ${xpath_dumps}

    # Verify dumps count.
    ${bmc_dump}=  Redfish.Get Attribute  ${REDFISH_DUMP_URI}  Members@odata.count
    Element Should Be Visible  ${xpath_header_text}
    ...  /following-sibling::*/*[text(),'${bmc_dump}']

    # Verify view more link and navigation to dumps page.
    Page Should Contain Link  View more
    Click Link  View more
    Wait Until Page Contains  Dumps  timeout=15s

*** Keywords ***

Verify Idle Power Saver
    [Documentation]  Verify idel power saver in GUI via Redfish.
    [Arguments]  ${idle_power_saver}

    # Description of argument(s):
    # idle_power_saver      IdlePowerSaver status from Redfish,either Enabled/Disabled.

    IF  '${idle_power_saver['Enabled']}' == 'True'
        Element Should Be Visible  ${xpath_header_text}
        ...  /following-sibling::*/*[text()='Enabled']
    ELSE
        Element Should Be Visible  ${xpath_header_text}
        ...  /following-sibling::*/*[text()='Disabled']
    END
