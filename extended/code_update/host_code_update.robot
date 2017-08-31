*** Settings ***
Documentation     Update the PNOR code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v DELETE_OLD_PNOR_IMAGES:<"true" or "false">
...               -v IMAGE_FILE_PATH:<path/*.tar>  host_code_update.robot
...
...               Code update method BMC
...               Update work flow sequence:
...                 - Upload image via REST
...                 - Verify that the file exists on the BMC
...                 - Check that software "Activation" is set to "Ready"
...                 - Set "Requested Activation" to "Active"
...                 - Wait for code update to complete
...                 - Verify the new version

Library           ../../lib/bmc_ssh_utils.py
Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/state_manager.robot
Resource          ../../lib/dump_utils.robot

Test Teardown     FFDC On Test Case Fail

*** Variables ***

${QUIET}                          ${1}
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

    Run Keyword If  '${PREV_TEST_STATUS}' == 'FAIL'
    ...  Fail  Code update failed. No need to boot to OS.
    Start SOL Console Logging
    REST Power On


Host Image Priority Attribute Test
    [Documentation]  Set "Priority" attribute.
    [Tags]  Host_Image_Priority_Attribute_Test
    [Template]  Temporarily Set PNOR Attribute

    # Property        Value
    Priority          ${0}
    Priority          ${1}
    Priority          ${127}


Set RequestedActivation To None
    [Documentation]  Set the RequestedActivation of the image to None and
    ...              verify that it is in fact set to None.
    [Tags]  Set_RequestedActivation_To_None

    ${software_objects}=  Get Software Objects
    Set Host Software Property  @{software_objects}[0]  RequestedActivation
    ...  ${REQUESTED_NONE}
    ${software_properties}=  Get Host Software Property  @{software_objects}[0]
    Should Be Equal As Strings  &{software_properties}[RequestedActivation]
    ...  ${REQUESTED_NONE}


Set RequestedActivation And Activation To Invalid Value
    [Documentation]  Set the RequestedActivation and Activation propreties of
    ...              the image to an invalid value and verify that it was not
    ...              changed.
    [Template]  Set Property To Invalid Value And Verify No Change
    [Tags]  Set_RequestedActivation_And_Activation_To_Invalid_Value

    # Property              Version Type
    RequestedActivation     ${VERSION_PURPOSE_HOST}
    Activation              ${VERSION_PURPOSE_HOST}


Upload And Activate Multiple Host Images
    [Documentation]  Upload another PNOR image and verify that its state is
    ...              different from all others.
    [Tags]  Upload_And_Activate_Multiple_Host_Images
    [Template]  Activate Image And Verify No Duplicate Priorities
    [Setup]  Upload And Activate Multiple BMC Images Setup

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

Temporarily Set PNOR Attribute
    [Documentation]  Update the PNOR attribute value.
    [Arguments]  ${attribute_name}  ${attribute_value}

    # Description of argument(s):
    # attribute_name    Host software attribute name (e.g. "Priority").
    # attribute_value   Value to be written.

    ${image_ids}=  Get Software Objects
    ${init_host_properties}=  Get Host Software Property  ${image_ids[0]}
    ${initial_priority}=  Set Variable  ${init_host_properties["Priority"]}

    Set Host Software Property  ${image_ids[0]}  ${attribute_name}
    ...  ${attribute_value}

    ${cur_host_properties}=  Get Host Software Property  ${image_ids[0]}
    Should Be Equal As Integers  ${cur_host_properties["Priority"]}
    ...  ${attribute_value}

    # Revert to to initial value.
    Set Host Software Property
    ...  ${image_ids[0]}  ${attribute_name}  ${initial_priority}


Code Update Setup
    [Documentation]  Do code update test case setup.
    # 1. Clean up all existing BMC dumps.
    # 2. Clean up all currently install PNOR images.

    Delete All Dumps
    Run Keyword If  'true' == '${DELETE_OLD_PNOR_IMAGES}'
    ...  Delete All PNOR Images


Upload And Activate Multiple BMC Images Setup
    [Documentation]  Check that the ALTERNATE_FILE_PATH variable is set.

    Should Not Be Empty  ${ALTERNATE_IMAGE_FILE_PATH}


Get PNOR Extended Version
    [Documentation]  Return the PNOR extended version.
    [Arguments]  ${manifest_path}

    # Description of argument(s):
    # manifest_path  Path of the MANIFEST file
    #                (e.g. "/tmp/images/abc123/MANIFEST").

    ${version}= BMC Execute Command
    ...  grep extended_version= ${manifest_path}
    [return] ${version.split(",")}
