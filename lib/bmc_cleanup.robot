*** Settings ***
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot

*** Variables ***
# User defined path to do the cleanup.
${CLEANUP_DIR_PATH}  ${EMPTY}
# List that holds space separated filepaths to skip from cleanup.
${SKIP_LIST}  ${EMPTY}

*** Keywords ***


Cleanup Dir
    [Documentation]  Remove leftover files in cleanup directory path.
    [Arguments]      ${cleanup_dir_path}=${CLEANUP_DIR_PATH}
    ...              ${skip_list}=${SKIP_LIST}

    # Description of argument(s):
    # cleanup_dir_path  Directory path to do the cleanup.
    # skip_list  List of files to skip from cleanup.

    Should Not Be Empty  ${cleanup_dir_path}
    Should Not Be Empty  ${SKIP_LIST}
    Open Connection And Log In
    @{skip_list}=  Set Variable  ${skip_list.split()}
    ${skip_list_string}=  Set Variable  ${EMPTY}
    :FOR  ${file}  IN  @{skip_list}
    \  ${skip_list_string}=   Set Variable  ${skip_list_string} ! -path "${file}"

    ${file_count1}=  Execute Command On BMC  find ${cleanup_dir_path} | wc -l
    Set Global Variable  ${file_count1}
    Write  find ${cleanup_dir_path} \\( ${skip_list_string} \\) | xargs rm
    Write  find ${cleanup_dir_path} \\( ${skip_list_string} \\) | xargs rmdir
    ${file_count2}=  Execute Command On BMC  find ${cleanup_dir_path} | wc -l

    Run Keyword If  ${file_count2} < ${file_count1}
    ...  Reboot And Verify

Reboot And Verify
    [Documentation]  Reboot BMC and verify cleanup.
    [Arguments]      ${cleanup_dir_path}=${CLEANUP_DIR_PATH}

    # Description of argument(s):
    # cleanup_dir_path  Directory path to do the cleanup.

    OBMC Reboot (off)
    # Take SSH session post BMC reboot before executing command.
    Open Connection And Log In
    ${file_count2}=  Execute Command On BMC  find ${cleanup_dir_path} | wc -l
    Should Be True  ${file_count2} < ${file_count1}
