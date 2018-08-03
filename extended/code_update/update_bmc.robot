*** Settings ***
Documentation     Trigger code update to a target BMC.
...               Execution Method :
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v FILE_PATH:<path/*all.tar>  update_bmc.robot
...
...               Code update method BMC using REST
...               Update work flow sequence:
...                 - User input BMC File existence check
...                 - Ping Test and REST authentication
...                 - Set Host Power host setting Policy to ALWAYS_POWER_OFF
...                   On reboot this policy would ensure the BMC comes
...                   online and stays at HOST_POWERED_OFF state.
...                 - Issue poweroff
...                 - Prune archived journal logs
...                 - Prepare for Update
...                 - Wait for BMC to come online clean
...                 - Wait for BMC_READY state
...                 - Apply preserve BMC Network setting
...                 - SCP image to BMC
...                 - Activate the flash image
...                 - Warm Reset BMC to activate code
...                 - Wait for BMC to come online time out 30 minutes
...                 - Version check post update
...                 - Identify REST url post update

Library                 ../../lib/gen_robot_keyword.py
Library                 String

Resource                code_update_utils.robot
Resource                ../../lib/state_manager.robot
Resource                ../../lib/utils.robot
Resource                ../../lib/list_utils.robot
Resource                ../../lib/openbmc_ffdc.robot
Resource                ../../extended/obmc_boot_test_resource.robot
Resource                ../../lib/boot_utils.robot

Test Teardown           Run Key  FFDC On Test Case Fail

*** Variables ***

${QUIET}                ${1}
# Boot failures are not acceptable so we set the threshold to 0.
${boot_fail_threshold}  ${0}

${FILE_PATH}            ${EMPTY}
${FORCE_UPDATE}         ${0}
${REST_URL_FILE_PATH}   ${EMPTY}

# There are two reboots issued by code update.
${MAX_BOOT_COUNT}       ${2}

*** Test Cases ***

Initiate Code Update BMC
    [Documentation]  Initiate a code update on the BMC.
    [Tags]  Initiate_Code_Update_BMC

    ${status}=  Run Keyword If  '${LAST_KNOWN_GOOD_VERSION}' != '${EMPTY}'
    ...  Run Keyword And Return Status
    ...  Validate BMC Version  ${LAST_KNOWN_GOOD_VERSION}

    Run Keyword if  '${status}' == '${True}'
    ...  Pass Execution  The BMC already has the requested build loaded so no further action will be taken.

    # Enable user to bypass prerequisite operations.
    # Use cases for if BMC is not in working state.
    Run Keyword If  ${FORCE_UPDATE} == ${0}  Run Keywords
    ...  Prepare BMC For Update  AND
    ...  Smart Power Off

    Run Key U  Preserve BMC Network Setting
    Run Key  SCP Tar Image File To BMC \ ${FILE_PATH}
    Run Key  Activate BMC Flash Image
    Run Key U  OBMC Boot Test \ OBMC Reboot (off)
    Run Key U  Check Boot Count And Time
    Run Keyword If  ${BOOT_COUNT} == ${1}
    ...  Log  Boot time not updated by kernel.  level=WARN

*** Keywords ***

Prepare BMC For Update
    [Documentation]  Prerequisite operation before code update.
    Check Boot Count And Time
    Prune Journal Log
    Power Off Request
    Set BMC Power Policy  ALWAYS_POWER_OFF

    Prepare For Update
    Check If BMC is Up  20 min  10 sec
    Check Boot Count And Time

    Wait For BMC Ready

Check Boot Count And Time
    [Documentation]  Check for unexpected reboots.
    Set BMC Reset Reference Time
    Log To Console  \n Boot Count: ${BOOT_COUNT}
    Log To Console  \n Boot Time: ${BOOT_TIME}
    Run Keyword If  ${BOOT_COUNT} > ${MAX_BOOT_COUNT}
    ...  Log  Phantom Reboot!!! Unexpected reboot detected  level=WARN
