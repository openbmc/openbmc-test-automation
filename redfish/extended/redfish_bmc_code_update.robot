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

Force Tags               BMC_Code_Update

*** Variables ***

${FORCE_UPDATE}          ${0}
${LOOP_COUNT}            20

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_BMC_Code_Update

    ${image_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    ${bmc_release_info}=  Get BMC Release Info
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


Redfish Firmware Update Loop
    [Documentation]  Update the firmware image in loop.
    [Tags]  Redfish_Firmware_Update_Loop
    [Template]  Redfish Firmware Update In Loop

    ${LOOP_COUNT}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    # Delete BMC dump and Error logs.
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Purge Event Log
    # Checking for file existence.
    Valid File Path  IMAGE_FILE_PATH

    Redfish Power Off  stack_mode=skip


Redfish Firmware Update In Loop
    [Documentation]  Update the firmware in loop.
    [Arguments]  ${update_loop_count}

    # Description of argument(s):
    # update_loop_count    This value is used to run the firmware update in loop.

    ${before_image_state}=  Get BMC Functional Firmware
    ${temp_update_loop_count}=  Evaluate  ${update_loop_count} + 1

    FOR  ${count}  IN RANGE  1  ${temp_update_loop_count}
      Print Timen  **************************************
      Print Timen  * The Current Loop Count is ${count} of ${update_loop_count} *
      Print Timen  **************************************
      Redfish Update Firmware
      ${sw_inv}=  Get Functional Firmware  BMC update
      ${nonfunctional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  False
      Run Keyword If  ${nonfunctional_sw_inv['functional']} == False
      ...  Set BMC Image Priority To Least  ${nonfunctional_sw_inv['version']}  ${nonfunctional_sw_inv}
      Redfish.Login
      ${sw_inv}=  Get Functional Firmware  BMC update
      ${nonfunctional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  False
      Delete BMC Image
    END

    ${after_image_state}=  Get BMC Functional Firmware
    Valid Value  before_image_state["version"]  ['${after_image_state["version"]}']


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
    Redfish Upload Image And Check Progress State
    ${tar_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    ${image_info}=  Get Software Inventory State By Version  ${tar_version}
    Run Key  ${post_code_update_actions['${image_info["image_type"]}']['OnReset']}
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}

