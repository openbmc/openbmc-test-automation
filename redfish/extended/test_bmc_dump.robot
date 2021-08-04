*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/rest_client.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/state_manager.robot
Library             ../../lib/bmc_ssh_utils.py

Suite Setup         Suite Setup Execution
Test Setup          Open Connection And Log In
Test Teardown       Test Teardown Execution

*** Test Cases ***

Verify Core Dump Size
    [Documentation]  Verify BMC core dump size is under 200k.
    [Tags]  Verify_Core_Dump_Size

    Delete All Dumps
    Trigger Core Dump
    Wait Until Keyword Succeeds  2 min  10 sec  Get Dump Entries

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    ${dump_size}=  Read Attribute  ${dump_entries[0]}  Size

    # Max size for dump is 200k = 200x1024
    Should Be True  0 < ${dump_size} < 204800  msg=Size of dump is incorrect.


Verify Dump After Host Watchdog Error Injection
    [Documentation]  Inject host watchdog error and verify whether dump is generated.
    [Tags]  Verify_Dump_After_Host_Watchdog_Error_Injection

    Redfish Power On

    Run Keyword And Ignore Error  Delete All Dumps

    # Enable auto reboot
    Set Auto Reboot  ${1}

    Trigger Host Watchdog Error  2000  30

    Wait Until Keyword Succeeds  300 sec  20 sec  Is Host Rebooted

    #Get dump details
    @{dump_entry_list}=  Read Properties  ${DUMP_ENTRY_URI}

    # Verifying that there is only one dump
    ${length}=  Get length  ${dump_entry_list}
    Should Be Equal As Integers  ${length}  ${1}

    # Get dump id
    ${value}=  Get From List  ${dump_entry_list}  0
    @{split_value}=  Split String  ${value}  /
    ${dump_id}=  Get From List  ${split_value}  -1

    # Max size for dump is 200k = 200x1024
    ${dump_size}=  Read Attribute  ${DUMP_ENTRY_URI}${dump_id}  Size
    Should Be True  0 < ${dump_size} < 204800


Verify Download BMC Dump
    [Documentation]  Verify that a BMC dump can be downloaded to the local machine.
    [Tags]  Verify_Download_BMC_Dump

    ${dump_id}=  Create User Initiated Dump
    ${dump_dict}=  Get Dump Dict
    ${bmc_dump_name}=  Fetch From Right  ${dump_dict['${dump_id}']}  /
    ${bmc_dump_checksum}  ${stderr}  ${rc}=  BMC Execute Command
    ...  md5sum ${dump_dict['${dump_id}']}|awk '{print$1}'
    ${bmc_dump_size}  ${stderr}  ${rc}=  BMC Execute Command
    ...  stat -c "%s" ${dump_dict['${dump_id}']}

    ${response}=  OpenBMC Get Request  ${DUMP_DOWNLOAD_URI}${dump_id}
    ...  quiet=${1}
    Should Be Equal As Strings  ${response.status_code}  ${HTTP_OK}
    Create Binary File  ${EXECDIR}${/}dumps   ${response.content}
    Run  tar -xvf ${EXECDIR}${/}dumps
    ${download_dump_name}=  Fetch From Left  ${bmc_dump_name}  .
    ${download_dump_checksum}=  Run  md5sum ${EXECDIR}/dumps|awk '{print$1}'
    ${download_dump_size}=  Run  stat -c "%s" ${EXECDIR}${/}dumps

    OperatingSystem.Directory Should Exist  ${EXECDIR}/${download_dump_name}
    ...  msg=Created dump name and downloaded dump name don't match.
    Should Be Equal As Strings  ${bmc_dump_checksum}  ${download_dump_checksum}
    Should Be Equal As Strings  ${bmc_dump_size}  ${download_dump_size}

    Run  rm -rf ${EXECDIR}${/}${download_dump_name};rm ${EXECDIR}${/}dumps


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do initial suite setup tasks.

    ${resp}=  OpenBMC Get Request  ${DUMP_URI}
    Run Keyword If  '${resp.status_code}' == '${HTTP_NOT_FOUND}'
    ...  Run Keywords  Set Suite Variable  ${DUMP_URI}  /xyz/openbmc_project/dump/  AND
    ...  Set Suite Variable  ${DUMP_ENTRY_URI}  /xyz/openbmc_project/dump/entry/


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Wait Until Keyword Succeeds  3 min  15 sec  Verify No Dump In Progress
    FFDC On Test Case Fail
    Delete All BMC Dump
    Close All Connections
