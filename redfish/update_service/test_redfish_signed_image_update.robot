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
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/var_funcs.py
Library                  ../../lib/gen_robot_keyword.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

Test Tags               Redfish_Signed_Image_Update

*** Variables ***

${ACTIVATION_WAIT_TIMEOUT}     8 min

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


REST Failure When Field Mode Set To Disable
    [Documentation]  Verify error while disabling field mode from enabled mode.
    [Tags]  REST_Failure_When_Field_Mode_Set_To_Disable  rest

    ${args}=  Create Dictionary  data=${0}
    ${resp}=  OpenBMC Post Request  ${SOFTWARE_VERSION_URI}attr/FieldModeEnabled  data=${args}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_METHOD_NOT_ALLOWED}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Valid File Path  IMAGE_FILE_PATH
    Enable Field Mode And Verify Unmount
    Redfish.Login
    Redfish Delete All BMC Dumps
    Redfish Purge Event Log


Redfish Signed Firmware Update
    [Documentation]  Update the BMC/Host firmware via redfish interface.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # IMAGE_FILE_PATH  The path to the image file.

    Field Mode Should Be Enabled
    ${image_version}=  Get Version Tar  ${image_file_path}

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Run Keyword And Ignore Error  Set ApplyTime  policy=OnReset

    # Python module:  get_member_list(resource_path)
    ${before_inv_list}=  redfish_utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    Log To Console   Current images on the BMC before upload: ${before_inv_list}

    # URI : /redfish/v1/UpdateService
    # "HttpPushUri": "/redfish/v1/UpdateService/update",

    ${redfish_update_uri}=  Get Redfish Update Service URI
    Redfish Upload Image  ${redfish_update_uri}  ${IMAGE_FILE_PATH}

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


Redfish Unsigned Firmware Update
    [Documentation]  Update the BMC/Host firmware via redfish interface.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # IMAGE_FILE_PATH  The path to the image file.

    Field Mode Should Be Enabled
    Set ApplyTime  policy=Immediate

    # URI : /redfish/v1/UpdateService
    # "HttpPushUri": "/redfish/v1/UpdateService/update",

    ${redfish_update_uri}=  Get Redfish Update Service URI
    Redfish Upload Image  ${redfish_update_uri}  ${image_file_path}
    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id
    Sleep  5s
    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Disabled', 'Updating', 'Disabled'  image_id=${image_id}
    Delete Software Object
    ...  /xyz/openbmc_project/software/${image_id}

