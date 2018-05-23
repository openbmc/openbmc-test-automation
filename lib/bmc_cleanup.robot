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

    ${skip_list_string}=  Set Variable  cd ${cleanup_dir_path}
    :FOR  ${file}  IN  @{skip_list}
    \  ${skip_list_string}=   Set Variable  ${skip_list_string} && rm ${file}

    ${file_count1}  ${stderr}  ${rc}=  BMC Execute Command  find ${cleanup_dir_path} | wc -l
    BMC Execute Command  ${skip_list_string}

    ${file_count2}  ${stderrt}  ${rc}=  BMC Execute Command  find ${cleanup_dir_path} | wc -l
    Should Be True  ${file_count2} < ${file_count1}
    # Delete the directory if it is empty.
    Run Keyword If  ${file_count2} <= 1
    ...  BMC Execute Command  rm -r ${cleanup_dir_path}
