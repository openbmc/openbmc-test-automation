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
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/var_funcs.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

Force Tags               BMC_Code_Update

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_BMC_Code_Update

    ${image_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    Run Keyword If  not ${FORCE_UPDATE}
    ...  Activate Existing Firmware  ${image_version}
    Redfish Update Firmware

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    # Delete BMC dump and Error logs.
    Delete All BMC Dump
    Redfish Purge Event Log
    # Checking for file existence.
    Valid File Path  IMAGE_FILE_PATH


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

    Pass Execution  The existing ${image_version} firmware is now functional.


Get Image Priority
    [Documentation]  Get Current Image Priority.
    [Arguments]  ${image_version}

    # Description of argument(s):
    # image_version       The Fimware image version (e.g. ibm-v.x-xx).

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
    # image_version       The Fimware image version (e.g. ibm-v.x-xx).
    # software_inventory  Software inventory details.

    ${least_priority}=  Get Least Value Priority Image  ${VERSION_PURPOSE_BMC}
    ${cur_priority}=  Get Image Priority  ${image_version}
    Rprint Vars  least_priority  cur_priority

    Return From Keyword If  '${least_priority}' == ${cur_priority}
    Set Host Software Property
    ...  ${SOFTWARE_VERSION_URI}${software_inventory['image_id']}
    ...  Priority  ${least_priority}

    # Reboot BMC And Login
    Redfish OBMC Reboot (off)
    Redfish.Login


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.

    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Run Keyword And Ignore Error  Set ApplyTime  policy=OnReset
    Redfish Upload Image And Check Progress State
    Reboot BMC And Verify BMC Image
    ...  OnReset  start_boot_seconds=${state['epoch_seconds']}

