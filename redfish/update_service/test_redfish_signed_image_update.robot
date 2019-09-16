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
    ...  image, when FieldMode is set to true value.
    [Tags]  Redfish_Signed_Code_Update
    [Template]  Redfish Signed Firmware Update

    # image_file_path
    ${IMAGE_FILE_PATH}


Redfish Fail Unsigned Code Update
    [Documentation]  BMC/Host unsigned code update over functional signed
    ...  image, when Field Mode is set to true to value.
    [Tags]  Redfish_Fail_Unsigned_Code_Update
    [Template]  Redfish Unsigned Firmware Update

    # image_file_path
    ${IMAGE_FILE_PATH}


REST Field Mode Disable Fail
    [Documentation]  Un-able to set field mode value to false, if field mode value is set to true.
    [Tags]  REST_Field_Mode_Disable_Fail

    ${field_mode_status}=  Run Keyword and Return Status  Field Mode Should Be Enabled
    Run Keyword If  '${field_mode_status}' == 'True'
    ...  Run Keyword
    ...   REST Disable Field Mode
    ...  ELSE
    ...    Run Keywords
    ...      Enable Field Mode And Verify Unmount  AND
    ...      Field Mode Should Be Enabled  AND
    ...      REST Disable Field Mode


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Valid File Path  IMAGE_FILE_PATH
    Redfish.Login
    Delete All BMC Dump
    Redfish Purge Event Log


Redfish Signed Firmware Update
    [Documentation]  Update the BMC/Host firmware via redfish interface.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # IMAGE_FILE_PATH  The path to the image file.

    Field Mode Should Be Enabled
    ${image_version}=  Get Version Tar  ${image_file_path}
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Redfish Upload Image And Check Progress State  Immediate
    ${image_info}=  Get Software Inventory State By Version  ${image_version}
    Run Keyword If  'BMC update' == '${image_info["image_type"]}'
    ...    Reboot BMC And Verify BMC Image  Immediate  start_boot_seconds=${state['epoch_seconds']}
    ...  ELSE
    ...    Poweron Host And Verify Host Image


Redfish Unsigned Firmware Update
    [Documentation]  Update the BMC/Host firmware via redfish interface.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # IMAGE_FILE_PATH  The path to the image file.

    Field Mode Should Be Enabled
    Set ApplyTime  policy=Immediate
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${image_file_path}
    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id
    Sleep  5s
    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Disabled', 'Updating', 'Disabled'  image_id=${image_id}
    Delete Software Object
    ...  /xyz/openbmc_project/software/${image_id}


REST Disable Field Mode
    [Documentation]  Failed to set field mode value to False.

    ${args}=  Create Dictionary  data=${0}
    ${resp}=  OpenBMC Post Request  ${SOFTWARE_VERSION_URI}attr/FieldModeEnabled  data=${args}    
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_METHOD_NOT_ALLOWED}

