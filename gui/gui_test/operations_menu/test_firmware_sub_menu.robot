*** Settings ***

Documentation  Test OpenBMC "Firmware" sub-menu of "Operations".
...
...  Test Parameters:
...  IMAGE_FILE_PATH         Path to the BMC firmware package file.
...  HOST_IMAGE_FILE_PATH    Path to the BIOS firmware package file.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_redfish_resource.robot
Library         ../../../lib/code_update_utils.py
Library         String

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers

Test Tags      Firmware_Sub_Menu

*** Variables ***

${xpath_firmware_heading}                //h1[text()="Firmware"]
${xpath_add_file_button}                 //button[contains(@class,'add-file-btn') and not(contains(@class,'disabled'))] | //span[@class='add-file-btn btn btn-secondary']
${xpath_add_file_button_disabled}        //span[@class='add-file-btn btn disabled btn-secondary']
${xpath_start_update_button}             //*[@data-test-id="firmware-button-startUpdate"]
${xpath_switch_to_running}               //*[@data-test-id="firmware-button-switchToRunning"]
${xpath_switch_image_button}             //button[normalize-space()='Switch images']
${xpath_cancel_button}                   //button[normalize-space()='Cancel']
${xpath_toast_close_button}              (//button[@aria-label='Close'])[1]
${xpath_firmware_file_input}             //input[@type='file']
${xpath_update_firmware_confirm_button}  //div[contains(@class,'modal') or @role='dialog']//button[normalize-space(.)='Start update']
${xpath_update_started_toast}            //div[contains(@class,'toast') and contains(.,'Update started')]
${xpath_update_started_toast_close}      //div[contains(@class,'toast') and contains(.,'Update started')]//button[contains(@class,'close')]
${xpath_verify_update_toast}             //div[contains(@class,'toast') and contains(.,'Verify update')]
${xpath_verify_update_toast_close}       //div[contains(@class,'toast') and contains(.,'Verify update')]//button[contains(@class,'close')]
${xpath_running_image_version}           //div[@class='card-deck']/div[@class='card'][1]//dd
${xpath_backup_image_version}            //div[@class='card-deck']/div[@class='card'][2]//dd
${FW_VERIFY_DIR}                         /tmp/fw_verify

*** Test Cases ***

Verify Navigation To Firmware Page
    [Documentation]  Verify navigation to firmware page.
    [Tags]  Verify_Navigation_To_Firmware_Page

    Page Should Contain Element  ${xpath_firmware_heading}


Verify Existence Of All Sections In Firmware Page
    [Documentation]  Verify existence of all sections in firmware page.
    ...  Detects old vs current webui by checking for "BMC and server":
    ...  - Old UI: "BMC and server" and "Access key expiration" are both required.
    ...  - Current UI: "BMC" is required; "BIOS" is optional (config-dependent);
    ...    "Access key expiration" is not checked.
    [Tags]  Verify_Existence_Of_All_Sections_In_Firmware_Page

    # Detect UI version: old webui shows "BMC and server", current webui shows "BMC".
    ${is_old_ui}=  Run Keyword And Return Status  Page Should Contain  BMC and server
    IF    ${is_old_ui}
        # Old UI: both sections are mandatory.
        Page Should Contain  BMC and server
        Page Should Contain  Access key expiration
    ELSE
        # Current UI: "BMC" section is mandatory; "BIOS" is optional.
        Page Should Contain  BMC
        # BIOS section is present only on systems with Host firmware support
        ${has_bios}=  Run Keyword And Return Status  Page Should Contain  BIOS
        Log  BIOS section present: ${has_bios}
    END
    # "Update firmware" section is present in both old and current UI.
    Page Should Contain  Update firmware


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
    ...              Running image and Backup image are present in
    ...              both old and current webui.
    ...              Temporary and Permanent apply-time options are
    ...              required on old UI and not checked on current UI
    ...              (detected via "BMC and server" section title).
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Poweroff_State
    [Setup]  Run Keywords  Power Off Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Page Should Contain  Running image
    Page Should Contain  Backup image
    # Detect UI version: old webui shows "BMC and server", current webui shows "BMC".
    ${is_old_ui}=  Run Keyword And Return Status  Page Should Contain  BMC and server
    IF    ${is_old_ui}
        # Old UI: Temporary and Permanent apply-time options are mandatory.
        Page Should Contain  Temporary
        Page Should Contain  Permanent
    END
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
    ...              Running image and Backup image are present in both old and current webui.
    ...              Temporary and Permanent apply-time options are required on old UI and not
    ...              checked on current UI (detected via "BMC and server" section title).
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Power_On_State
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Page Should Contain  Running image
    Page Should Contain  Backup image
    # Detect UI version: old webui shows "BMC and server", current webui shows "BMC".
    ${is_old_ui}=    Run Keyword And Return Status    Page Should Contain    BMC and server
    IF    ${is_old_ui}
        # Old UI: Temporary and Permanent apply-time options are mandatory.
        Page Should Contain  Temporary
        Page Should Contain  Permanent
    END
    Element Should Be Disabled  ${xpath_switch_to_running}


Verify Existence Of All Buttons In Firmware Page At Host Power On
    [Documentation]  Verify existence of all buttons in firmware page at host power on.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_On
    [Setup]  Run Keywords  Power On Server  AND  Navigate To Required Sub Menu
    ...      ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Wait Until Element Is Not Visible  ${xpath_page_loading_progress_bar}  timeout=30
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


Verify BMC Firmware Update
    [Documentation]  Verify BMC firmware update.
    [Tags]  Verify_BMC_Flash_Firmware_Update
    [Teardown]  Test Teardown Execution

    # Add file existence check
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}  msg=Firmware package not found: ${IMAGE_FILE_PATH}
    Perform Firmware Update  ${IMAGE_FILE_PATH}

    # Verify BMC version matches uploaded image.
    ${image_version}=  code_update_utils.Get Version Tar  ${IMAGE_FILE_PATH}
    Wait Until Keyword Succeeds  15 min  30 sec  Redfish.Login
    ${bmc_version}=  Get BMC Firmware Version  running
    Should Be Equal  ${bmc_version}  ${image_version}

    # Verify the version displayed on Web UI matches.
    Verify Version On GUI  ${image_version}


Verify Valid Signed BMC Firmware
    [Documentation]  Verify signature for BMC firmware.
    [Tags]  Verify_Valid_Signed_BMC_Firmware
    [Teardown]  Remove Directory  ${FW_VERIFY_DIR}  recursive=True

    Create Directory  ${fw_verify_dir}
    ${result}=  Run Process  tar  -xf  ${IMAGE_FILE_PATH}  -C  ${fw_verify_dir}/
    Should Be Equal As Integers  ${result.rc}  0
    ...  msg=Failed to extract firmware tar: ${IMAGE_FILE_PATH}

    VAR  @{images}
    ...  MANIFEST
    ...  image-kernel
    ...  image-rofs
    ...  image-u-boot
    ...  image-rwfs

    FOR  ${image}  IN  @{images}
        Verify Image Signature  ${image}
    END


Verify BMC Running Firmware Version
    [Documentation]  Verify BMC running firmware version.
    [Tags]  Verify_BMC_Running_Firmware_Version
    [Teardown]  Test Teardown Execution

    # Get running firmware version via Redfish.
    Redfish.Login
    ${running_version}=  Get BMC Firmware Version  running

    # Verify the version displayed on Web UI matches.
    Verify Version On GUI  ${running_version}

    ${image_version}=  code_update_utils.Get Version Tar  ${IMAGE_FILE_PATH}
    Should Be Equal  ${running_version}  ${image_version}


Verify BMC Backup Firmware Version
    [Documentation]  Verify BMC backup firmware version.
    [Tags]  Verify_BMC_Backup_Firmware_Version
    [Teardown]  Test Teardown Execution

    # Get backup firmware version via Redfish.
    Redfish.Login
    ${backup_version}=  Get BMC Firmware Version  backup

    # Verify the backup version is displayed on Web UI.
    Verify Version On GUI  ${backup_version}


Verify Host Firmware Update
    [Documentation]  Verify Host/BIOS firmware update.
    [Tags]  Verify_Host_Firmware_Update
    [Teardown]  Test Teardown Execution

    # Add file existence check
    OperatingSystem.File Should Exist  ${HOST_IMAGE_FILE_PATH}  msg=Firmware package not found: ${HOST_IMAGE_FILE_PATH}
    Perform Firmware Update  ${HOST_IMAGE_FILE_PATH}

    # Verify Host version matches uploaded image.
    ${image_version}=  code_update_utils.Get Version Tar  ${HOST_IMAGE_FILE_PATH}
    Redfish.Login
    ${version}=  Get Host Firmware Version
    Should Be Equal  ${version}  ${image_version}

    # Verify the version displayed on Web UI matches.
    Verify Version On GUI  ${image_version}


Verify Host Running Firmware Version
    [Documentation]  Verify Host (BIOS) running firmware version.
    [Tags]  Verify_Host_Running_Firmware_Version
    [Teardown]  Test Teardown Execution

    # Get running BIOS firmware version via Redfish FirmwareInventory.
    Redfish.Login
    ${host_version}=  Get Host Firmware Version

    # Verify the version displayed on Web UI matches.
    Verify Version On GUI  ${host_version}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30


Test Teardown Execution
    [Documentation]  Run FFDC on Test case fail.

    FFDC On Test Case Fail


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
    [Arguments]  ${user_type}  ${button}  ${expected_state}

    # Description of argument(s):
    # user_type             User type (admin/readonly)
    # button                Button to verify (add_file/start_update)
    # expected_state        Expected button state (enabled/disabled)

    # Check user type first, then button type.
    IF  '${user_type}' == 'readonly'
        # For readonly user, both buttons should always be disabled.
        IF  '${button}' == 'add_file'
            Wait Until Element Is Visible  ${xpath_add_file_button_disabled}  timeout=10s
            Page Should Contain Element  ${xpath_add_file_button_disabled}
            Page Should Not Contain Element  ${xpath_add_file_button}
        ELSE IF  '${button}' == 'start_update'
            Element Should Be Disabled  ${xpath_start_update_button}
        END
    ELSE
        # For admin user, check expected state.
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


Get BMC Firmware Version
    [Documentation]  Get the BMC firmware version (running or backup) via Redfish.
    [Arguments]  ${firmware_type}=running

    # Description of argument(s):
    # firmware_type     Type of firmware version to retrieve: 'running' or 'backup'.

    ${running_version}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  FirmwareVersion

    IF  '${firmware_type}' == 'running'
        RETURN  ${running_version}
    END

    # For backup: iterate FirmwareInventory to find a BMC entry that differs from running.
    ${members}=  redfish_utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory

    FOR  ${member_uri}  IN  @{members}
        ${inv_data}=  Redfish.Get  ${member_uri}
        VAR  ${version}  ${inv_data.dict.get('Version', '')}
        VAR  ${name}  ${inv_data.dict.get('Name', '')}
        ${is_bmc}=  Run Keyword And Return Status
        ...  Should Contain  ${name}  BMC
        IF  ${is_bmc} and '${version}' != '' and '${version}' != '${running_version}'
            RETURN  ${version}
        END
    END
    RETURN  ${EMPTY}

Perform Firmware Update
    [Documentation]  Upload a firmware package via Web UI and verify update completed.
    [Arguments]  ${pkg_path}

    # Description of argument(s):
    # pkg_path     Full path to the firmware package file.

    Log To Console  \nUploading ${pkg_path}
    # Upload firmware package file via Web UI.
    Choose File  ${xpath_firmware_file_input}  ${pkg_path}
    Wait Until Element Is Enabled  ${xpath_start_update_button}  timeout=30s
    Click Element  ${xpath_start_update_button}

    # A modal dialog titled "Update firmware" appears after clicking Start update.
    # It says: "The new image will be uploaded and activated. After that, the host
    # will reboot automatically to run from the new image."
    # Wait for the modal to appear, then click "Start update" to confirm.
    Wait Until Page Contains  Update firmware  timeout=30s
    Wait Until Element Is Visible  ${xpath_update_firmware_confirm_button}  timeout=30s
    Click Button  ${xpath_update_firmware_confirm_button}

    # Verify "Update started" toast notification appears immediately after confirming.
    # Toast message: "Wait for the firmware update notification before making any changes."
    Wait Until Element Is Visible  ${xpath_update_started_toast}  timeout=30s
    Page Should Contain  Update started
    Page Should Contain  Wait for the firmware update notification before making any changes.
    Log To Console  Update started toast verified.

    # Close the "Update started" toast notification to prevent interference with subsequent updates.
    Wait Until Element Is Visible  ${xpath_update_started_toast_close}  timeout=10s
    Click Element  ${xpath_update_started_toast_close}
    Wait Until Element Is Not Visible  ${xpath_update_started_toast}  timeout=10s
    Log To Console  Update started toast closed.

    # Verify "Verify update" toast notification appears after update completes.
    # Toast message: "Refresh the application to verify firmware updated successfully".
    Wait Until Element Is Visible  ${xpath_verify_update_toast}  timeout=600s
    Page Should Contain  Verify update
    Page Should Contain  Refresh the application to verify firmware updated successfully
    Log To Console  Verify update toast verified.

    # Close the "Verify update" toast notification to prevent interference with subsequent updates.
    Wait Until Element Is Visible  ${xpath_verify_update_toast_close}  timeout=10s
    Click Element  ${xpath_verify_update_toast_close}
    Wait Until Element Is Not Visible  ${xpath_verify_update_toast}  timeout=10s
    Log To Console  Verify update toast closed.

    # Click the Refresh button in the top right corner to refresh the UI and display updated firmware version.
    Wait Until Element Is Visible  ${xpath_refresh_button}  timeout=10s
    Click Element  ${xpath_refresh_button}
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Log To Console  UI refreshed.


Get Host Firmware Version
    [Documentation]  Get the host (BIOS) firmware version via Redfish FirmwareInventory.

    ${host_version}=  Redfish.Get Attribute
    ...  /redfish/v1/UpdateService/FirmwareInventory/bios_active  Version
    RETURN  ${host_version}


Verify Version On GUI
    [Documentation]  Verify that the given firmware version string is displayed on the Web UI.
    [Arguments]  ${version}

    # Description of argument(s):
    # version     Firmware version string expected to be visible on the page.

    Wait Until Keyword Succeeds  1 min  5 sec  Page Should Contain  ${version}


Verify Image Signature
    [Documentation]  Verify the SHA-256 signature of a firmware image file using openssl.
    [Arguments]  ${image}

    # Description of argument(s):
    # image     Name of the firmware image file to verify (e.g. MANIFEST, image-kernel,
    #           image-rofs, image-u-boot, image-rwfs).

    ${result}=  Run Process
    ...  openssl  dgst  -sha256  -verify  ${fw_verify_dir}/publickey
    ...  -signature  ${fw_verify_dir}/${image}.sig  ${fw_verify_dir}/${image}
    Should Contain  ${result.stdout}  Verified OK
    ...  msg=${image} signature verification failed: ${result.stdout}
    Log To Console  ${image}: ${result.stdout}
