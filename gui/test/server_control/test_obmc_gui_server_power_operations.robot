*** Settings ***

Documentation   Test OpenBMC GUI "Server power operation" sub-menu of
...             "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Navigate To Power Operation Page


*** Variables ***

${xpath_power_indicator_bar}     //*[@id='power-indicator-bar']
${xpath_shutdown_button}         //button[contains(text(), "Shut down")]
${xpath_reboot_button}           //button[contains(text(), "Reboot")]


*** Test Cases ***

Verify System State At Power Off
    [Documentation]  Verify system state at power off.
    [Tags]  Verify_System_State_At_Power_Off

    Test Setup Execution  ${OBMC_PowerOff_state}
    Element Should Contain  ${xpath_power_indicator_bar}  Off


Verify BMC IP In Server Power Operation Page
    [Documentation]  Verify BMC IP in server power operation page.
    [Tags]  Verify_BMC_IP_In_Server_Power_Operation_Page

    Element Should Contain  ${xpath_power_indicator_bar}  ${OPENBMC_HOST}


Verify Shutdown Button At Power Off
    [Documentation]  Verify that shutdown button is not present at power Off.
    [Tags]  Verify_Shutdown_Button_At_Power_Off

    Test Setup Execution  ${OBMC_PowerOff_state}
    Element Should Not Be Visible  ${xpath_shutdown_button}


Verify Reboot Button At Power Off
    [Documentation]  Verify that reboot button is not present at power Off.
    [Tags]  Verify_Reboot_Button_At_Power_Off

    Test Setup Execution  ${OBMC_PowerOff_state}
    Element Should Not Be Visible  ${xpath_reboot_button}


*** Keywords ***

Navigate To Power Operation Page
   [Documentation]  Navigate to server power operation page.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_power_operations}
    Wait Until Page Contains  Server power operations
