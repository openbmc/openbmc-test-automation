*** Settings ***
Documentation  Cleanup user patches from BMC.

Library    ../lib/gen_robot_keyword.py
Resource   ../lib/utils.robot
Resource   ../extended/obmc_boot_test_resource.robot

*** Variables ***

# User defined path to cleanup.
${cleanup_dir_path}

*** Test Cases ***

Cleanup User Patches
    [Documentation]  Check leftover code and do the cleanup.

    Should Not Be Empty  ${cleanup_dir_path}
    Open Connection And Log In
    ${output}=  Execute Command  ls ${cleanup_dir_path} | wc -l
    Run Keyword If  ${output} != 1  Remove Files
    Run Key U  OBMC Boot Test \ OBMC Reboot (off)
    ${output}=  Execute Command  ls ${cleanup_dir_path} | wc -l
    Should Be Equal  ${output}  1

*** Keywords ***

Remove Files
    [Documentation]  Remove leftover files in ${PATH} except python libraries.

    Write  cd ${cleanup_dir_path}
    Write  ls | grep -v python2.7 | xargs rm -rf
