*** Settings ***
Documentation     Trigger code update to a target BMC.
...               Execution Method :
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v IMAGE_FILE_PATH:<path/*.tar>  code_update.robot
...
...               Code update method BMC
...               Update work flow sequence:
...                 - Download image via REST
...                 - Verify that the file exist on the BMC
...                 - Verify the dbus object gets created
...                 - Check Software Activation Object to be "Ready"
...                 - Set Requested Activation to "Active"
...                 - Wait for codeupdate to complete
...                 - Warm Reset BMC to activate code
...                 - Verify the new version matches the one on the image

Library           code_update.py
Library           ../../lib/gen_robot_keyword.py
Library           ../test_uploadimage.py
Library           String
Library           Collections
Library           String
Library           OperatingSystem
Variables         ../../data/variables.py
Resource          code_update_utils.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown  Code Update Teardown

*** Variables ***

${QUIET}                          ${1}
${VERSION_ID}                     ${EMPTY}
${UPLOAD_DIR_PATH}                /tmp/images/
${IMAGE_VERSION}                  ${EMPTY}
${IMAGE_PURPOSE}                  ${EMPTY}
${ACTIVATION_STATE}               ${EMPTY}
${ACTIVATION_STATE}               ${EMPTY}
${REQUESTED_STATE}                ${EMPTY}

*** Test Cases ***

Initiate PNOR_Code Update With REST Image Upload
    [Documentation]  Start a PNOR code update by downloading image via REST
    [Tags]  Initiate_PNOR_Code_Update_With_REST_Image_Upload

    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}
    ${IMAGE_VERSION}=  Get Version Tar  ${IMAGE_FILE_PATH}

    ${image_data}=  OperatingSystem.Get Binary File  ${IMAGE_FILE_PATH}
    Upload Post Request  /upload/image  data=${image_data}
    ${ret}=  Verify Image Upload
    Should Be True  True == ${ret}

    # Verify the image is 'READY' to be activated
    ${ACTIVATION_STATE}=  Get Activation State
    Should Be Equal As Strings  ${ACTIVATION_STATE}  ${READY}

    # Request the image to be activated
    ${args}=  Create Dictionary   data=${REQUESTED_ACTIVE}
    Write Attribute  ${SOFTWARE_VERSION_URI}${VERSION_ID}
    ...  RequestedActivation  data=${args}
    ${REQUESTED_STATE}=  Get Requested Activation State
    Should Be Equal As Strings  ${REQUESTED_STATE}  ${REQUESTED_ACTIVE}

    # Verify code update was successful and Activation is Active
    Wait For Activation State Change  ${ACTIVATING}
    ${ACTIVATION_STATE}=  Get Activation State
    Should Be Equal As Strings  ${ACTIVATION_STATE}  ${ACTIVE}

*** Keywords ***

Code Update Teardown
    [Documentation]  Log FFDC if test suite fails and collect SOL log for
    ...              debugging purposes.

    Open Connection And Log In
    Execute Command On BMC  rm -f /tmp/images/*

    Close All Connections
    FFDC On Test Case Fail
