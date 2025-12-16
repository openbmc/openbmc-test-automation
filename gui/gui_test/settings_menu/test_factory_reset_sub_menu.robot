*** Settings ***

Documentation   Test suite for OpenBMC GUI "Factory reset" sub-menu of "Settings" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

Test Tags      Factory_Reset_Sub_Menu

*** Variables ***

${xpath_factory_reset_heading}           //h1[text()="Factory reset"]
${xpath_reset_button}                    //button[@data-test-id='factoryReset-button-submit']
${xpath_reset_server_radio_button}       //*[@data-test-id='factoryReset-radio-resetBios']
${xpath_reset_bmc_server_radio_button}   //*[@data-test-id='factoryReset-radio-resetToDefaults']
${xpath_cancel_button}                   //button[@data-test-id='factoryReset-button-cancel']
${xpath_reset_server_settings}           //button[@data-test-id='factoryReset-button-confirm']


*** Test Cases ***

Verify Navigation To Factory Reset Page
    [Documentation]  Verify navigation to factory reset page.
    [Tags]  Verify_Navigation_To_Factory_Reset_Page

    Page Should Contain Element  ${xpath_factory_reset_heading}


Verify Existence Of All Sections In Factory Reset Page
    [Documentation]  Verify existence of all sections in factory reset page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Factory_Reset_Page

    Page Should Contain  Reset options


Verify Existence Of All Buttons In Factory Reset Page
    [Documentation]  Verify existence of all buttons in factory reset page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Factory_Reset_Page

    Page Should Contain Element  ${xpath_reset_button}


### Power Off Test Cases ###

Verify Existence Of All Radio Buttons In Factory Reset Page
     [Documentation]  Verify existence of all radio buttons in factory reset page.
     [Tags]  Verify_Existence_Of_All_Radio_Buttons_In_Factory_Reset_Page
     [Setup]  Power Off Server

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     Page Should Contain Element  ${xpath_reset_server_radio_button}
     Page Should Contain Element  ${xpath_reset_bmc_server_radio_button}


Verify Reset Server Settings Only Option With Readonly User When Host Off State
     [Documentation]  Verify reset server settings only option
     ...              with readonly user when host at off state.
     [Tags]  Verify_Reset_Server_Settings_Only_Option_With_Readonly_User_When_Host_Off_State
     [Setup]  Run Keywords  Power Off Server  AND  Logout GUI
     ...      AND  Create Readonly User And Login To GUI
     [Teardown]  Delete Readonly User And Logout Current GUI Session

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     # Perform reset server setting option with readonly user.
     Click Element  ${xpath_reset_button}
     Wait And Click Element  ${xpath_reset_server_settings}

     Sleep  10
     # Verify error and unautorized messages on GUI.
     Verify Error And Unauthorized Message On GUI


Verify Reset Server Settings Only Option Followed By Cancel Operation With Readonly User
     [Documentation]  Verify reset server seyttings only option followed by
     ...              cancel operation with readonly user when host at poweroff state
     [Tags]  Verify_Reset_Server_Settings_Only_Option_Followed_By_Cancel_Operation_With_Readonly_User
     [Setup]  Run Keywords  Power Off Server  AND  Logout GUI
     ...      AND  Create Readonly User And Login To GUI
     [Teardown]  Delete Readonly User And Logout Current GUI Session

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     # Perform Cancel operation.
     Click Element  ${xpath_reset_button}
     Wait And Click Element  ${xpath_cancel_button}

     Page Should Not Contain  ${xpath_cancel_button}


Verify Reset BMC And Server Settings Option With Readonly User When Host Off State
     [Documentation]  Verify reset bmc and server settings option
     ...              with readonly user when host at off state.
     [Tags]  Verify_Reset_BMC_And_Server_Settings_Option_With_Readonly_User_When_Host_Off_State
     [Setup]  Run Keywords  Power Off Server  AND  Logout GUI
     ...      AND  Create Readonly User And Login To GUI
     [Teardown]  Delete Readonly User And Logout Current GUI Session

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     # Perform reset server setting option with readonly user.
     Click Element At Coordinates  ${xpath_reset_bmc_server_radio_button}  0  0
     Wait And Click Element  ${xpath_reset_button}
     Click Element  ${xpath_reset_server_settings}

     # Verify error and unautorized messages on GUI.
     Verify Error And Unauthorized Message On GUI


Verify Reset BMC And Server Settings Option Followed By Cancel Operation With Readonly User
     [Documentation]  Verify reset bmc and server settings option followed by
     ...              cancel operation with readonly user when host at poweroff state
     [Tags]  Verify_Reset_BMC_And_Server_Settings_Option_Followed_By_Cancel_Operation_With_Readonly_User
     [Setup]  Run Keywords  Power Off Server  AND  Logout GUI
     ...      AND  Create Readonly User And Login To GUI
     [Teardown]  Delete Readonly User And Logout Current GUI Session

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     # Perform Cancel operation.
     Click Element At Coordinates  ${xpath_reset_server_radio_button}  0  0
     Wait And Click Element  ${xpath_reset_button}
     Click Element  ${xpath_cancel_button}

     Page Should Not Contain  ${xpath_cancel_button}


### Power On Test Cases ###

Verify Information Message On F-reset Page When System At Power On State
     [Documentation]  Verify information message when system at poweron state.
     [Tags]  Verify_Information_Message_On_F-reset_Page_When_System_At_Power_On_State
     [Setup]  Power Off Server

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     Page Should Contain  System must be powered off to reset


Verify Factory Reset And Reset Options Should Be Disabled At Host On State
     [Documentation]  Verify factory reset options and reset button
     ...              should be disabled when host at poweron state.
     [Tags]  Verify_Factory_Reset_And_Reset_Options_Should_Be_Disabled_At_Host_On_State
     [Setup]  Power On Server

     # Navigate to factory reset page.
     Navigate To Required Sub Menu  ${xpath_settings_menu}  ${xpath_factory_reset_sub_menu}  factory-reset

     # Factory Reset buttons.
     Element Should Be Disabled  ${xpath_reset_server_radio_button}
     Element Should Be Disabled  ${xpath_reset_bmc_server_radio_button}

     # Reset button.
     Element Should Be Disabled  ${xpath_reset_button}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_settings_menu}
    Click Element  ${xpath_factory_reset_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  factory-reset
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
