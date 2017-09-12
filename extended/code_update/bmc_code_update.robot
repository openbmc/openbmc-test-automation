*** Settings ***
Documentation     Update the BMC code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v IMAGE_FILE_PATH:<path/*.tar>  bmc_code_update.robot

Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/dump_utils.robot

Test Teardown     Code Update Test Teardown

*** Variables ***

${QUIET}                          ${1}
${IMAGE_FILE_PATH}                ${EMPTY}
${ALTERNATE_IMAGE_FILE_PATH}      ${EMPTY}

*** Test Cases ***

REST BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via REST.
    [Tags]  REST_BMC_Code_Update
    [Setup]  Code Update Setup

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    OBMC Reboot (off)


Upload And Activate Multiple BMC Images
    [Documentation]  Upload another BMC image and verify that its state is
    ...              different from all others.
    [Tags]  Upload_And_Activate_Multiple_BMC_Images
    [Template]  Activate Image And Verify No Duplicate Priorities
    [Setup]  Upload And Activate Multiple BMC Images Setup

    # Image File Path              Image Purpose
    ${ALTERNATE_IMAGE_FILE_PATH}   ${VERSION_PURPOSE_BMC}


BMC Set Priority To Invalid Values
    [Documentation]  Attempt to set the priority of an image to an invalid
    ...              value and expect an error.
    [Tags]  BMC_Set_Priority_To_Invalid_Values
    [Template]  Set Priority To Invalid Value And Expect Error

    # Version Type              Priority
    ${SOFTWARE_PURPOSE_BMC}     ${-1}
    ${SOFTWARE_PURPOSE_BMC}     ${256}


Delete BMC Image
    [Documentation]  Delete a BMC image from the BMC flash chip.
    [Tags]  Delete_BMC_Image

    ${software_object}=  Get Non Running BMC Software Object
    Delete Image And Verify  ${software_object}  ${VERSION_PURPOSE_BMC}


*** Keywords ***

Upload And Activate Multiple BMC Images Setup
    [Documentation]  Check that the ALTERNATE_FILE_PATH variable is set.

    Should Not Be Empty  ${ALTERNATE_IMAGE_FILE_PATH}

Code Update Setup
    [Documentation]  Do code update test case setup.
    # - Clean up all existing BMC dumps.

    Delete All Dumps

Code Update Test Teardown
    [Documentation]  Do code update test case teardown.
    # 1. Collect FFDC if test case failed.
    # 2. Collect FFDC if test PASS but error log exists.

    FFDC On Test Case Fail
    Run Keyword If  '${TEST_STATUS}' == 'PASS'  Check Error And Collect FFDC
