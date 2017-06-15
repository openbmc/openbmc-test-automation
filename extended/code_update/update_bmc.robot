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
...                 - Set Host Power host setting Policy to RESTORE_LAST_STATE
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
Resource                ../../lib/boot/boot_resource_master.robot
Resource                ../../lib/state_manager.robot
Resource                ../../lib/utils.robot
Resource                ../../lib/list_utils.robot
Resource                ../../lib/openbmc_ffdc.robot
Resource                ../../extended/obmc_boot_test_resource.robot

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

Test Basic BMC Performance Before Code Update
    [Documentation]   Check performance of memory, CPU & file system of BMC.
    [Tags]  Test_Basic_BMC_Performance_Before_Code_Update
    Open Connection And Log In
    Check BMC CPU Performance
    Check BMC Mem Performance
    Check BMC File System Performance

Check Core Dump Exist Before Code Update
    [Documentation]  Check core dump existence on BMC before code update.
    [Tags]  Check_Core_Dump_Exist_Before_Code_Update
    Check For Core Dumps

Check URLs Before Code Update
    [Documentation]  Check available URLs before code update.
    [Tags]  Check_URLs_Before_Code_Update

    ${url_list}=  Get URL List  ${OPENBMC_BASE_URI}
    Set Global Variable  ${URL_BEFORE_CU}  ${url_list}

    ${bmc_version}=  Get BMC Version
    Set Suite Variable  ${bmc_version_before}  ${bmc_version}

Initiate Code Update BMC
    [Documentation]  Initiate a code update on the BMC.
    [Tags]  Initiate_Code_Update_BMC

    # TODO: Disabling version check until new logic are in place.
    # ${status}=   Run Keyword and Return Status
    # ...   Validate BMC Version   before

    # Run Keyword if  '${status}' == '${False}'
    # ...     Pass Execution   Same Driver version installed

    # Enable user to bypass prerequisite operations.
    # Use cases for if BMC is not in working state.
    Run Keyword If  ${FORCE_UPDATE} == ${0}
    ...  Prepare BMC For Update

    Run Key U  Preserve BMC Network Setting
    Run Key  SCP Tar Image File To BMC \ ${FILE_PATH}
    Run Key  Activate BMC Flash Image
    Run Key U  OBMC Boot Test \ OBMC Reboot (off)
    Run Key U  Check Boot Count And Time
    Run Keyword If  ${BOOT_COUNT} == ${1}
    ...  Log  Boot time not updated by kernel.  level=WARN

Install BMC Debug Tarball
    [Documentation]  Install the downloaded debug tarball on BMC.
    [Tags]  Install_BMC_Debug_Tarball
    Run Keyword If  '${DEBUG_TARBALL_PATH}' != '${EMPTY}'
    ...  Install Debug Tarball On BMC  ${DEBUG_TARBALL_PATH}

Compare URLs Before And After Code Update
    [Documentation]  Compare URLs before and after code update.
    [Tags]  Compare_URLs_Before_And_After_Code_Update

    ${bmc_version}=  Get BMC Version
    Set Suite Variable  ${bmc_version_after}  ${bmc_version}

    # Exit test for same firmware version.
    Pass Execution If  '${bmc_version_before}' == '${bmc_version_after}'
    ...  Same BMC firmware version found

    ${url_after_cu}=  Get URL List  ${OPENBMC_BASE_URI}
    Compare URL List After Code Update  ${URL_BEFORE_CU}  ${url_after_cu}

Test Basic BMC Performance At Ready State
    [Documentation]   Check performance of memory, CPU & file system of BMC.
    [Tags]  Test_Basic_BMC_Performance_At_Ready_State
    Open Connection And Log In
    Check BMC CPU Performance
    Check BMC Mem Performance
    Check BMC File System Performance

Check Core Dump Exist After Code Update
    [Documentation]  Check core dump existence on BMC after code update.
    [Tags]  Check_Core_Dump_Exist_After_Code_Update
    Check For Core Dumps

Enable Core Dump File Size To Be Unlimited
    [Documentation]  Set core dump file size to unlimited.
    [Tags]  Enable_Core_Dump_File_size_To_Be_unlimited
    Set Core Dump File Size Unlimited

*** Keywords ***

Prepare BMC For Update
    [Documentation]  Prerequisite operation before code update.
    Check Boot Count And Time
    Prune Journal Log
    Power Off Request
    Set Policy Setting   RESTORE_LAST_STATE
    Prepare For Update
    Check If BMC is Up  20 min  10 sec
    Check Boot Count And Time

    # Temporary fix for lab migration for driver which is booted with
    # BMC state "/xyz/openbmc_project/state/BMC0/".
    ${status}=  Run Keyword And Return Status  Temp BMC URI Check
    Run Keyword If  '${status}' == '${False}'
    ...  Wait For BMC Ready
    ...  ELSE  Wait For Temp BMC Ready

    # TODO: openbmc/openbmc#815
    Sleep  1 min


Check Boot Count And Time
    [Documentation]  Check for unexpected reboots.
    Set BMC Reset Reference Time
    Log To Console  \n Boot Count: ${BOOT_COUNT}
    Log To Console  \n Boot Time: ${BOOT_TIME}
    Run Keyword If  ${BOOT_COUNT} > ${MAX_BOOT_COUNT}
    ...  Log  Phantom Reboot!!! Unexpected reboot detected  level=WARN

Temp BMC URI Check
    [Documentation]  Check for transient "BMC0" interface.
    ${resp}=  Openbmc Get Request  /xyz/openbmc_project/state/BMC0/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Check Temp BMC State
    [Documentation]  BMC state should be "Ready".
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  /xyz/openbmc_project/state/BMC0/  CurrentBMCState
    Should Be Equal  Ready  ${state.rsplit('.', 1)[1]}

Wait For Temp BMC Ready
    [Documentation]  Check for BMC "Ready" until timedout.
    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Check Temp BMC State

Compare URL List After Code Update
    [Documentation]  Compare URL list before and after code update.
    [Arguments]  ${url_before_cu}  ${url_after_cu}
    # Description of arguments:
    # url_before_cu  List of URLs available before code update.
    # url_after_cu   List of URLs available after code update.

    ${url_removed_list}=  Subtract Lists  ${url_before_cu}  ${url_after_cu}
    ${url_added_list}=  Subtract Lists  ${url_after_cu}  ${url_before_cu}
    Log  ${url_removed_list}
    Log  ${url_added_list}

    Return From Keyword If  '${REST_URL_FILE_PATH}' == '${EMPTY}'

    # Create file with BMC firmware version before and after code update.
    # i.e. <Before_Version>--<After_Version>
    # Example v1.99.6-141-ge662190--v1.99.6-141-ge664242

    ${file_name}=  Catenate  SEPARATOR=--
    ...  ${bmc_version_before}  ${bmc_version_after}
    ${REST_URL_FILE}=  Catenate  ${REST_URL_FILE_PATH}/${file_name}
    Create File  ${REST_URL_FILE}  URL Removed${\n}

    Return From Keyword If
    ...  ${url_removed_list} == [] and ${url_added_list} == []

    Create File  ${REST_URL_FILE}  URL Removed${\n}
    Append To File  ${REST_URL_FILE}  [${url_removed_list}]
    Append To File  ${REST_URL_FILE}  ${\n}URL Added${\n}
    Append To File  ${REST_URL_FILE}  [${url_added_list}]
