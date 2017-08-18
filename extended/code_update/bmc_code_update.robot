*** Settings ***
Documentation     Update the BMC code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v DELETE_OLD_PNOR_IMAGES:<"true" or "false">
...               -v IMAGE_FILE_PATH:<path/*.tar>
...               -v ALTERNATE_IMAGE_FILE_PATH:<path/*.tar>  code_update.robot

Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

*** Variables ***

${QUIET}                          ${1}
${upload_dir_path}                /tmp/images/
${IMAGE_FILE_PATH}                ${EMPTY}
${ALTERNATE_IMAGE_FILE_PATH}      ${EMPTY}

*** Test Cases ***

REST BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via REST.
    [Tags]  REST_BMC_Code_Update

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    # TODO: Switch OBMC Reboot (off) once it's fixed
    Trigger Warm Reset Via Reboot
    Check If BMC is Up
    Wait For BMC Ready


Upload And Activate Multiple BMC Images
    [Documentation]  Upload another BMC image and verify that its state is
    ...              different from all others.
    [Tags]  Upload_And_Activate_Multiple_BMC_Images
    [Template]  Activate Image And Verify No Duplicate Priorities

    # Image File Path              Image Purpose
    ${ALTERNATE_IMAGE_FILE_PATH}   ${VERSION_PURPOSE_BMC}


Delete BMC Image
    [Documentation]  Delete a BMC image from the BMC flash chip.
    [Tags]  Delete_BMC_Image

    ${software_object}=  Get Non Running BMC Software Object
    Delete Image And Verify  ${software_object}  ${VERSION_PURPOSE_BMC}
