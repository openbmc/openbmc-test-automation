*** Settings ***
Documentation            Update the BMC code on a target BMC via Redifsh in loop.

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

*** Variables ***
${dump_cmd_nvram}              hexdump -C /var/lib/pldm/PHYP-NVRAM -n 8192
${dump-cmd_cksum}              hexdump -C /var/lib/pldm/PHYP-NVRAM-CKSUM

${ACTIVATION_WAIT_TIMEOUT}     8 min

${LOOP_COUNT}                  1

*** Test Cases ***

Redfish BMC Firmware Update Loop
    [Documentation]  Update the firmware image in loop.
    [Tags]  Redfish_BMC_Firmware_Update_Loop

    ${temp_update_loop_count}=  Evaluate  ${LOOP_COUNT} + 1

    FOR  ${count}  IN RANGE  1  ${temp_update_loop_count}
      Redfish Power Off  stack_mode=skip
      Print Timen  **************************************
      Print Timen  * The Current Loop Count is ${count} of ${LOOP_COUNT} *
      Print Timen  **************************************

      Multiple Redfish Firmware Update
 
    END


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login

    # Delete BMC dump and Error logs.
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Purge Event Log

    # Checking for file existence.
    Valid File Path  FIRST_IMAGE_FILE_PATH
    Valid File Path  SECOND_IMAGE_FILE_PATH
    Valid File Path  THIRD_IMAGE_FILE_PATH

    Redfish Power Off  stack_mode=skip


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
    Print Timen  The backup firmware image ${image_version} is now functional.
    Redfish Power On  stack_mode=skip  quiet=1
    Redfish Power Off
    Capture Host Dump

    [Return]  True


Capture Host Dump
    [Documentation]  Run command to capture Host dump.

    ${run_cmd_list}=  Create List
    Append To List  ${run_cmd_list}  ${dump_cmd_nvram}
    Append To List  ${run_cmd_list}  ${dump-cmd_cksum}

    FOR  ${cmd}  IN  @{run_cmd_list}
      Log To Console  Initiating command to take hexdump logs
      ${stdout}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
      Run Keyword If  ${rc} == ${0}  Print Timen  Command ${cmd} successfully
      Log To Console  ${stdout}
      Log To Console  Logging complete for hexdump
    END


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Run Keyword And Ignore Error  Set ApplyTime  policy=OnReset

    # Python module:  get_member_list(resource_path)
    ${before_inv_list}=  redfish_utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    Log To Console   Current images on the BMC before upload: ${before_inv_list}

    Log To Console   Start uploading image to BMC.
    Redfish Upload Image  /redfish/v1/UpdateService  ${IMAGE_FILE_PATH}
    Log To Console   Completed image upload to BMC.

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


Multiple Redfish Firmware Update
    [Documentation]  Update the firmware image in user define loop.

    ${image_path_list}=  Create List
    Append To List  ${image_path_list}  ${FIRST_IMAGE_FILE_PATH}
    Append To List  ${image_path_list}  ${SECOND_IMAGE_FILE_PATH}
    Append To List  ${image_path_list}  ${THIRD_IMAGE_FILE_PATH}

    FOR  ${file_path}  IN  @{image_path_list}
      Log To Console  Install image : ${file_path}
      Set Global Variable  ${IMAGE_FILE_PATH}  ${file_path}
      Capture Host Dump

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

      ${status}=  Run Keyword If  '${functional_version}' == '${image_version}'
      ...  Run Keywords  Print Timen  The existing ${image_version} firmware is already functional.  AND
      ...  Set Test Variable  ${status}  ${True}

      # Check if the existing firmware is functional.
      Continue For Loop If  '${functional_version}' == '${image_version}'

      ${sw_inv}=  Get Functional Firmware  BMC image
      ${nonfunctional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  False

      # Redfish active software image API.
      ${image_status}=  Run Keyword If  ${num_records} > 0
      ...  Run Keyword If  '${nonfunctional_sw_inv['version']}' == '${image_version}'
      ...  Set Backup Firmware To Functional  ${image_version}  ${state}

      Continue For Loop If  '${True}' == '${image_status}'

      Print Timen  Performing firmware update ${image_version}.
      Redfish Update Firmware
      Redfish Power On  stack_mode=skip  quiet=1
      Redfish Power Off
      Capture Host Dump

    END

