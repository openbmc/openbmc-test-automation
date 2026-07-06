*** Settings ***

Documentation  Test OpenBMC GUI "Power restore policy" sub-menu of "Settings" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Run Keywords  Set Server Operating Mode  Normal  AND  Close Browser

Test Tags       Power_Restore_Policy_Sub_Menu

*** Variables ***

${xpath_power_restore_policy_heading}  //h1[text()="Power restore policy"]
${xpath_AlwaysOn_radio}                //input[@value='AlwaysOn']
${xpath_AlwaysOff_radio}               //input[@value='AlwaysOff']
${xpath_LastState_radio}               //input[@value='LastState']
${xpath_save_settings_button}          //button[contains(normalize-space(.),'Save')]
${xpath_manual_mode_info_message}      //p[normalize-space()='Power restore policy can not be changed while in manual operating mode.']
${xpath_change_server_mode_link}       //a[contains(text(),'Change server operating mode')]
${xpath_operations_heading}            //h1[contains(text(),'Server power operations')]

*** Test Cases ***

Verify Navigation To Power Restore Policy Page
    [Documentation]  Verify navigation to Power Restore Policy page.
    [Tags]  Verify_Navigation_To_Power_Restore_Policy_Page

    Page Should Contain Element  ${xpath_power_restore_policy_heading}


Verify Existence Of All Sections In Power Restore Policy Page
    [Documentation]  Verify existence of all sections in Power Restore Policy page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Power_Restore_Policy_Page

    Page Should Contain  Power restore policies


Verify Existence Of All Buttons In Power Restore Policy Page
    [Documentation]  Verify existence of All Buttons.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Power_Restore_Policy_Page
    [Setup]  Wait Until Element Is Visible  ${xpath_AlwaysOn_radio}

    Page Should Contain Element  ${xpath_AlwaysOn_radio}
    Page Should Contain Element  ${xpath_AlwaysOff_radio}
    Page Should Contain Element  ${xpath_LastState_radio}
    Page Should Contain Element  ${xpath_save_settings_button}


Verify Setting Power Restore Policy To Available Options With Admin User
    [Documentation]  Verify setting Power restore policy to available options with admin user.
    [Tags]  Verify_Setting_Power_Restore_Policy_To_Available_Options_With_Admin_User
    [Setup]  Set Server Operating Mode  Normal

    Set Power Restore Policy And Verify  ${xpath_AlwaysOff_radio}  ${OPENBMC_USERNAME}  Normal
    Set Power Restore Policy And Verify  ${xpath_AlwaysOn_radio}   ${OPENBMC_USERNAME}  Normal
    Set Power Restore Policy And Verify  ${xpath_LastState_radio}  ${OPENBMC_USERNAME}  Normal


### Manual Operating Mode Test Cases ###

Verify Information Message On Power Restore Policy Page
    [Documentation]  Verify information message on Power restore policy Page.
    [Tags]  Verify_Information_Message_On_Power_Restore_Policy_Page
    [Setup]  Set Server Operating Mode  Manual
    [Teardown]  Set Server Operating Mode  Normal

    Page Should Contain Element  ${xpath_manual_mode_info_message}


Verify Power Restore Policy Options Disabled In Manual Mode
    [Documentation]  Verify Power Restore policy Page when server operating mode is set to Manual.
    ...              Making sure all options should be disabled.
    [Tags]  Verify_Power_Restore_Policy_Options_Disabled_In_Manual_Mode
    [Setup]  Set Server Operating Mode  Manual
    [Teardown]  Set Server Operating Mode  Normal

    Set Power Restore Policy And Verify  ${xpath_AlwaysOff_radio}  ${OPENBMC_USERNAME}  Manual


Verify Change Server Operating Mode Navigates To Operation Page
    [Documentation]  Verify Change server operating mode navigates to Operation page.
    ...              Click element and page should contain Operations.
    [Tags]  Verify_Change_Server_Operating_Mode_Navigates_To_Operation_Page
    [Setup]  Set Server Operating Mode  Manual
    [Teardown]  Set Server Operating Mode  Normal

    # Click on "Change server operating mode" link.
    Wait And Click Element  ${xpath_change_server_mode_link}
    Wait Until Element Is Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30

    # Verify navigation to Operations page.
    Page Should Contain Element  ${xpath_operations_heading}


### Readonly User Test Cases ###

Verify Setting Power Restore Policy To Available Options With Readonly User
    [Documentation]  Verify setting Power restore policy to available options readonly user.
    [Tags]  Verify_Setting_Power_Restore_Policy_To_Available_Options_With_Readonly_User
    [Setup]  Readonly User Test Setup  Normal
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Set Power Restore Policy And Verify  ${xpath_AlwaysOff_radio}  readonly  Normal
    Set Power Restore Policy And Verify  ${xpath_AlwaysOn_radio}   readonly  Normal
    Set Power Restore Policy And Verify  ${xpath_LastState_radio}  readonly  Normal


Verify Power Restore Policy Options Disabled In Manual Mode With Readonly User
    [Documentation]  Verify Power Restore policy options are disabled in Manual mode for readonly user.
    ...              All options should be disabled and information message should be displayed.
    [Tags]  Verify_Power_Restore_Policy_Options_Disabled_In_Manual_Mode_With_Readonly_User
    [Setup]  Readonly User Test Setup  Manual
    [Teardown]  Run Keywords  Set Server Operating Mode  Normal  AND
    ...         Delete Readonly User And Logout Current GUI Session

    Set Power Restore Policy And Verify  ${xpath_AlwaysOff_radio}  readonly  Manual
    Page Should Contain Element  ${xpath_manual_mode_info_message}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_settings_menu}
    ...      ${xpath_power_restore_policy_sub_menu}  power-restore-policy

    # Set Power mode to Normal.
    Set BIOS Attribute  pvm_system_operating_mode  Normal
    Refresh GUI


Readonly User Test Setup
    [Documentation] Do this test setup for Readonly user scenarios.
    [Arguments]  ${mode}

    Set Server Operating Mode  ${mode}
    Logout GUI
    Create Readonly User And Login To GUI
    Navigate To Required Sub Menu  ${xpath_settings_menu}
    ...      ${xpath_power_restore_policy_sub_menu}  power-restore-policy


Set Power Restore Policy And Verify
    [Documentation]  Set power restore policy and verify based on user type and operating mode.
    [Arguments]  ${policy_radio_button}  ${user_type}  ${mode}=Normal

    # Description of argument(s):
    # policy_radio_button   XPath of the power restore policy radio button to select.
    #                       (e.g., ${xpath_AlwaysOff_radio}, ${xpath_AlwaysOn_radio}, ${xpath_LastState_radio}).
    # user_type             User type — pass 'readonly' for readonly user,
    #                       any other value (e.g. ${OPENBMC_USERNAME}) for admin or service user.
    # mode                  Server operating mode ('Manual' or 'Normal'). Default: Normal.

    # Wait until Always on option is visible.
    Wait Until Element Is Visible  ${xpath_AlwaysOn_radio}  timeout=10s

    # Check if mode is Manual. If Mode is manual we can't click on radio buttons, because those are disabled.
    IF  '${mode}' == 'Manual'
        # Verify all radio buttons are disabled.
        Element Should Be Disabled  ${xpath_AlwaysOn_radio}
        Element Should Be Disabled  ${xpath_AlwaysOff_radio}
        Element Should Be Disabled  ${xpath_LastState_radio}
        Element Should Be Disabled  ${xpath_save_settings_button}
    ELSE
        # Click the required policy radio button.
        Wait And Click Element  ${policy_radio_button}

        # Click the save settings button.
        Wait And Click Element  ${xpath_save_settings_button}

        IF  '${user_type}' == 'readonly'
            # For readonly user, verify error and unauthorized message.
            Verify Error And Unauthorized Message On GUI
        ELSE
            # For admin user, verify success message.
            Verify Success Message On BMC GUI Page
        END
    END


Set Server Operating Mode
    [Documentation]  Set server operating mode and refresh the page.
    [Arguments]  ${operating_mode}=Normal

    # Description of argument(s):
    # operating_mode        Server operating mode ('Manual' or 'Normal'). Default: Normal.

    Set BIOS Attribute  pvm_system_operating_mode  ${operating_mode}
    Refresh GUI
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30s
