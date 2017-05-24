*** Settings ***
Documentation     Trigger code update to a target BMC.
...               Execution Method :
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v IMAGE_FILE_PATH:<path/*.tar>  code_update.robot
...
...               Code update method BMC
...               Update work flow sequence:
...                 - Upload image via REST
...                 - Verify that the file exist on the BMC
...                 - Check Software Activation status to be "Ready"
...                 - Set Requested Activation to "Active"
...                 - Wait for code update to complete
...                 - Verify the new version

Library           code_update.py
Library           ../test_uploadimage.py
Library           OperatingSystem
Variables         ../../data/variables.py
Resource          code_update_utils.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     Code Update Teardown

*** Variables ***

${QUIET}                          ${1}
${version_id}                     ${EMPTY}
${upload_dir_path}                /tmp/images/
${image_version}                  ${EMPTY}
${image_purpose}                  ${EMPTY}
${activation_state}               ${EMPTY}
${requested_state}                ${EMPTY}

*** Test Cases ***

Initiate PNOR Code Update With REST
    [Documentation]  Start a PNOR code update by downloading image via REST.
    [Tags]  Initiate_PNOR_Code_Update_With_REST

    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}
    ${IMAGE_VERSION}=  Get Version Tar  ${IMAGE_FILE_PATH}

    ${image_data}=  OperatingSystem.Get Binary File  ${IMAGE_FILE_PATH}
    Upload Image To BMC  /upload/image  data=${image_data}
    ${ret}=  Verify Image Upload
    Should Be True  True == ${ret}

    # Verify the image is 'READY' to be activated.
    ${activation_state}=  Get Activation State
    Should Be Equal As Strings  ${activation_state}  ${READY}

    # Request the image to be activated.
    ${args}=  Create Dictionary   data=${REQUESTED_ACTIVE}
    Write Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  RequestedActivation  data=${args}
    ${requested_state}=  Get Requested Activation State
    Should Be Equal As Strings  ${requested_state}  ${REQUESTED_ACTIVE}

    # Verify code update was successful and Activation state is Active.
    Wait For Activation State Change  ${ACTIVATING}
    ${activation_state}=  Get Activation State
    Should Be Equal As Strings  ${activation_state}  ${ACTIVE}

*** Keywords ***

Code Update Teardown
    [Documentation]  Log FFDC if test fails for debugging purposes.

    Open Connection And Log In
    Execute Command On BMC  rm -rf /tmp/images/*

    Close All Connections
    FFDC On Test Case Fail
