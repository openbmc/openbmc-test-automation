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
Resource          ../../lib/state_manager.robot
Resource          ../../lib/boot_utils.robot

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

REST PNOR Code Update
    [Documentation]  Do a PNOR code update by uploading image on BMC via REST.
    [Tags]  REST_PNOR_Code_Update
    [Setup]  Code Update Setup

    Upload And Activate Image  ${IMAGE_FILE_PATH}


Post Update Boot To OS
    [Documentation]  Boot the host OS
    [Tags]  Post_Update_Boot_To_OS

    REST Power On


Set Activation To Invalid
    # property  version_id     value

    Activation  ${version_id}  ${INVALID}

    [Documentation]  Set the Activation property of the image to invalid and
    ...              verify it was set.
    [Tags]  Set_Activation_To_Invalid
    [Template]  Set And Verify Property


Set Activation To Ready
    # property  verison_id     value

    Activation  ${version_id}  ${READY}

    [Documentation]  Set the Activation property of the image to ready and
    ...              verify it was set.
    [Tags]  Set_Activation_To_Ready
    [Template]  Set And Verify Property


Set Activation To Failed
    # property  version_id     value

    Activation  ${version_id}  ${FAILED}

    [Documentation]  Set the Activation property of the image to failed and
    ...              verify it was set.
    [Tags]  Set_Activation_To_Failed
    [Template]  Set And Verify Property


Set Activation To Invalid Value
    # property  version_id

    Activation  ${version_id}

    [Documentation]  Set the Activation property of the image to an invalid
    ...              setting and verify that it was not changed.
    [Tags]  Set_Activation_To_Invalid_Value
    [Template]  Set Property To Invalid Value And Verify No Change


Set RequestedActivation To None
    # property           version_id     value

    RequestedActivation  ${version_id}  ${REQUESTED_NONE}

    [Documentation]  Set the RequestedActivation of the image to None and
    ...              verify that it is set to None.
    [Tags]  Set_RequestedActivation_To_None
    [Template]  Set And Verify Property


Set RequestedActivation To Invalid Value
    # property           version_id

    RequestedActivation  ${version_id}

    [Documentation]  Set the RequestedActivation proprety of the image to an
    ...              invalid value and verify that it was not changed.
    [Tags]  Set_RequestedActivation_To_Invalid_Value
    [Template]  Set Property To Invalid Value And Verify No Change


*** Keywords ***

Code Update Setup
    [Documentation]  Do code update test case setup.

    Run Keyword If  'true' == '${DELETE_OLD_PNOR_IMAGES}'
    ...  Delete All PNOR Images


Code Update Teardown
    [Documentation]  Do code update test case teardown.

    #TODO: Use the Delete interface instead once delivered
    Open Connection And Log In
    Execute Command On BMC  rm -rf /tmp/images/*

    Close All Connections
    FFDC On Test Case Fail


Upload And Activate Image
    [Documentation]  Upload an image to the BMC and activate it with REST.
    [Arguments]  ${image_file_path}

    # This keyword will also set the ${image_version} global.
    #
    # Description of argument(s):
    # image_file_path  The path to the image file to upload and activate.

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


Get PNOR Extended Version
    [Documentation]  Return the PNOR extended version.
    [Arguments]  ${path}

    # Description of argument(s):
    # path  Path of the MANIFEST file.

    Open Connection And Log In
    ${version}= Execute Command On BMC
    ...  "grep \"extended_version=\" " + ${path}
    [return] ${version.split(",")}


Set And Verify Property
    [Documentation]  Set the given property of an image to the given
    ...              value and verify that it was actually set.
    [Arguments]  ${property}  ${version_id}  ${value}

    # Description of argument(s):
    # image_version     Version ID of the image generated by the BMC.
    # activation_value  Value to set the Activation property to.

    ${args}=  Create Dictionary  data=${value}
    Write Attribute  ${SOFTWARE_VERSION_URI}${version_id}  ${property}
    ...  data=${args}
    ${read_val}=  Read Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  ${property}
    Should Be Equal As Strings  ${read_val}  ${value}


Set Property To Invalid Value And Verify No Change
    [Documentation]  Set the given property of an image to an invalid value
    ...              and verify that the set operation failed and the property
    ...              value did not change.
    [Arguments]  ${property}  ${version_id}

    # Description of argument(s):
    # version_id  Version ID of the image generated by the BMC.

    ${prev_val}=  Read Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  ${property}
    ${args}=  Create Dictionary  data=foo
    Run Keyword And Expect Error  500 != 200
    ...  Write Attribute  ${SOFTWARE_VERSION_URI}${version_id}  Activation
    ...  data=${args}
    ${read_val}=  Read Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  ${property}
    Should Be Equal As Strings  ${read_val}  ${prev_val}
