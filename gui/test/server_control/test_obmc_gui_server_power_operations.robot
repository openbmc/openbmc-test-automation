*** Settings ***
Documentation  This test suite will validate the "OpenBMC" GUI ->
...            "Server control" main menu -> "Server power
...            operations" submenu module.

Resource         ../../lib/resource.robot
Test Setup       Test Setup Execution  ${OBMC_PowerOff_state}
Test Teardown    Test Teardown Execution

*** Variables ***
${xpath_select_server_control}           //*[@id="nav__top-level"]/li[3]/button/span
${xpath_select_server_power_operations}  //a[@href='#/server-control/power-operations']
${string_server_power_operations}        Server power operations
${string_current_status}                 Current status
${string_select_power_operation}         Select a power operation
${string_warm_reboot}                    Attempts to perform an orderly shutdown before restarting the server
${string_cold_reboot}                    Shuts down the server immediately, then restarts it
${string_orderly_shutdown}               Attempts to stop all software on the server before removing power
${string_immediate_shutdown}             Removes power from the server without waiting for software to stop
${string_power_on}                       Attempts to power on the server

*** Test Case ***
# OpenBMC @ Power Off state test cases.

Verify Warm Reboot Button At Power Off
    [Documentation]  Verify warm reboot button is not present at power Off.
    [Tags]  Verify_Warm_Reboot_Button_At_Power_Off
    
    Select Server Power Operations Sub Menu
    #Page Should Not Contain Button  ${xpath_select_button_warm_reboot}
    Element Should Not Be Visible  ${xpath_select_button_warm_reboot}

Verify Cold Reboot Button At Power Off
    [Documentation]  Verify cold reboot button is not present at power Off.
    [Tags]  Verify_Cold_Reboot_Button_At_Power_Off

    
    Select Server Power Operations Sub Menu
    Element Should Not Be Visible  ${xpath_select_button_cold_reboot}

Verify Title Text Should Be Server Power Operations At Power Off
    [Documentation]  Verify display of title text "Server Power Operations".
    [Tags]  Verify_Title_Text_Should_Be_Server_Power_Operations_At_Power_Off
    ...  OBMC_PowerOff_state

    Select Server Power Operations Sub Menu
    Verify Display Content  ${string_server_power_operations}


Verify Sub Title Text Should Be Current Status At Power Off
    [Documentation]  Verify display of title text "Current Status".
    [Tags]  Verify_Sub_Title_Text_Should_Be_Current_Status_At_Power_Off
    ...  OBMC_PowerOff_state

    Select Server Power Operations Sub Menu
    Verify Display Content  ${string_current_status}

Verify Sub Title Text Should Be Select Power Operation At Power Off
    [Documentation]  Verify display of title text "Select a power operation".
    [Tags]  Verify_Sub_Title_Text_Should_Be_Select_Power_Operation_At_Power_Off
    ...  OBMC_PowerOff_state

    Select Server Power Operations Sub Menu
    Verify Display Content  ${string_Select_power_operation}

Verify Power On Button Should Present At Power Off
    [Documentation]  Verify presence of "Warm reboot" button.
    [Tags]  Verify_Power_On_Button_Should_Present_At_Power_Off
    ...  OBMC_PowerOff_State

    Select Server Power Operations Sub Menu
    Verify Presence of Power Button And Text Info
    ...  ${xpath_select_button_power_on}  ${string_power_on}

Verify Power On At Power Off
    [Documentation]  Verify presence of "Warm reboot" button.
    [Tags]  Verify_Power_On_At_Power_Off
    ...  OBMC_PowerOff_State

    Power On OpenBMC


# OpenBMC @ Power Running state test cases.

Verify Warm Reboot Button Should Present At Power Running
    [Documentation]  Verify presence of "Warm reboot" button.
    [Tags]  Verify_Warm_Reboot_Button_Should_Present_At_Power_Running
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Verify Presence of Power Button And Text Info
    ...  ${xpath_select_button_warm_reboot}  ${string_warm_reboot}

Verify Cold Reboot Button Should Present At Power Running
    [Documentation]  Verify presence of "cold reboot" button.
    [Tags]  Verify_Cold_Reboot_Button_Should_Present_At_Power_Running
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Verify Presence of Power Button And Text Info
    ...  ${xpath_select_button_cold_reboot}  ${string_cold_reboot}

Verify Orderly Shutdown Button Should Present At Power Running
    [Documentation]  Verify presence of "Orderly shutdow " button.
    [Tags]  Verify_Orderly_Shutdown_Button_Should_Present_At_Power_Running
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Verify Presence of Power Button And Text Info
    ...  ${xpath_select_button_orderly_shutdown}  ${string_orderly_shutdown}

Verify Immediate Shutdown Button Should Present At Power Running
    [Documentation]  Verify presence of "Immediate shutdown" button.
    [Tags]  Verify_Immediate_Shutdown_Button_Should_Present_At_Power_Running
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Verify Presence of Power Button And Text Info
    ...  ${xpath_select_button_immediate_shutdown}  ${string_immediate_shutdown}

Verify Warm Reboot Should Not Happen By Clicking No Button
    [Documentation]  Verify functionality of warm reboot "No" button clicking.
    [Tags]  Verify_Warm_Reboot_Should_Not_Happen_By_Clicking_No_Button
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Click Element  ${xpath_select_button_warm_reboot}
    Verify Warning Message Display Text  ${xpath_warm_reboot_warning_message}
    ...  ${text_warm_reboot_warning_message}
    Verify No Button Functionality
    ...  ${xpath_select_button_warm_reboot_no}

Verify Cold Reboot Should Not Happen By Clicking No Button
    [Documentation]  Verify functionality of cold reboot "No" button clicking.
    [Tags]  Verify_Cold_Reboot_Should_Not_Happen_By_Clicking_No_Button
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Click Element  ${xpath_select_button_cold_reboot}
    Verify Warning Message Display Text  ${xpath_cold_reboot_warning_message}
    ...  ${text_cold_reboot_warning_message}
    Verify No Button Functionality
    ...  ${xpath_select_button_cold_reboot_no}

Verify Orderly Shutdown Should Not Happen By Clicking No Button
    [Documentation]  Verify functionality of orderly shutdown "No" button clicking.
    [Tags]  Verify_Orderly_Shutdown_Should_Not_Happen_By_Clicking_No_Button
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Click Element  ${xpath_select_button_orderly_shutdown}
    Verify Warning Message Display Text  ${xpath_orderly_shutdown_warning_message}
    ...  ${text_orderly_shutdown_warning_message}
    Verify No Button Functionality
    ...  ${xpath_select_button_orderly_shutdown_button_no}

Verify Immediate Shutdown Should Not Happen By Clicking No Button
    [Documentation]  Verify functionality of immediate shutdown "No" button clicking.
    [Tags]  Verify_Immediate_Shutdown_Should_Not_Happen_By_Clicking_No_Button
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Click Element  ${xpath_select_button_immediate_shutdown}
    Verify Warning Message Display Text  ${xpath_immediate_shutdown_warning_message}
    ...  ${text_immediate_shutdown_warning_message}
    Verify No Button Functionality
    ...  ${xpath_select_button_immediate_shutdown_no}

Verify Warm Reboot Should Happen By Clicking Yes Button
    [Documentation]  Verify functionality of warm reboot "Yes" button clicking.
    [Tags]  Verify_Warm_Reboot_Should_Happen_By_Clicking_Yes_Button
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Warm Reboot openBMC

Verify Cold Reboot Should Happen By Clicking Yes Button
    [Documentation]  Verify functionality of cold reboot "Yes" button clicking.
    [Tags]  Verify_Cold_Reboot_Should_Happen_By_Clicking_Yes_Button
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Cold Reboot openBMC

Verify Orderly Shutdown Should Happen By Clicking Yes Button
    [Documentation]  Verify functionality of orderly shutdown "Yes" button clicking.
    [Tags]  Verify_Orderly_Shutdown_Should_Happen_By_Clicking_Yes_Button
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Orderly Shutdown OpenBMC

Verify Immediate Shutdown Should Happen By Clicking Yes Button
    [Documentation]  Verify functionality of immediate shutdown "Yes" button clicking.
    [Tags]  Verify_Immediate_Shutdown_Should_Happen_By_Clicking_Yes_Button
    ...  OBMC_PowerRunning_State
    [Setup]  Test Setup Execution  ${OBMC_PowerRunning_state}

    Select Server Power Operations Sub Menu
    Immediate Shutdown openBMC

*** Keywords ***
Select Server Power Operations Sub Menu
    [Documentation]  Selecting of OpenBMC "Server Power Operations" Submenu.

    Click Button  ${xpath_select_server_control}
    Click Button  ${xpath_select_server_power_operations}

Verify Presence of Power Button And Text Info
    [Documentation]  Verify the presens fo power button and text message info.
    [Arguments]      ${power_button}  ${power_button_text}

    # power_button         Xpath of power button.
    # power_button_text    Text message info.

    Page Should Contain Button  ${power_button}
    Verify Display Content  ${power_button_text}

Verify No Button Functionality
    [Documentation]  Verify the functionality of "No" button click.
    [Arguments]      ${xpath_no_button}

    # xpath_no_button      Xpath of "No" button.

    Click No Button  ${xpath_no_button}
    ${obmc_current_state}=  Get Text  ${xpath_display_server_power_status}
    Should Contain  ${obmc_current_state}  ${obmc_running_state}
