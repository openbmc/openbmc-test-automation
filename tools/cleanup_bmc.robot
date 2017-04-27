*** Settings ***
Documentation  Cleanup user patches from BMC.

Library    ../lib/gen_robot_keyword.py
Resource   ../lib/utils.robot
Resource   ../extended/obmc_boot_test_resource.robot

*** Variables ***

# User defined path to cleanup.
${CLEANUP_DIR_PATH}  ${EMPTY}
# List that holds space separated filepaths to skip from cleanup.
${SKIP_LIST}  ${EMPTY}
# Number of files before cleanup.
${file_count1}

*** Test Cases ***

Cleanup User Patches
    [Documentation]  Do the cleanup in cleanup directory path.

    Should Not Be Empty  ${CLEANUP_DIR_PATH}
    Open Connection And Log In
    Remove Files

*** Keywords ***

Remove Files
    [Documentation]  Remove leftover files in cleanup directory path.

    Should Not Be Empty  ${SKIP_LIST}
    @{skip_list}=  Set Variable  ${SKIP_LIST.split()}
    ${skip_list_string}=  Set Variable  ${EMPTY}
    :FOR  ${file}  IN  @{skip_list}
    \  ${skip_list_string}=   Set Variable  ${skip_list_string} ! -path "${file}"

    ${file_count1}=  Execute Command On BMC  find ${CLEANUP_DIR_PATH} | wc -l
    Set Global Variable  ${file_count1}
    Write  find ${CLEANUP_DIR_PATH} \\( ${skip_list_string} \\) | xargs rm
    Write  find ${CLEANUP_DIR_PATH} \\( ${skip_list_string} \\) | xargs rmdir
    ${file_count2}=  Execute Command On BMC  find ${CLEANUP_DIR_PATH} | wc -l

    Run Keyword If  ${file_count2} < ${file_count1}
    ...  Reboot And Verify

Reboot And Verify
    [Documentation]  Reboot BMC and verify cleanup.

    Run Key U  OBMC Boot Test \ OBMC Reboot (off)
    ${file_count2}=  Execute Command On BMC  find ${CLEANUP_DIR_PATH} | wc -l
    Should Be True  ${file_count2} < ${file_count1}
