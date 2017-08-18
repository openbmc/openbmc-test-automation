*** Settings ***
Documentation     Update the PNOR code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v DELETE_OLD_PNOR_IMAGES:<"true" or "false">
...               -v IMAGE_FILE_PATH:<path/*.tar>
...               -v ALTERNATE_IMAGE_FILE_PATH:<path/*.tar>  code_update.robot
...
...               Code update method BMC
...               Update work flow sequence:
...                 - Upload image via REST
...                 - Verify that the file exists on the BMC
...                 - Check software "Activation" status to be "Ready"
...                 - Set "Requested Activation" to "Active"
...                 - Wait for code update to complete
...                 - Verify the new version

Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../../lib/state_manager.robot

Test Teardown     FFDC On Test Case Fail

*** Variables ***

${QUIET}                          ${1}
${upload_dir_path}                /tmp/images/
${IMAGE_FILE_PATH}                ${EMPTY}
${DELETE_OLD_PNOR_IMAGES}         false
${ALTERNATE_IMAGE_FILE_PATH}      ${EMPTY}

*** Test Cases ***

REST Host Code Update
    [Documentation]  Do a PNOR code update by uploading image on BMC via REST.
    [Tags]  REST_Host_Code_Update
    [Setup]  Code Update Setup

    Upload And Activate Image  ${IMAGE_FILE_PATH}

    OBMC Reboot (off)


Post Update Boot To OS
    [Documentation]  Boot the host OS
    [Tags]  Post_Update_Boot_To_OS
    [Teardown]  Stop SOL Console Logging

    Run Keyword Unless  '${PREV_TEST_STATUS}' == 'PASS'
    ...  Fail  Code update failed. No need to boot to OS.
    Start SOL Console Logging
    REST Power On


Host Image Priority Attribute Test
    [Documentation]  Set "Priority" attribute.
    [Tags]  Host_Image_Priority_Attribute_Test
    [Template]  Set PNOR Attribute

    # Property        Value
    Priority          ${0}
    Priority          ${1}
    Priority          ${127}


Set RequestedActivation To None
    [Documentation]  Set the RequestedActivation of the image to None and
    ...              verify that it is in fact set to None.
    [Tags]  Set_RequestedActivation_To_None

    ${sw_objs}=  Get Software Objects
    Set Host Software Property  @{sw_objs}[0]  RequestedActivation
    ...  ${REQUESTED_NONE}
    ${sw_props}=  Get Host Software Property  @{sw_objs}[0]
    Should Be Equal As Strings  &{sw_props}[RequestedActivation]
    ...  ${REQUESTED_NONE}


Set RequestedActivation To Invalid Value
    [Documentation]  Set the RequestedActivation proprety of the image to an
    ...              invalid value and verify that it was not changed.
    [Template]  Set Property To Invalid Value And Verify No Change
    [Tags]  Set_RequestedActivation_To_Invalid_Value

    # Property              Version Type
    RequestedActivation     ${VERSION_PURPOSE_HOST}


Set Activation To Invalid Value
    [Documentation]  Set the Activation proprety of the image to an invalid
    ...              value and verify that it was not changed.
    [Template]  Set Property To Invalid Value And Verify No Change
    [Tags]  Set_Activation_To_Invalid_Value

    # Property  Version Type
    Activation  ${VERSION_PURPOSE_HOST}


Upload And Activate Multiple Host Images
    [Documentation]  Upload another PNOR image and verify that its state is
    ...              different from all others.
    [Tags]  Upload_And_Activate_Multiple_Host_Images
    [Template]  Activate Image And Verify No Duplicate Priorities

    # Image File Path              Image Purpose
    ${ALTERNATE_IMAGE_FILE_PATH}   ${VERSION_PURPOSE_HOST}


Delete Host Image
    [Documentation]  Delete a PNOR image from the BMC and PNOR flash chip.
    [Tags]  Delete_Host_Image
    [Setup]  Initiate Host PowerOff

    ${software_objects}=  Get Software Objects
    ...  version_type=${VERSION_PURPOSE_HOST}
    ${num_images}=  Get Length  ${software_objects}
    Should Be True  0 < ${num_images}
    ...  msg=There are no PNOR images on the BMC to delete.
    Delete Image And Verify  @{software_objects}[0]  ${VERSION_PURPOSE_HOST}


*** Keywords ***

Set PNOR Attribute
    [Documentation]  Update the attribute value.
    [Arguments]  ${attribute_name}  ${value}

    # Description of argument(s):
    # attribute_name   Host software attribute name (e.g. "Priority").
    # value            Value to be written.

    ${image_ids}=  Get Software Objects
    ${resp}=  Get Host Software Property  ${image_ids[0]}
    ${initial_value}=  Set Variable  ${resp["Priority"]}

    Set Host Software Property  ${image_ids[0]}  ${attribute_name}  ${value}

    ${resp}=  Get Host Software Property  ${image_ids[0]}
    Should Be Equal As Integers  ${resp["Priority"]}  ${value}

    # Revert to to initial value.
    Set Host Software Property
    ...  ${image_ids[0]}  ${attribute_name}  ${initial_value}


Code Update Setup
    [Documentation]  Do code update test case setup.

    Run Keyword If  'true' == '${DELETE_OLD_PNOR_IMAGES}'
    ...  Delete All PNOR Images


Get PNOR Extended Version
    [Documentation]  Return the PNOR extended version.
    [Arguments]  ${path}

    # Description of argument(s):
    # path  Path of the MANIFEST file.

    Open Connection And Log In
    ${version}= Execute Command On BMC
    ...  "grep \"extended_version=\" " + ${path}
    [return] ${version.split(",")}
