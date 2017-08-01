*** Settings ***
Documentation     Code update to a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v DELETE_OLD_PNOR_IMAGES:<"true" or "false">
...               -v IMAGE_FILE_PATH:<path/*.tar>  code_update.robot
...
...               Code update method BMC
...               Update work flow sequence:
...                 - Upload image via REST
...                 - Verify that the file exists on the BMC
...                 - Check software "Activation" status to be "Ready"
...                 - Set "Requested Activation" to "Active"
...                 - Wait for code update to complete
...                 - Verify the new version

#TODO: Move test_uploadimage.py to lib/
Library           ../test_uploadimage.py
Library           code_update.py
Library           OperatingSystem
Variables         ../../data/variables.py
Resource          code_update_utils.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/code_update_utils.robot

Test Teardown     Code Update Teardown

*** Variables ***

${QUIET}                          ${1}
${version_id}                     ${EMPTY}
${upload_dir_path}                /tmp/images/
${image_version}                  ${EMPTY}
${image_purpose}                  ${EMPTY}
${activation_state}               ${EMPTY}
${requested_state}                ${EMPTY}
${IMAGE_FILE_PATH}                ${EMPTY}
${DELETE_OLD_PNOR_IMAGES}         false

*** Test Cases ***

REST Host Code Update
    [Documentation]  Do a PNOR code update by uploading image on BMC via REST.
    [Tags]  REST_Host_Code_Update
    [Setup]  Code Update Setup

    OperatingSystem.File Should Exist  ${image_file_path}
    ${image_version}=  Get Version Tar  ${image_file_path}

    ${image_data}=  OperatingSystem.Get Binary File  ${image_file_path}
    Upload Image To BMC  /upload/image  data=${image_data}
    ${ret}=  Verify Image Upload
    Should Be True  ${ret}

    # Verify the image is 'READY' to be activated.
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[Activation]  ${READY}

    # Request the image to be activated.
    ${args}=  Create Dictionary  data=${REQUESTED_ACTIVE}
    Write Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  RequestedActivation  data=${args}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[RequestedActivation]
    ...  ${REQUESTED_ACTIVE}

    # Verify code update was successful and Activation state is Active.
    Wait For Activation State Change  ${version_id}  ${ACTIVATING}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[Activation]  ${ACTIVE}

    Trigger Warm Reset Via Reboot
    Wait Until Keyword Succeeds  5 min  10 sec  Post Login Request


Post Update Boot To OS
    [Documentation]  Boot the host OS
    [Tags]  Post_Update_Boot_To_OS

    Run Keyword Unless  '${PREV_TEST_STATUS}' == 'PASS'
    ...  Fail  Code update failed. No need to boot to OS.
    REST Power On


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
    # Property

    RequestedActivation

    [Documentation]  Set the RequestedActivation proprety of the image to an
    ...              invalid value and verify that it was not changed.
    [Template]  Set Property To Invalid Value And Verify No Change
    [Tags]  Set_RequestedActivation_To_Invalid_Value


Set Activation To Invalid Value
    # Property

    Activation

    [Documentation]  Set the Activation proprety of the image to an invalid
    ...              value and verify that it was not changed.
    [Template]  Set Property To Invalid Value And Verify No Change
    [Tags]  Set_Activation_To_Invalid_Value


*** Keywords ***

Code Update Setup
    [Documentation]  Do code update test case setup.

    Run Keyword If  'true' == '${DELETE_OLD_PNOR_IMAGES}'
    ...  Delete All PNOR Images


Code Update Teardown
    [Documentation]  Do code update test case teardown.

    FFDC On Test Case Fail


Get PNOR Extended Version
    [Documentation]  Return the PNOR extended version.
    [Arguments]  ${path}

    # Description of argument(s):
    # path  Path of the MANIFEST file.

    Open Connection And Log In
    ${version}= Execute Command On BMC
    ...  "grep \"extended_version=\" " + ${path}
    [return] ${version.split(",")}


Set Property To Invalid Value And Verify No Change
    [Documentation]  Attempt to set a property and check that the value didn't
    ...              change.
    [Arguments]  ${property}

    # Description of argument(s):
    # property  The property to attempt to set.

    ${sw_objs}=  Get Software Objects
    ${prev_props}=  Get Host Software Property  @{sw_objs}[0]
    Run Keyword And Expect Error  500 != 200
    ...  Set Host Software Property  @{sw_objs}[0]  ${property}  foo
    ${cur_props}=  Get Host Software Property  @{sw_objs}[0]
    Should Be Equal As Strings  &{prev_props}[${property}]
    ...  &{cur_props}[${property}]
