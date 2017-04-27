*** Settings ***
Documentation  Cleanup user patches from BMC.

Library    ../lib/gen_robot_keyword.py
Resource   ../lib/utils.robot
Resource   ../extended/obmc_boot_test_resource.robot

*** Variables ***

# User defined path to cleanup.
${CLEANUP_DIR_PATH}  ${EMPTY}
# String that holds space separated filepaths to skip from cleanup.
${skip_file_string}=  /run/initramfs/rw/cow/etc/  /run/initramfs/rw/cow/usr/lib/python2.7

*** Test Cases ***

Cleanup User Patches
    [Documentation]  Do the cleanup in ${CLEANUP_DIR_PATH}.

    Should Not Be Empty  ${CLEANUP_DIR_PATH}
    Open Connection And Log In
    Remove Files

Remove Files
    [Documentation]  Remove leftover files in ${CLEANUP_DIR_PATH}.

    @{skip_list}=  Split String  ${skip_file_string}
    ${list_length}=  Get Length  ${skip_list}

    Write  cd ${CLEANUP_DIR_PATH}
    Write  find $PWD | xargs -I {} bash -c 'array=(${skip_file_string});count=0;for file in \${array[@]}; do if [[ ($file != {}*) && ({} != $file*) ]]; then count=$((count+1));fi; done; if [ $count = ${list_length} ]; then rm -rf {}; fi'
    ${output}=  Execute Command  find $PWD | wc -l

    Run Key U  OBMC Boot Test \ OBMC Reboot (off)

    ${file_count}=  Execute Command  find ${CLEANUP_DIR_PATH}/$PWD | xargs -I {} bash -c 'array=(${skip_file_string});count=0;for file in \${array[@]}; do if [[ ($file != {}*) && ({} != $file*) ]]; then count=$((count+1));fi; done; if [ $count = ${list_length} ]; then echo {}; fi'|wc -l
    Should Be Equal  ${file_count}  0
