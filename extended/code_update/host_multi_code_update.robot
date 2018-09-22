*** Settings ***
Documentation    Verify that the host boots between code updates of different
...              PNOR version. Verify with N, the current version, downgrade
...              and verify with N-1, update and verify N again, and finally
...              update and verify with N+1.

Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot

Suite Setup       Suite Setup Execution

Test Teardown     FFDC On Test Case Fail

*** Variables ***

${QUIET}                        ${1}
${IMAGE_FILE_PATH}              ${EMPTY}
${N_MINUS_ONE_IMAGE_FILE_PATH}  ${EMPTY}
${N_PLUS_ONE_IMAGE_FILE_PATH}   ${EMPTY}

*** Test Cases ***

Host Multi Code Update
    [Documentation]  Do four code updates in a row. Update to N, N-1, N, and
    ...              then N+1.
    [Tags]  Host_Multi_Code_Update
    [Template]  Code Update And Power On Host

    # Image File Path
    ${IMAGE_FILE_PATH}
    ${N_MINUS_ONE_IMAGE_FILE_PATH}
    ${IMAGE_FILE_PATH}
    ${N_PLUS_ONE_IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Should Not Be Empty  ${IMAGE_FILE_PATH}  msg=Must set IMAGE_FILE_PATH.
    Should Not Be Empty  ${N_MINUS_ONE_IMAGE_FILE_PATH}
    ...  msg=Must set N_MINUS_ONE_IMAGE_FILE_PATH.
    Should Not Be Empty  ${N_PLUS_ONE_IMAGE_FILE_PATH}
    ...  msg=N_PLUS_ONE_IMAGE_FILE_PATH.
    Should Not Be Empty  ${OS_HOST}  msg=Must set OS_HOST.
    Should Not Be Empty  ${OS_USERNAME}  msg=Must set OS_USERNAME.
    Should Not Be Empty  ${OS_PASSWORD}  msg=Must set OS_PASSWORD.


Code Update And Power On Host
    [Documentation]  Shutdown the host, update to the given image, and then
    ...              verify that the host is able to power on.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the host image file.

    REST Power Off  stack_mode=skip  quiet=${1}
    Delete All PNOR Images
    Upload And Activate Image  ${image_file_path}
    REST Power On
