*** Settings ***
Documentation    Updates

Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/state_manager.robot

Test Teardown     FFDC On Test Case Fail

*** Variables ***

${QUIET}                        ${1}
${IMAGE_FILE_PATH}              ${EMPTY}
${N_MINUS_ONE_IMAGE_FILE_PATH}  ${EMPTY}
${N_PLUS_ONE_IMAGE}             ${EMPTY}

*** Test Cases ***

Host_Multi Code Update
    [Documentation]  Do four code updates in a row. Update to N, N-1, N, and
    ...              then N+1.
    [Tags]  Host_Mult_Code_Update
    [Template]  Code Update And Power On Host
    [Setup]  Variable Check

    # Image File Path
    ${IMAGE_FILE_PATH}
    ${N_MINUS_ONE_IMAGE_FILE_PATH}
    ${IMAGE_FILE_PATH}
    ${N_PLUS_ONE_IMAGE_FILE_PATH}


*** Keywords ***

Variable Check
    [Documentation]  Checks that any required variables are set.

    Should Not Be Empty  ${IMAGE_FILE_PATH}
    Should Not Be Empty  ${N_MINUS_ONE_IMAGE_FILE_PATH}
    Should Not Be Empty  ${N_PLUS_ONE_IMAGE_FILE_PATH}

Code Update And Power On Host
    [Documentation]  Shutdown the host, update to the given image, and then
    ...              verify that the host is able to power on.
    [Arguments]  ${image_file_path}

    Initiate Host PowerOff
    Delete All PNOR Images
    Upload And Activate Image  ${image_file_path}
    REST Power On