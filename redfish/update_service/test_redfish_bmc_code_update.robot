*** Settings ***
Documentation            Update firmware on a target BMC via Redifsh.

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
Resource                 ../../lib/dump_utils.robot
Resource                 ../../lib/logging_utils.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/tftp_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

Force Tags               BMC_Code_Update

*** Test Cases ***

Redfish Code Update With ApplyTime OnReset
    [Documentation]  Update the firmaware image with ApplyTime of OnReset.
    [Tags]  Redfish_Code_Update_With_ApplyTime_OnReset
    [Template]  Redfish Update Firmware

    # policy
    OnReset


Redfish Code Update With ApplyTime Immediate
    [Documentation]  Update the firmaware image with ApplyTime of Immediate.
    [Tags]  Redfish_Code_Update_With_ApplyTime_Immediate
    [Template]  Redfish Update Firmware

    # policy
    Immediate


Redfish Code Update With Multiple Firmware
    [Documentation]  Update the firmaware image with ApplyTime of Immediate.
    [Tags]  Redfish_Code_Update_With_Multiple_Firmware
    [Template]  Redfish Multiple Upload Image And Check Progress State

    # policy   image_file_path     alternate_image_file_path
    Immediate  ${IMAGE_FILE_PATH}  ${ALTERNATE_IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Valid File Path  IMAGE_FILE_PATH
    Redfish.Login
    Delete All BMC Dump
    Redfish Purge Event Log


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.
    [Arguments]  ${apply_time}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Redfish Upload Image And Check Progress State  ${apply_time}
    Reboot BMC And Verify BMC Image
    ...  ${apply_time}  start_boot_seconds=${state['epoch_seconds']}


Redfish Multiple Upload Image And Check Progress State
    [Documentation]  Update multiple BMC firmware via redfish interface and check status.
    [Arguments]  ${apply_time}  ${IMAGE_FILE_PATH}  ${ALTERNATE_IMAGE_FILE_PATH}

    # Description of argument(s):
    # apply_time                 ApplyTime allowed values (e.g. "OnReset", "Immediate").
    # IMAGE_FILE_PATH            The path to BMC image file.
    # ALTERNATE_IMAGE_FILE_PATH  The path to alternate BMC image file.

    Valid File Path  ALTERNATE_IMAGE_FILE_PATH
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Set ApplyTime  policy=${apply_time}
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id
    Sleep  5s
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${ALTERNATE_IMAGE_FILE_PATH}

    ${alter_image_id}=  Get Latest Image ID
    Rprint Vars  alter_image_id

    Check Image Update Progress State
    ...  match_state='Updating', 'Disabled'  image_id=${alter_image_id}

    Check Image Update Progress State
    ...  match_state='Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Enabled'  image_id=${image_id}
    Reboot BMC And Verify BMC Image  ${apply_time}  start_boot_seconds=${state['epoch_seconds']}

