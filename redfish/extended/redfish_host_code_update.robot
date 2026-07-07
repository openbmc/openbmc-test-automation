*** Settings ***
Documentation            Update the BMC code on a target BMC via Redifsh.

# Test Parameters:
# HOST_IMAGE_FILE_PATH        The path to the BMC image file.
#
# Firmware update states:
#     Enabled            Image is installed and either functional or active.
#     Disabled           Image installation failed or ready for activation.
#     Updating           Image installation currently in progress.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/openbmc_ffdc.robot
Resource                 ../../lib/common_utils.robot
Resource                 ../../lib/code_update_utils.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Resource                 ../../lib/utils.robot
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/var_funcs.py
Library                  ../../lib/gen_robot_keyword.py
Library                  ../../lib/code_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

# Force the test to timedout to prevent test hanging.
Test Timeout             30 minutes

Test Tags                Host_Code_Update

*** Variables ***

# Overwrite BIOS firmware or not if same bios version is already present.
${BIOS_OVERWRITE}     ${True}

*** Test Cases ***

Redfish Host Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_Host_Code_Update

    ${image_version}=  Get Version Tar  ${HOST_IMAGE_FILE_PATH}
    Rprint Vars  image_version

    ${sw_inv}=  Get Functional Firmware  Host image
    ${functional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  True

    ${num_records}=  Get Length  ${functional_sw_inv}

    IF  ${num_records} != 0
        Pass Execution If  '${functional_sw_inv['version']}' == '${image_version}'
        ...  The existing ${image_version} firmware is already functional.
    END

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Print Timen  Performing firmware update ${image_version}.

    Redfish Update Firmware


Redfish Host Firmware Update Multipart
    [Documentation]  Update the Host (BIOS) firmware using update-multipart.
    [Tags]  Redfish_Host_Firmware_Update_Multipart

    Valid File Path  HOST_IMAGE_FILE_PATH
    Redfish Host Firmware Update Multipart  ${HOST_IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    # Delete BMC dump and Error logs.
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Purge Event Log
    # Checking for file existence.
    Valid File Path  HOST_IMAGE_FILE_PATH


Redfish Update Firmware
    [Documentation]  Update the Host firmware via redfish interface.

    Redfish.Login
    ${post_code_update_actions}=  Get Post Boot Action
    Rprint Vars  post_code_update_actions
    Run Keyword And Ignore Error  Set ApplyTime  policy=OnReset
    Redfish Upload Image And Check Progress State
    ${tar_version}=  Get Version Tar  ${HOST_IMAGE_FILE_PATH}
    ${image_info}=  Get Software Inventory State By Version  ${tar_version}
    Run Key  ${post_code_update_actions['${image_info["image_type"]}']['OnReset']}
    Redfish.Login
    Redfish Verify Host Version  ${IMAGE_FILE_PATH}


Redfish Host Firmware Update Multipart
    [Documentation]  Common flow for Host (BIOS) firmware update via update-multipart.
    ...              Used by single-image, multi-package, and partial-package test cases.
    ...              Steps: get current version → upload → poll task → verify version.
    [Arguments]  ${image_path}

    # Get current BIOS firmware version before update.
    ${status}  ${bios_ver_prev}=  Run Keyword And Ignore Error
    ...  Redfish.Get Attribute
    ...  /redfish/v1/UpdateService/FirmwareInventory/bios_active  Version
    ${bios_ver_prev}=  Set Variable If  '${status}' == 'PASS'  ${bios_ver_prev}  ${EMPTY}
    Print Timen  Current BIOS firmware version: ${bios_ver_prev}

    # Get target version from the tar file MANIFEST.
    ${image_version}=  code_update_utils.Get Version Tar  ${image_path}
    Rprint Vars  image_version  bios_ver_prev

    # Skip if already at target version (only if bios_active exists and matches).
    Pass Execution If
    ...    not ${BIOS_OVERWRITE}
    ...    and  '${bios_ver_prev}' != '${EMPTY}'
    ...    and '${bios_ver_prev}' == '${image_version}'
    ...  The existing ${image_version} BIOS firmware is already active and BIOS overwrite is ${BIOS_OVERWRITE}.

    Print Timen  Uploading ${image_path} via update-multipart (target: bios_active)...

    # The update-multipart endpoint returns a Task object with the task Id.
    ${upload_resp}=  Upload Multipart Image To BMC
    ...  /redfish/v1/UpdateService/update-multipart
    ...  ${image_path}
    ...  /redfish/v1/UpdateService/FirmwareInventory/bios_active

    # Validate the upload response contains a task.
    Should Not Be Empty  ${upload_resp}
    ...  msg=No task response returned from firmware upload.
    ${task_id}=  Evaluate  $upload_resp.get('Id') or $upload_resp.get('@odata.id', '').split('/')[-1]
    Should Not Be Empty  ${task_id}
    ...  msg=Could not determine task ID from upload response.
    Print Timen  Host firmware update task started: ${task_id}

    Wait Until Keyword Succeeds  10 min  5 sec
    ...  Verify Host Update Task Completed  ${task_id}
    Print Timen  Task ${task_id} completed successfully.

    # Verify new BIOS firmware version matches uploaded image.
    Verify BIOS Firmware Version  ${image_version}
    ${bios_ver_new}=  Redfish.Get Attribute
    ...  /redfish/v1/UpdateService/FirmwareInventory/bios_active  Version
    Print Timen  Updated BIOS firmware version: ${bios_ver_new}

    Run Keyword If  '${bios_ver_prev}' == '${EMPTY}'
    ...  Log To Console  BIOS firmware installed for the first time: ${bios_ver_new}.
    ...  ELSE IF  '${bios_ver_prev}' == '${bios_ver_new}'
    ...  Log To Console  WARNING: BIOS firmware version is still the same after update.
    ...  ELSE
    ...  Log To Console  BIOS firmware updated from ${bios_ver_prev} to ${bios_ver_new}.


Verify BIOS Firmware Version
    [Documentation]  Poll GET /redfish/v1/UpdateService/FirmwareInventory/bios_active
    ...              and verify the Version matches the expected image version.
    [Arguments]  ${expected_version}

    ${bios_ver}=  Redfish.Get Attribute
    ...  /redfish/v1/UpdateService/FirmwareInventory/bios_active  Version
    Should Be Equal  ${bios_ver}  ${expected_version}
    ...  msg=BIOS firmware version mismatch: expected ${expected_version}, got ${bios_ver}


Verify Host Update Task Completed
    [Documentation]  Poll GET /redfish/v1/TaskService/Tasks/<id> and verify
    ...              TaskState=Completed and TaskStatus=OK.
    ...              Fails immediately if task ends in an error state
    ...              (Cancelled, Killed, or Exception).
    [Arguments]  ${task_id}

    ${task_resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}
    ${task_state}=  Set Variable  ${task_resp.dict['TaskState']}
    ${task_status}=  Set Variable  ${task_resp.dict['TaskStatus']}

    Log To Console  Task ${task_id}: State=${task_state}, Status=${task_status}

    # Fail immediately if task ended in a terminal error state.
    Run Keyword If  '${task_state}' in ['Cancelled', 'Killed', 'Exception']
    ...  Fail  Task ${task_id} ended with error state: ${task_state} / ${task_status}

    Should Be Equal  ${task_state}  Completed
    ...  msg=Task ${task_id} not yet completed: state=${task_state}
    Should Be Equal  ${task_status}  OK
    ...  msg=Task ${task_id} completed with error status: ${task_status}
