*** Settings ***
Documentation     Code update to a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<bmc hostname>
...               -v OS_HOST:<os hostname>
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

*** Test Cases ***

REST PNOR Code Update
    [Documentation]  Do a PNOR code update by uploading image on BMC via REST.
    [Tags]  REST_PNOR_Code_Update

    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}
    ${IMAGE_VERSION}=  Get Version Tar  ${IMAGE_FILE_PATH}

    ${image_data}=  OperatingSystem.Get Binary File  ${IMAGE_FILE_PATH}
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

    Verify Host Boots To OS If Available


*** Keywords ***

Code Update Teardown
    [Documentation]  Do code update test case teardown.

    #TODO: Use the Delete interface instead once delivered
    Open Connection And Log In
    Execute Command On BMC  rm -rf /tmp/images/*

    Close All Connections
    FFDC On Test Case Fail

Get PNOR Extended Version
    [Documentation]  Return the PNOR extended version.
    ...              Description of arguments:
    ...              path  Path of the MANIFEST file
    [Arguments]      ${path}

    Open Connection And Log In
    ${version}= Execute Command On BMC
    ...  "grep \"extended_version=\" " + ${path}
    [return] ${version.split(",")}
