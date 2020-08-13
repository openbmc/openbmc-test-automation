*** Settings ***

Documentation   Test OpenBMC GUI "Server power operation" sub-menu of
...             "Server control".

Resource        ../../lib/resource.robot

*** Variables ***

${xpath_shutdown_button}         //button[contains(text(), "Shut down")]
${xpath_power_on_button}         //button[contains(text(), "Power on")]
${xpath_tpm_toggle_switch}       //label[@for="toggle__switch-round"]
${xpath_select_boot_override}    //select[@id="boot-selected"]
${xpath_select_one_time_boot}    //label[@id="one-time-label"]

*** Test Cases ***

Verify Power On Button Should Present At Power Off
    [Documentation]  Verify presence of "Power On" button at power off.
    [Tags]  Verify_Power_On_Button_At_Power_Off
    [Setup]  Setup For Test Execution  ${OBMC_PowerOff_state}

    Element Should Be Visible  ${xpath_power_on_button}


Verify Shutdown Button At Power On
    [Documentation]  Verify that shutdown button is present at power on.
    [Tags]  Verify_Shutdown_Button_At_Power_On
    [Setup]  Setup For Test Execution  ${obmc_PowerRunning_state}

    Element Should Be Visible  ${xpath_shutdown_button}


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
