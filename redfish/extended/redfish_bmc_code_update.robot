*** Settings ***
Documentation            Update the BMC code on a target BMC via Redifsh.

# Test Parameters:
# IMAGE_FILE_PATH        The path to the BMC image file.
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

Force Tags               Bmc_Code_Update

*** Variables ***

${FORCE_UPDATE}          ${0}
${LOOP_COUNT}            ${2}
${DELETE_ERRLOGS}        ${1}

${ACTIVATION_WAIT_TIMEOUT}     8 min

# New code update path.
${REDFISH_UPDATE_URI}    /redfish/v1/UpdateService/update

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_BMC_Code_Update

    # Python module:  get_version_tar(tar_file_path)
    ${image_version}=  code_update_utils.Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    # Python module: get_bmc_release_info()
    ${bmc_release_info}=  utils.Get BMC Release Info
    ${functional_version}=  Set Variable  ${bmc_release_info['version_id']}
    Rprint Vars  functional_version

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    # Check if the existing firmware is functional.
    Pass Execution If  '${functional_version}' == '${image_version}'
    ...  The existing ${image_version} firmware is already functional.

    ${sw_inv}=  Get Functional Firmware  BMC image
    ${nonfunctional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  False

    # Redfish active software image API.
    Run Keyword If  ${num_records} > 0
    ...  Run Keyword If  '${nonfunctional_sw_inv['version']}' == '${image_version}'
    ...  Set Backup Firmware To Functional  ${image_version}  ${state}

    Print Timen  Performing firmware update ${image_version}.

    Redfish Update Firmware


Redfish BMC Code Update Running And Backup Image With Same Firmware
    [Documentation]  Perform the firmware update with same image back to back, so that
    ...              the running (functional Image) and backup image (alternate image)
    ...              with same firmware.
    [Tags]  Redfish_BMC_Code_Update_Running_And_Backup_Image_With_Same_Firmware

    # Python module:  get_version_tar(tar_file_path)
    ${image_version}=  code_update_utils.Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    # Python module: get_bmc_release_info()
    ${bmc_release_info}=  utils.Get BMC Release Info
    ${functional_version}=  Set Variable  ${bmc_release_info['version_id']}
    Rprint Vars  functional_version

    # First update.
    Print Timen  Performing firmware update ${image_version}.
    Redfish Update Firmware

    # Second update.
    Print Timen  Performing firmware update ${image_version}.
    Redfish Update Firmware


Redfish Firmware Update Loop
    [Documentation]  Update the same firmware image in loop.
    [Tags]  Redfish_Firmware_Update_Loop
    [Template]  Redfish Firmware Update In Loop
    [Timeout]    NONE
    # Override default 30 minutes, Disabling timeout with NONE explicitly
    # else this test will fail for longer loop runs.

    ${LOOP_COUNT}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    # Delete BMC dump and Error logs.
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword If  ${DELETE_ERRLOGS} == ${1}
    ...   Run Keyword And Ignore Error  Redfish Purge Event Log
    # Checking for file existence.
    Valid File Path  IMAGE_FILE_PATH

    # Check and set the update path.
    # Old - /redfish/v1/UpdateService/
    # New - /redfish/v1/UpdateService/update
    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/update
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NOT_FOUND},${HTTP_METHOD_NOT_ALLOWED}]

    # If the method is not found, set update URI to old method.
    Run Keyword If  ${resp.status} == ${HTTP_NOT_FOUND}
    ...  Set Suite Variable  ${REDFISH_UPDATE_URI}  /redfish/v1/UpdateService

    Log To Console  Update URI: ${REDFISH_UPDATE_URI}

    Redfish Power Off  stack_mode=skip


Redfish Firmware Update In Loop
    [Documentation]  Update the firmware in loop.
    [Arguments]  ${update_loop_count}

    # Description of argument(s):
    # update_loop_count    This value is used to run the firmware update in loop.

    # Python module:  get_version_tar(tar_file_path)
    ${image_version}=  code_update_utils.Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    # Python module: get_bmc_release_info()
    ${bmc_release_info}=  utils.Get BMC Release Info
    ${functional_version}=  Set Variable  ${bmc_release_info['version_id']}
    Print Timen  Starting firmware information:
    Rprint Vars  functional_version

    ${temp_update_loop_count}=  Evaluate  ${update_loop_count} + 1

    FOR  ${count}  IN RANGE  1  ${temp_update_loop_count}
       Print Timen  **************************************
       Print Timen  * The Current Loop Count is ${count} of ${update_loop_count} *
       Print Timen  **************************************
       Print Timen  Performing firmware update ${image_version}.
       Redfish Update Firmware
    END


Delete BMC Image
    [Documentation]  Delete a BMC image from the BMC flash chip.

    ${software_object}=  Get Non Running BMC Software Object
    Delete Image And Verify  ${software_object}  ${VERSION_PURPOSE_BMC}


Activate Existing Firmware
    [Documentation]  Set firmware image to lower priority.
    [Arguments]  ${image_version}

    # Description of argument(s):
    # image_version     Version of image.

    ${software_inventory_record}=  Get Software Inventory State By Version
    ...  ${image_version}
    ${num_keys}=  Get Length  ${software_inventory_record}

    Rprint Vars  software_inventory_record

    # If no software inventory record was found, there is no existing
    # firmware for the given version and therefore no action to be taken.
    Return From Keyword If  not ${num_keys}

    # Check if the existing firmware is functional.
    Pass Execution If  ${software_inventory_record['functional']}
    ...  The existing ${image_version} firmware is already functional.

    # If existing firmware is not functional, then set the priority to least.
    Print Timen  The existing ${image_version} firmware is not yet functional.
    Set BMC Image Priority To Least  ${image_version}  ${software_inventory_record}

    Pass Execution  The existing ${image_version} firmware is now functional.


Get Image Priority
    [Documentation]  Get Current Image Priority.
    [Arguments]  ${image_version}

    # Description of argument(s):
    # image_version       The Firmware image version (e.g. 2.8.0-dev-1107-g512028d95).

    ${software_info}=  Read Properties
    ...  ${SOFTWARE_VERSION_URI}/enumerate  quiet=1
    # Get only the record associated with our image_version.

    ${software_info}=  Filter Struct
    ...  ${software_info}  [('Version', '${image_version}')]
    # Convert from dict to list.
    ${software_info}=  Get Dictionary Values  ${software_info}

    [Return]  ${software_info[0]['Priority']}


Set BMC Image Priority To Least
    [Documentation]  Set BMC image priority to least value.
    [Arguments]  ${image_version}  ${software_inventory}

    # Description of argument(s):
    # image_version       The Firmware image version (e.g. 2.8.0-dev-1107-g512028d95).
    # software_inventory  Software inventory details.

    ${least_priority}=  Get Least Value Priority Image  ${VERSION_PURPOSE_BMC}
    ${cur_priority}=  Get Image Priority  ${image_version}
    Rprint Vars  least_priority  cur_priority

    Return From Keyword If  '${least_priority}' == ${cur_priority}
    Set Host Software Property
    ...  ${SOFTWARE_VERSION_URI}${software_inventory['image_id']}
    ...  Priority  ${least_priority}

    Redfish OBMC Reboot (off)


Set Backup Firmware To Functional
    [Documentation]  Set the backup firmware to functional.
    [Arguments]  ${image_version}  ${state}

    # Description of argument(s):
    # image_version     Version of image.
    # state             Pre reboot state.

    Print Timen  Switch to back up and rebooting.
    Switch Backup Firmware Image To Functional
    Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}
    Pass Execution  The backup firmware image ${image_version} is now functional.


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Run Keyword And Ignore Error  Set ApplyTime  policy=OnReset

    # Python module:  get_member_list(resource_path)
    ${before_inv_list}=  redfish_utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    Log To Console   Current images on the BMC before upload: ${before_inv_list}

    Print Timen  Start uploading image to BMC.
    Redfish Upload Image  ${REDFISH_UPDATE_URI}  ${IMAGE_FILE_PATH}
    Print Timen  Completed image upload to BMC.

    # Python module:  get_member_list(resource_path)
    ${after_inv_list}=  redfish_utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    Log To Console  Current images on the BMC after upload: ${after_inv_list}

    ${image_id}=  Evaluate  set(${after_inv_list}) - set(${before_inv_list})
    Should Not Be Empty    ${image_id}
    ${image_id}=  Evaluate  list(${image_id})[0].split('/')[-1]
    Log To Console  Firmware installation in progress with image id:: ${image_id}

    Wait Until Keyword Succeeds  ${ACTIVATION_WAIT_TIMEOUT}  10 sec
    ...  Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}

    # Python module:  get_version_tar(tar_file_path)
    ${tar_version}=  code_update_utils.Get Version Tar  ${IMAGE_FILE_PATH}
    ${image_info}=  Get Software Inventory State By Version  ${tar_version}

    Run Key  ${post_code_update_actions['${image_info["image_type"]}']['OnReset']}
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}

