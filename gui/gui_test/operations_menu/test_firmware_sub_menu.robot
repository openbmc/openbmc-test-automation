*** Settings ***

Documentation  Test OpenBMC Firmware Update" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers

Test Tags      Firmware_Sub_Menu

*** Variables ***

${xpath_firmware_heading}                //h1[text()="Firmware"]
${xpath_add_file_button}                 //span[@class='add-file-btn btn btn-secondary']
${xpath_add_file_button_disabled}        //span[@class='add-file-btn btn disabled btn-secondary']
${xpath_start_update_button}             //*[@data-test-id="firmware-button-startUpdate"]
${xpath_switch_to_running}               //*[@data-test-id="firmware-button-switchToRunning"]
${xpath_switch_image_button}             //button[normalize-space()='Switch images']
${xpath_cancel_button}                   //button[normalize-space()='Cancel']
${xpath_toast_close_button}              (//button[@aria-label='Close'])[1]
${xpath_running_image_version}           //div[@class='card-deck']/div[@class='card'][1]//dd
${xpath_backup_image_version}            //div[@class='card-deck']/div[@class='card'][2]//dd


*** Test Cases ***

Verify Navigation To Firmware Page
    [Documentation]  Verify navigation to firmware page.
    [Tags]  Verify_Navigation_To_Firmware_Page

    Page Should Contain Element  ${xpath_firmware_heading}


Verify Existence Of All Sections In Firmware Page
    [Documentation]  Verify existence of all sections in firmware page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Firmware_Page

    Page Should Contain  BMC and server
    Page Should Contain  Update firmware
    Page Should Contain  Access key expiration


###  Power Off Test Cases  ###

Verify Existence Of All Buttons In Firmware Page At Host Power Off
    [Documentation]  Verify existence of all buttons in firmware page at host power off.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_Off
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Wait Until Page Contains    Update firmware  30s
    Minimize Browser Window
    Page Should Contain Element  ${xpath_add_file_button}
    Page Should Contain Element  ${xpath_start_update_button}


Verify Existence Of All Sub Sections Under BMC And Server Section At Poweroff State
    [Documentation]  Verify existence of all sub sections under BMC
    ...              and server section at poweroff state.
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Poweroff_State
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Page Should Contain  Running image
    Page Should Contain  Backup image
    Page Should Contain  Temporary
    Page Should Contain  Permanent
    Element Should Be Visible  ${xpath_switch_to_running}


Verify Switch To Running Image With Switch Image Button At PowerOff State
    [Documentation]  Verify that user is allowed to switching to a running image when
    ...              the system is in power-off state by clicking the "Switch Image" button
    [Tags]  Verify_Switch_To_Running_Image_With_Switch_Image_Button_At_PowerOff_State
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Run Keywords  Click Element  ${xpath_switch_to_running}
    ...         AND  Perform Firmware Switch And Verify

    Verify Switch Image and Cancel Buttons Of Switch To Running Image  ${OPENBMC_USERNAME}  Switch_Image


Verify Switch To Running Image With Cancel Button At PowerOff State
    [Documentation]  Verify that clicking the “Cancel” button minimizes the dialog and
    ...              prevents switching to a running image at powered‑off state.
    [Tags]  Verify_Switch_To_Running_Image_With_Cancel_Button_At_PowerOff_State
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Verify Switch Image and Cancel Buttons Of Switch To Running Image  ${OPENBMC_USERNAME}  Cancel


Verify Switch To Running Image With Switch Image Button At PowerOff State With ReadOnly User
    [Documentation]  Verify that a read-only user is restricted from switching to a running image
    ...              when the system is in power-off state by clicking the "Switch Image" button
    [Tags]  Verify_Switch_To_Running_Image_With_Switch_Image_Button_At_PowerOff_State_With_ReadOnly_User
    [Setup]  Run Keywords  Power Off Server  AND  Create Readonly User And Login To GUI  AND
    ...      Navigate To Required Sub Menu  ${xpath_operations_menu}
    ...      ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Switch Image and Cancel Buttons Of Switch To Running Image   readonly  Switch_Image


Verify Switch To Running Image With Cancel Button At PowerOff State With ReadOnly User
    [Documentation]  Verify that clicking the “Cancel” button minimizes the dialog and
    ...              prevents switching to a running image when a read-only user
    ...              attempts the action in a powered‑off state.
    [Tags]  Verify_Switch_To_Running_Image_With_Cancel_Button_At_PowerOff_State_With_ReadOnly_User
    [Setup]  Run Keywords  Power Off Server  AND  Create Readonly User And Login To GUI
    ...      AND  Navigate To Required Sub Menu  ${xpath_operations_menu}
    ...      ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Switch Image and Cancel Buttons Of Switch To Running Image   readonly  Cancel


Verify Add File Button Enabled At System Poweroff State
    [Documentation]  Verify that "Add file" button is enabled when system is at poweroff state.
    [Tags]  Verify_Add_File_Button_Enabled_At_System_Poweroff_State
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Verify Firmware Button State  user_type=admin  button=add_file  expected_state=enabled


Verify Start Update Button Enabled At System Poweroff State
    [Documentation]  Verify that "Start update" button is enabled when system is at poweroff state.
    [Tags]  Verify_Start_Update_Button_Enabled_At_System_Poweroff_State
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Verify Firmware Button State  user_type=admin  button=start_update  expected_state=enabled


Verify Add File Button Disabled At System Poweroff State With Readonly User
    [Documentation]  Verify that "Add file" button is disabled when system is at poweroff state with readonly user.
    [Tags]  Verify_Add_File_Button_Disabled_At_System_Poweroff_State_With_Readonly_User
    [Setup]  Run Keywords  Power Off Server  AND  Create Readonly User And Login To GUI  AND
    ...      Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Firmware Button State  user_type=readonly  button=add_file  expected_state=disabled


Verify Start Update Button Disabled At System Poweroff State With Readonly User
    [Documentation]  Verify that "Start update" button is disabled when system is at poweroff state with readonly user.
    [Tags]  Verify_Start_Update_Button_Disabled_At_System_Poweroff_State_With_Readonly_User
    [Setup]  Run Keywords  Power Off Server  AND  Create Readonly User And Login To GUI  AND
    ...      Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Firmware Button State  user_type=readonly  button=start_update  expected_state=disabled


###  Power On Test Cases  ###

Verify Existence Of All Sub Sections Under BMC And Server Section At Power On State
    [Documentation]  Verify existence of all sub sections under BMC and server section at power on state.
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Power_On_State
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Page Should Contain  Running image
    Page Should Contain  Backup image
    Page Should Contain  Temporary
    Page Should Contain  Permanent
    Element Should Be Disabled  ${xpath_switch_to_running}


Verify Existence Of All Buttons In Firmware Page At Host Power On
    [Documentation]  Verify existence of all buttons in firmware page at host power on.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_On
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Minimize Browser Window
    Page Should Contain Element  ${xpath_add_file_button_disabled}
    Element Should Be Disabled  ${xpath_start_update_button}


Verify Switch To Running Image At Power On State
    [Documentation]  Verify that Switch To Running Image options should be greyed out at poweron state
    [Tags]  Verify_Switch_To_Running_Image_At_Power_On_State
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Element Should Be Disabled  ${xpath_switch_to_running}


Verify Add File Button Disabled At System Poweron State
    [Documentation]  Verify that "Add file" button is disabled when system is at poweron state.
    [Tags]  Verify_Add_File_Button_Disabled_At_System_Poweron_State
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Verify Firmware Button State  user_type=admin  button=add_file  expected_state=disabled


Verify Start Update Button Disabled At System Poweron State
    [Documentation]  Verify that "Start update" button is disabled when system is at poweron state.
    [Tags]  Verify_Start_Update_Button_Disabled_At_System_Poweron_State
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Verify Firmware Button State  user_type=admin  button=start_update  expected_state=disabled


Verify Add File Button Disabled At System Poweron State With Readonly User
    [Documentation]  Verify that "Add file" button is disabled when system is at poweron state with readonly user.
    [Tags]  Verify_Add_File_Button_Disabled_At_System_Poweron_State_With_Readonly_User
    [Setup]  Run Keywords  Power On Server  AND  Create Readonly User And Login To GUI  AND
    ...      Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Firmware Button State  user_type=readonly  button=add_file  expected_state=disabled


Verify Start Update Button Disabled At System Poweron State With Readonly User
    [Documentation]  Verify that "Start update" button is disabled when system is at poweron state with readonly user.
    [Tags]  Verify_Start_Update_Button_Disabled_At_System_Poweron_State_With_Readonly_User
    [Setup]  Run Keywords  Power On Server  AND  Create Readonly User And Login To GUI  AND
    ...      Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    Verify Firmware Button State  user_type=readonly  button=start_update  expected_state=disabled


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_firmware_update_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  firmware
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


Verify Switch Image and Cancel Buttons Of Switch To Running Image
    [Documentation]  Verify switch to running image with specified action button.
    [Arguments]   ${username}  ${button}

    # Description of argument(s):
    # username      admin, service and readonly users.
    # button        Cancel and switch images.

    Wait Until Element Is Enabled  ${xpath_switch_to_running}
    Click Element  ${xpath_switch_to_running}
    Page Should Contain Element  ${xpath_switch_image_button}

    IF  '${username}' == 'readonly'
      IF  '${button}' == 'Cancel'
         Wait And Click Element  ${xpath_cancel_button}
      ELSE
         Wait And Click Element  ${xpath_switch_image_button}
         Verify Error And Unauthorized Message On GUI
      END
      Wait Until Page Contains  Firmware
    ELSE
        Log  'User is not readonly'
        IF  '${button}' == 'Cancel'
           Click Element  ${xpath_cancel_button}
        ELSE
           Perform Firmware Switch And Verify
        END
        Wait Until Page Contains  Firmware
        Page Should Contain Element  ${xpath_switch_to_running}
    END


Perform Firmware Switch And Verify
    [Documentation]  Perform firmware image switch and
    ...              verify if the firmware swap is successful.

    # Capture image versions before switch.
    ${running_image_before}=  Get Text  ${xpath_running_image_version}
    ${backup_image_before}=  Get Text  ${xpath_backup_image_version}
    Log  Running image before switch: ${running_image_before}
    Log  Backup image before switch: ${backup_image_before}

    # Click switch to running button.
    Wait Until Page Contains Element  ${xpath_switch_image_button}  timeout=10s
    Click Element  ${xpath_switch_image_button}
    Log  Switch image started now

    # Wait for Step 1 of 3 - Firmware switching.
    Wait Until Page Contains  Step 1 of 3 - Firmware switching  timeout=30s
    Page Should Contain  Process started. Firmware switching in progress.
    Click Element  ${xpath_toast_close_button}

    # Wait for Step 2 of 3 - Reboot phase.
    Wait Until Page Contains  Step 2 of 3 - Reboot  timeout=30s
    Page Should Contain  Firmware switching complete. BMC reboot in progress.
    Click Element  ${xpath_toast_close_button}

    # Wait for Step 3 of 3 - Complete phase.
    Wait Until Page Contains  Step 3 of 3 - Complete  timeout=360s
    Page Should Contain  Firmware switch successful. Click refresh to verify the running and backup images switched.
    Click Element  ${xpath_toast_close_button}

    # Refresh the GUI to verify the switch.
    Refresh GUI
    Wait Until Page Contains  Firmware

    # Get the image post firmware switch.
    ${running_image_after}=  Get Text  ${xpath_running_image_version}
    ${backup_image_after}=  Get Text  ${xpath_backup_image_version}
    Log  Running image after switch: ${running_image_after}
    Log  Backup image after switch: ${backup_image_after}

    # Verify if the image swap is correct.
    Should Be Equal  ${running_image_before}  ${backup_image_after}
    ...  msg=Running image before switch should match backup image after switch
    Should Be Equal  ${backup_image_before}  ${running_image_after}
    ...  msg=Backup image before switch should match running image after switch

    Log  Firmware images successfully swapped!


Verify Firmware Button State
    [Documentation]  Reusable keyword to verify firmware button state based on user type and button.
    ...              Arguments:
    ...              - user_type: User type (admin/readonly)
    ...              - button: Button to verify (add_file/start_update)
    ...              - expected_state: Expected button state (enabled/disabled)
    [Arguments]  ${user_type}  ${button}  ${expected_state}

    # Check user type first, then button type
    IF  '${user_type}' == 'readonly'
        # For readonly user, both buttons should always be disabled
        IF  '${button}' == 'add_file'
            Wait Until Element Is Visible  ${xpath_add_file_button_disabled}  timeout=10s
            Page Should Contain Element  ${xpath_add_file_button_disabled}
            Page Should Not Contain Element  ${xpath_add_file_button}
        ELSE IF  '${button}' == 'start_update'
            Element Should Be Disabled  ${xpath_start_update_button}
        END
    ELSE
        # For admin user, check expected state
        IF  '${button}' == 'add_file'
            IF  '${expected_state}' == 'enabled'
                Wait Until Element Is Visible  ${xpath_add_file_button}  timeout=10s
                Element Should Be Enabled  ${xpath_add_file_button}
                Page Should Not Contain Element  ${xpath_add_file_button_disabled}
            ELSE
                Wait Until Element Is Visible  ${xpath_add_file_button_disabled}  timeout=10s
                Page Should Contain Element  ${xpath_add_file_button_disabled}
                Page Should Not Contain Element  ${xpath_add_file_button}
            END
        ELSE IF  '${button}' == 'start_update'
            IF  '${expected_state}' == 'enabled'
                Wait Until Element Is Visible  ${xpath_start_update_button}  timeout=10s
                Element Should Be Enabled  ${xpath_start_update_button}
            ELSE
                Element Should Be Disabled  ${xpath_start_update_button}
            END
        END
    END
