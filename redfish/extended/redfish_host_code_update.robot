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
${FORCE_UPDATE}    ${0}

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
    [Documentation]  Perform Host firmware update via update-multipart API.
    [Arguments]  ${image_path}

    ${version_match}=  Compare Current Version And Image Version  ${image_path}  host
    IF  not ${FORCE_UPDATE} and ${version_match}
      Pass Execution    The existing BIOS firmware is already active and FORCE UPDATE is ${FORCE_UPDATE}.
    END
    Print Timen  Uploading ${image_path} via update-multipart (target: host)...

    # The update-multipart endpoint returns a Task object with the task Id.
    ${upload_resp}=  Update Multipart Image To BMC  ${image_path}  host

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

    ${bios_ver_new}=  Redfish Get Host Version
    Print Timen  Updated HOST firmware version: ${bios_ver_new}

    Redfish Verify Host Version  ${image_path}


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
