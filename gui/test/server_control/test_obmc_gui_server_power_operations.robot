*** Settings ***

Documentation   Test OpenBMC GUI "Server power operation" sub-menu of
...             "Server control".

Resource        ../../lib/resource.robot

Test Teardown   Close Browser


*** Variables ***

${xpath_power_indicator_bar}     //*[@id='power-indicator-bar']
${xpath_shutdown_button}         //button[contains(text(), "Shut down")]
${xpath_reboot_button}           //button[contains(text(), "Reboot")]
${xpath_power_on_button}         //button[contains(text(), "Power on")]
${xpath_tpm_toggle_switch}       //label[@for="toggle__switch-round"]
${xpath_select_boot_override}    //select[@id="boot-selected"]
${xpath_select_one_time_boot}    //label[@id="one-time-label"]

*** Test Cases ***

Verify System State At Power Off
    [Documentation]  Verify system state at power off.
    [Tags]  Verify_System_State_At_Power_Off
    [Setup]  Setup For Test Execution  ${OBMC_PowerOff_state}

    Element Should Contain  ${xpath_power_indicator_bar}  Off


Verify BMC IP In Server Power Operation Page
    [Documentation]  Verify BMC IP in server power operation page.
    [Tags]  Verify_BMC_IP_In_Server_Power_Operation_Page
    [Setup]  Setup For Test Execution  ${OBMC_PowerOff_state}

    Element Should Contain  ${xpath_power_indicator_bar}  ${OPENBMC_HOST}


Verify Shutdown Button At Power Off
    [Documentation]  Verify that shutdown button is not present at power Off.
    [Tags]  Verify_Shutdown_Button_At_Power_Off
    [Setup]  Setup For Test Execution  ${OBMC_PowerOff_state}

    Element Should Not Be Visible  ${xpath_shutdown_button}


Verify Reboot Button At Power Off
    [Documentation]  Verify that reboot button is not present at power Off.
    [Tags]  Verify_Reboot_Button_At_Power_Off
    [Setup]  Setup For Test Execution  ${OBMC_PowerOff_state}

    Element Should Not Be Visible  ${xpath_reboot_button}


Verify Power On Button At Power Off
    [Documentation]  Verify presence of "Power On" button at power off.
    [Tags]  Verify_Power_On_Button_At_Power_Off
    [Setup]  Setup For Test Execution  ${OBMC_PowerOff_state}

    Element Should Be Visible  ${xpath_power_on_button}


Verify System State At Power On
    [Documentation]  Verify system state at power on.
    [Tags]  Verify_System_State_At_Power_On
    [Setup]  Setup For Test Execution  ${obmc_PowerRunning_state}

    Element Should Contain  ${xpath_power_indicator_bar}  Running


Verify Shutdown Button At Power On
    [Documentation]  Verify that shutdown button is present at power on.
    [Tags]  Verify_Shutdown_Button_At_Power_On
    [Setup]  Setup For Test Execution  ${obmc_PowerRunning_state}

    Element Should Be Visible  ${xpath_shutdown_button}


Verify Reboot Button At Power On
    [Documentation]  Verify that reboot button is present at power on.
    [Tags]  Verify_Reboot_Button_At_Power_On
    [Setup]  Setup For Test Execution  ${obmc_PowerRunning_state}

    Element Should Be Visible  ${xpath_reboot_button}


Verify Existence Of All Sections In Host Os Boot Settings
    [Documentation]  Verify existence of all sections in host os boot settings.
    [Tags]  Verify_Existence_Of_All_Sections_In_Host_Os_Boot_Settings
    [Setup]  Run Keywords  Launch Browser And Login OpenBMC GUI  AND
    ...  Navigate To Server Power Operations

    Page Should Contain  Boot setting override
    Page Should Contain  TPM required policy


Verify Existence Of All Buttons In Host Os Boot Settings
    [Documentation]  Verify existence of all buttons in host os boot settings.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Host_Os_Boot_Settings
    [Setup]  Run Keywords  Launch Browser And Login OpenBMC GUI  AND
    ...  Navigate To Server Power Operations

    Page Should Contain Element  ${xpath_tpm_toggle_switch}
    Page Should Contain Element  ${xpath_save_button}
    Page Should Contain Element  ${xpath_cancel_button}


Verify Existence Of All Input Boxes In Host Os Boot Settings
    [Documentation]  Verify existence of all input boxes in host os boot settings.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Host_Os_Boot_Settings
    [Setup]  Run Keywords  Launch Browser And Login OpenBMC GUI  AND
    ...  Navigate To Server Power Operations

    Page Should Contain Element  ${xpath_select_boot_override}
    Page Should Contain Element  ${xpath_select_one_time_boot}


*** Keywords ***

Setup For Test Execution
    [Documentation]  Do setup tasks for test case.
    [Arguments]  ${obmc_required_state}

    # Description of argument(s):
    # obmc_required_state  The OpenBMC state which is required for the test.

    Test Setup Execution  ${obmc_required_state}
    Navigate To Server Power Operations

Navigate To Server Power Operations
    [Documentation]  Navigate to server power operations.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_power_operations}
    Wait Until Page Contains  Server power operations
