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

Resource          code_update_utils.robot
Resource          ../../lib/boot/boot_resource_master.robot
Resource          ../../lib/state_manager.robot
Resource          ../../lib/utils.robot
Resource          ../../lib/openbmc_ffdc.robot

Test Teardown      FFDC On Test Case Fail

*** Variables ***

${FILE_PATH}       ${EMPTY}
${REST_URL_FILE}   ${EMPTY}
${FORCE_UPDATE}    ${0}
${IDENTIFY_REST_URL}  no

# There are two reboots issued by code update.
${MAX_BOOT_COUNT}  ${2}

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

Initiate Code Update BMC
    [Documentation]  BMC code update process initiation
    [Setup]  Set State Interface Version
    [Tags]  Initiate_Code_Update_BMC

    Check If File Exist  ${FILE_PATH}
    System Readiness Test

    ${url_before_cu}=  Collect URL List

    # TODO: Disabling version check until new logic are in place.
    # ${status}=   Run Keyword and Return Status
    # ...   Validate BMC Version   before

    # Run Keyword if  '${status}' == '${False}'
    # ...     Pass Execution   Same Driver version installed

    # Enable user to bypass prerequisite operations.
    # Use cases for if BMC is not in working state.
    Run Keyword If  ${FORCE_UPDATE} == ${0}
    ...  Prepare BMC For Update

    Preserve BMC Network Setting
    SCP Tar Image File to BMC   ${FILE_PATH}

    Activate BMC flash image

    Run Keyword And Ignore Error    Trigger Warm Reset
    # Warm reset adds 3 seconds delay before forcing reboot
    # To minimize race conditions, we wait for 7 seconds
    Sleep  7s
    ${session_active}=   Check If warmReset is Initiated
    Run Keyword If   '${session_active}' == '${True}'
    ...    Trigger Warm Reset via Reboot

    Check If BMC is Up    30 min   10 sec
    Check Boot Count And Time
    Sleep  1 min
    # Validate BMC Version

    # Now that the code update is completed, make sure we use the correct
    # interface while checking for BMC ready state.
    Set State Interface Version
    Wait For BMC Ready
    Check Boot Count And Time
    Run Keyword If  ${BOOT_COUNT} == ${1}
    ...  Log  Boot Time not Updated by Kernel!!!  level=WARN

    ${url_after_cu}=  Collect URL List
    Run Keyword If  '${IDENTIFY_REST_URL}' == 'yes'
    ...  Compare URL List After Code Update  ${url_before_cu}  ${url_after_cu}


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

Collect URL List
    [Documentation]  Collect URLs list by using enumerate.

    Open Connection And Log In
    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=30
    ${list}=  Get Dictionary Keys  ${resp}
    [Return]  ${list}

Compare URL List After Code Update
    [Documentation]  Compare URL list before and after code update.
    [Arguments]  ${url_before_cu}  ${url_after_cu}
    # Description of arguments:
    # url_before_cu  List of URLs available before code update.
    # url_after_cu   List of URLs available after code update.

    Create File  ${REST_URL_FILE}  URL Removed${\n}
    ${url_removed_list}=  Create List
    :FOR  ${item}  IN  @{url_before_cu}
    \  ${status}=  Run Keyword And Return Status  Should Contain  ${url_after_cu}  ${item}
    \  Run Keyword If  '${status}' == '${False}'
    ...  Append To File  ${REST_URL_FILE}  [${item}]${\n}

    Append To File  ${REST_URL_FILE}  URL Added${\n}

    ${url_added_list}=  Create List
    :FOR  ${item}  IN  @{url_after_cu}
    \  ${status}=  Run Keyword And Return Status  Should Contain  ${url_before_cu}  ${item}
    \  Run Keyword If  '${status}' == '${False}'
    ...  Append To File  ${REST_URL_FILE}  [${item}]${\n}
