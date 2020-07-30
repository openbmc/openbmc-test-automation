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

Force Tags               BMC_Code_Update

*** Variables ***

${FORCE_UPDATE}          ${0}


*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_BMC_Code_Update

    ${image_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    ${bmc_release_info}=  Get BMC Release Info
    ${functional_version}=  Set Variable  ${bmc_release_info['version_id']}
    Rprint Vars  functional_version

    # Check if the existing firmware is functional.
    Pass Execution If  '${functional_version}' == '${image_version}'
    ...  The existing ${image_version} firmware is already functional.

    Run Keyword If  not ${FORCE_UPDATE}
    ...  Activate Existing Firmware  ${image_version}
    Redfish Update Firmware


Redfish Firmware Update Loop
    [Documentation]  Update the firmware image in loop.
    [Tags]  Redfish_Firmware_Update_Loop
    [Template]  Redfish Firmware Update In Range

    ${LOOP_COUNT}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    # Delete BMC dump and Error logs.
    Delete All BMC Dump
    Run Keyword And Ignore Error  Redfish Purge Event Log
    # Checking for file existence.
    Valid File Path  IMAGE_FILE_PATH


Redfish Firmware Update In Range
    [Documentation]  Update the firmware in range.
    [Arguments]  ${LOOP_COUNT}

    FOR  ${time}  IN RANGE  ${LOOP_COUNT}
      Redfish.Login
      Redfish Update Firmware
      ${sw_inv}=  Get Functional Firmware  BMC update
      ${non_sw_inv}=  Get Non Fucntional Firmware  ${sw_inv}  False
      Run Keyword If  ${non_sw_inv['functional']} == False
      ...  Activate Existing Firmware  ${non_sw_inv['version']}
      Redfish.Login
      ${sw_inv}=  Get Functional Firmware  BMC update
      ${non_sw_inv}=  Get Non Fucntional Firmware  ${sw_inv}  False
      #Redfish.Delete  /redfish/v1/UpdateService/FirmwareInventory/${non_sw_inv['image_id']}
      Delete BMC Image
    END


Get Functional Firmware
    [Documentation]
    [Arguments]  ${type}

    ${software_inventory}=  Get Software Inventory State
    ${bmc_inv}=  Get BMC Firmware  ${type}  ${software_inventory}
    [Return]  ${bmc_inv}


Get Non Fucntional Firmware
    [Documentation]
    [Arguments]  ${sw_inv}  ${value}

    ${resp}=  Filter Struct  ${sw_inv}  [('functional', ${value})]
    ${resp}=  Get Dictionary Values  ${resp}
    ${num_records}=  Get Length  ${resp}

    Return From Keyword If  ${num_records} == ${0}  ${EMPTY}

    [Return]  ${resp}[0]


Delete BMC Image
    [Documentation]  Delete a BMC image from the BMC flash chip.
    [Tags]  Delete_BMC_Image

    ${software_object}=  Get Non Running BMC Software Object
    Delete Image And Verify  ${software_object}  ${VERSION_PURPOSE_BMC}


Activate Existing Firmware
    [Documentation]  Set fimware image to lower priority.
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

    Print Timen  The existing ${image_version} firmware is now functional.


Get Image Priority
    [Documentation]  Get Current Image Priority.
    [Arguments]  ${image_version}

    # Description of argument(s):
    # image_version       The Fimware image version (e.g. 2.8.0-dev-1107-g512028d95).

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
    # image_version       The Fimware image version (e.g. 2.8.0-dev-1107-g512028d95).
    # software_inventory  Software inventory details.

    ${least_priority}=  Get Least Value Priority Image  ${VERSION_PURPOSE_BMC}
    ${cur_priority}=  Get Image Priority  ${image_version}
    Rprint Vars  least_priority  cur_priority

    Return From Keyword If  '${least_priority}' == ${cur_priority}
    Set Host Software Property
    ...  ${SOFTWARE_VERSION_URI}${software_inventory['image_id']}
    ...  Priority  ${least_priority}

    Redfish OBMC Reboot (off)


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

