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

Library           ../../lib/code_update_utils.py
Library           OperatingSystem
Library           String
Variables         ../../data/variables.py
Resource          code_update_utils.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/code_update_utils.robot
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
${DELETE_OLD_PNOR_IMAGES}         false

*** Test Cases ***

REST Host Code Update
    [Documentation]  Do a PNOR code update by uploading image on BMC via REST.
    [Tags]  REST_Host_Code_Update
    [Setup]  Code Update Setup

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


Delete Host Image
    [Documentation]  Delete a PNOR image from the PNOR flash chip.
    [Tags]  Delete_Host_Image
    [Setup]  Initiate Host PowerOff

    ${software_objects}=  Get Software Objects
    ...  version_type=${VERSION_PURPOSE_HOST}
    ${num_images}=  Get Length  ${software_objects}
    Should Be True  0 < ${num_images}
    ...  msg=There are no PNOR images on the BMC to delete.
    Delete Image And Verify  @{software_objects}[0]  ${VERSION_PURPOSE_HOST}


Delete BMC Image
    [Documentation]  Delete a BMC image from the BMC flash chip.
    [Tags]  Delete_BMC_Image

    ${software_object}=  Get Non Running BMC Software Object
    Delete Image And Verify  ${software_object}  ${VERSION_PURPOSE_BMC}


*** Keywords ***

Code Update Setup
    [Documentation]  Do code update test case setup.

    Run Keyword If  'true' == '${DELETE_OLD_PNOR_IMAGES}'
    ...  Delete All PNOR Images

Code Update Teardown
    [Documentation]  Do code update test case teardown.

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

Delete Image And Verify
    [Documentation]  Delete an image from the BMC and verify that it was
    ...              removed from software and the /tmp/images directory.
    [Arguments]  ${software_object}  ${version_type}

    # Description of argument(s):
    # software_object        The URI of the software object to delete.
    # version_type  The type of the software object, e.g.
    #               xyz.openbmc_project.Software.Version.VersionPurpose.Host
    #               or xyz.openbmc_project.Software.Version.VersionPurpose.BMC.

    # Delete the image.
    Delete Software Object  ${software_object}
    # TODO: If/when we don't have to delete twice anymore, take this out
    Run Keyword And Continue On Failure
    ...  Delete Software Object  ${software_object}

    # Verify that it's gone from software.
    ${software_objects}=  Get Software Objects  version_type=${version_type}
    Should Not Contain  ${software_objects}  ${software_object}

    # Check that there is no file in the /tmp/images directory.
    ${image_id}=  Fetch From Right  ${software_object}  /
    BMC Execute Command
    ...  [ ! -d "/tmp/images/${image_id}" ]