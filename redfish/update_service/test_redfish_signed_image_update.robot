*** Settings ***
Documentation            Redfish BMC/Host signed and unsigned code update
...  over BMC functional signed image.

# Test Parameters:
# IMAGE_FILE_PATH        The path to the BMC/Host image file.
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
Resource                 ../../extended/code_update/update_bmc.robot
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/var_funcs.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

*** Test Cases ***

Redfish Signed Code Update
    [Documentation]  BMC/Host signed code update over functional signed
    ...  image, when FieldMode is set enable.
    [Tags]  Redfish_Signed_Code_Update
    [Template]  Redfish Signed Firmware Update

    # Image File Path
    ${IMAGE_FILE_PATH}


Redfish Fail Unsigned Code Update
    [Documentation]  BMC/Host unsigned code update over functional signed
    ...  image, when Field Mode is set enable.
    [Tags]  Redfish_Fail_Unsigned_Code_Update
    [Template]  Redfish Unsigned Firmware Update

    # Image File Path
    ${IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Delete All BMC Dump
    Redfish Purge Event Log
    Valid File Path  IMAGE_FILE_PATH


Redfish Signed Firmware Update
    [Documentation]  Update the BMC/Host firmware via redfish interface.
    [Arguments]  ${IMAGE_FILE_PATH}

    # Description of argument(s):
    # IMAGE_FILE_PATH  The path to the image file.

    Verify BMC Signed Image And Feild Mode
    ${image_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Redfish Upload Image And Check Progress State  Immediate
    Redfish.Login
    ${image_info}=  Get Software Inventory State By Version  ${image_version}
    Run keyword If  'BMC update' == '${image_info["image_type"]}'
    ...    Reboot BMC And Verify BMC Image
    ...    Immediate  start_boot_seconds=${state['epoch_seconds']}
    ...  ELSE
    ...    Poweron Host And Verify Host Image


Redfish Unsigned Firmware Update
    [Documentation]  Update the BMC/Host firmware via redfish interface.
    [Arguments]  ${IMAGE_FILE_PATH}

    # Description of argument(s):
    # IMAGE_FILE_PATH  The path to the image file..

    Verify BMC Signed Image And Feild Mode
    Set ApplyTime  policy=Immediate
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${IMAGE_FILE_PATH}
    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id
    sleep  5s
    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Disabled', 'Updating', 'Disabled'  image_id=${image_id}
    Delete Software Object
    ...  /xyz/openbmc_project/software/${image_id}


Verify BMC Signed Image And Feild Mode
     [Documentation]  Verify BMC fucntional image is signed
     ...  and field mode is set to true.

    Verify BMC Signed Image
    Field Mode Should Be Enabled
    Print Timen  The functional firmware is signed and field mode is set.

