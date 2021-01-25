*** Settings ***
Documentation            Update firmware on a target MCU via Redifsh.

# Test Parameters:
# IMAGE_MCU_FILE_PATH    The path to the MCU image file.
#
# Firmware update states:
#     Enabled            Image is installed and either functional or active.
#     Disabled           Image installation failed or ready for activation.
#     Updating           Image installation currently in progress.

Resource                 ../lib/resource.robot
Resource                 ../lib/bmc_redfish_resource.robot
Resource                 ../lib/boot_utils.robot
Resource                 ../lib/openbmc_ffdc.robot
Resource                 ../lib/common_utils.robot
Resource                 ../lib/code_update_utils.robot
Resource                 ../lib/dump_utils.robot
Resource                 ../lib/logging_utils.robot
Resource                 ../lib/redfish_code_update_utils.robot
Resource                 ../lib/utils.robot
Library                  ../lib/gen_robot_valid.py
Library                  ../lib/tftp_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

Force Tags               Mcu_Code_Update

*** Test Cases ***

Redfish Mcu Code Update With ApplyTime OnReset
    [Documentation]  Update the firmaware image with ApplyTime of OnReset.
    [Tags]  Redfish_Mcu_Code_Update_With_ApplyTime_OnReset
    [Template]  Redfish Update Firmware

    # policy
    OnReset    ${IMAGE_MCU_FILE_PATH_0}


Redfish Mcu Code Update With ApplyTime Immediate
    [Documentation]  Update the firmaware image with ApplyTime of Immediate.
    [Tags]  Redfish_Mcu_Code_Update_With_ApplyTime_Immediate
    [Template]  Redfish Update Firmware

    # policy
    Immediate  ${IMAGE_MCU_FILE_PATH_1}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    # Checking for file existence.
    Valid File Path  IMAGE_MCU_FILE_PATH_0
    Valid File Path  IMAGE_MCU_FILE_PATH_1

    Redfish.Login
    Delete All BMC Dump
    Redfish Purge Event Log


Redfish Verify MCU Version
    [Documentation]  Verify that the version on the MCU is the same as the
    ...              version in the given image via Redfish.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    # Extract the version from the image tarball on our local system.
    ${tar_version}=  Get Version Tar  ${image_file_path}

    ${image_info}=  Get Software Inventory State By Version  ${tar_version}
    ${image_id}=  Get Image Id By Image Info  ${image_info}

    ${mcu_version}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Version

    Valid Value  mcu_version  valid_values=['${tar_version}']


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.
    [Arguments]  ${apply_time}  ${image_file_path}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    Redfish.Login

    Set ApplyTime  policy=${apply_time}

    Redfish Upload Image  /redfish/v1/UpdateService  ${image_file_path}
    Sleep  30s

    ${image_version}=  Get Version Tar  ${image_file_path}
    ${image_info}=  Get Software Inventory State By Version  ${image_version}
    ${image_id}=  Get Image Id By Image Info  ${image_info}

    Redfish.Login
    Redfish Verify MCU Version  ${image_file_path}


Get Image Id By Image Info
    [Documentation]  Get image ID from image_info.
    [Arguments]  ${image_info}

    [Return]  ${image_info["image_id"]}
