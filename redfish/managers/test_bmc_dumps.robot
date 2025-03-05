*** Settings ***

Documentation       Test BMC dump functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Variables           ../../data/pel_variables.py

Suite Setup         Redfish.Login
Test Setup          Redfish Delete All BMC Dumps
Test Teardown       Test Teardown Execution

Test Tags          BMC_Dumps

*** Variables ***

# Total size of the dump in kilo bytes
${BMC_DUMP_TOTAL_SIZE}       ${1024}

# Minimum space required for one bmc dump in kilo bytes
${BMC_DUMP_MIN_SPACE_REQD}   ${20}
${MAX_DUMP_COUNT}            ${20}
${BMC_DUMP_COLLECTOR_PATH}   /var/lib/phosphor-debug-collector/dumps

*** Test Cases ***

Verify Error Response For Already Deleted Dump Id
    [Documentation]  Delete non existing BMC dump and expect an error.
    [Tags]  Verify_Error_Response_For_Already_Deleted_Dump_Id

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    Wait Until Keyword Succeeds  15 sec  5 sec  Redfish Delete BMC Dump  ${dump_id}
    Run Keyword And Expect Error  ValueError: *  Redfish Delete BMC Dump  ${dump_id}


Verify User Initiated BMC Dump When Host Powered Off
    [Documentation]  Create user initiated BMC dump at host off state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Powered_Off

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


Verify User Initiated BMC Dump Size
    [Documentation]  Verify user initiated BMC dump size is under 20 MB.
    [Tags]  Verify_User_Initiated_BMC_Dump_Size

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    ${resp}=  Redfish.Get Properties  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_id}

    # Example of response from above Redfish GET request.
    # "@odata.type": "#LogEntry.v1_7_0.LogEntry",
    # "AdditionalDataSizeBytes": 31644,
    # "AdditionalDataURI": "/redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/attachment/9",
    # "Created": "2020-10-23T06:32:53+00:00",
    # "DiagnosticDataType": "Manager",
    # "EntryType": "Event",
    # "Id": "9",
    # "Name": "BMC Dump Entry"

    # Max size for dump is 20 MB = 20x1024x1024 Byte.
    Should Be True  0 < ${resp["AdditionalDataSizeBytes"]} < 20971520


Verify Internal Failure Initiated BMC Dump Size
    [Documentation]  Verify that the internal failure initiated BMC dump size is under 20 MB.
    [Tags]  Verify_Internal_Failure_Initiated_BMC_Dump_Size

    Redfish Power Off  stack_mode=skip
    Redfish Delete All BMC Dumps

    # Create an internal failure error log.
    BMC Execute Command  ${CMD_INTERNAL_FAILURE}

    # Wait for BMC dump to get generated after injecting internal failure.
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available

    # Verify that only one BMC dump is generated after injecting error.
    ${dump_entries}=  Get BMC Dump Entries
    ${length}=  Get length  ${dump_entries}
    Should Be Equal As Integers  ${length}  ${1}

    # Max size for dump is 20 MB = 20x1024x1024 Byte.
    ${resp}=  Redfish.Get Properties
    ...  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_entries[0]}
    Should Be True  0 < ${resp["AdditionalDataSizeBytes"]} < 20971520


Verify Multiple BMC Dump Creation
    [Documentation]  Verify that multiple BMC dumps can be created one after
    ...  another successfully.
    [Tags]   Verify_Multiple_BMC_Dump_Creation

    Redfish Power Off  stack_mode=skip
    ${dump_count}=  Evaluate  random.randint(5, 10)  modules=random
    FOR  ${INDEX}  IN  1  ${dump_count}
      Create User Initiated BMC Dump Via Redfish
    END


Verify BMC Dump Default Location In BMC
     [Documentation]  Verify that BMC dump is created in its default location of BMC.
     [Tags]  Verify_BMC_Dump_Default_Location_In_BMC

     Redfish Power Off  stack_mode=skip
     Redfish Delete All BMC Dumps
     ${dump_id}=  Create User Initiated BMC Dump Via Redfish
     ${dump_file}  ${stderr}  ${rc}=  BMC Execute Command
     ...  ls ${BMC_DUMP_COLLECTOR_PATH}/${dump_id}
     Should Be True  ${rc} == 0
     Should Contain Any  ${dump_file}  BMCDUMP  obmcdump


Verify User Initiated BMC Dump At Host Booting
    [Documentation]  Create and verify user initiated BMC dump during Host is powwering on
    ...  or when host booting is in progress.
    [Tags]  Verify_User_Initiated_BMC_Dump_At_Host_Booting

    Redfish Power Off  stack_mode=skip
    Redfish Delete All BMC Dumps

    # Initiate power on.
    Redfish Power Operation  On
    Wait Until Keyword Succeeds  2 min  5 sec  Is Boot Progress Changed

    # Create user initiated BMC dump and verify only one dump is available.
    Create User Initiated BMC Dump Via Redfish
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1


Verify Dump Persistency On Dump Service Restart
    [Documentation]  Create user dump, restart dump manager service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Dump_Service_Restart

    Redfish Power Off  stack_mode=skip
    Create User Initiated BMC Dump Via Redfish
    ${dump_entries_before}=  redfish_utils.get_member_list  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries

    # Restart dump service.
    BMC Execute Command  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly

    ${dump_entries_after}=  redfish_utils.get_member_list  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Verify Dump Persistency On BMC Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_BMC_Reset

    # Power off host so that dump is not offloaded to host OS.
    Redfish Power Off  stack_mode=skip

    Create User Initiated BMC Dump Via Redfish
    ${dump_entries_before}=  redfish_utils.get_member_list  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries

    # Reset BMC.
    OBMC Reboot (off)  stack_mode=skip

    ${dump_entries_after}=  redfish_utils.get_member_list  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Delete User Initiated BMC Dump And Verify
    [Documentation]  Delete user initiated BMC dump and verify.
    [Tags]  Delete_User_Initiated_BMC_Dump_And_Verify

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    Wait Until Keyword Succeeds  15 sec  5 sec  Redfish Delete BMC Dump  ${dump_id}

    ${dump_entries}=  Get BMC Dump Entries
    Should Be Empty  ${dump_entries}


Delete All User Initiated BMC Dumps And Verify
    [Documentation]  Delete all user initiated BMC dumps and verify.
    [Tags]  Delete_All_User_Initiated_BMC_Dumps_And_Verify

    # Power off host so that dump is not offloaded to host OS.
    Redfish Power Off  stack_mode=skip

    # Create some BMC dump.
    Create User Initiated BMC Dump Via Redfish
    Create User Initiated BMC Dump Via Redfish

    Redfish Delete All BMC Dumps
    ${dump_entries}=  Get BMC Dump Entries
    Should Be Empty  ${dump_entries}


Create Two User Initiated BMC Dumps
    [Documentation]  Create two user initiated BMC dumps.
    [Tags]  Create_Two_User_Initiated_BMC_Dumps

    Redfish Power Off  stack_mode=skip
    ${dump_id1}=  Create User Initiated BMC Dump Via Redfish
    ${dump_id2}=  Create User Initiated BMC Dump Via Redfish

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  2
    Should Contain  ${dump_entries}  ${dump_id1}
    Should Contain  ${dump_entries}  ${dump_id2}


Create Two User Initiated BMC Dumps And Delete One
    [Documentation]  Create two dumps and delete the first.
    [Tags]  Create_Two_User_Initiated_BMC_Dumps_And_Delete_One

    Redfish Power Off  stack_mode=skip
    ${dump_id1}=  Create User Initiated BMC Dump Via Redfish
    ${dump_id2}=  Create User Initiated BMC Dump Via Redfish

    Wait Until Keyword Succeeds  15 sec  5 sec  Redfish Delete BMC Dump  ${dump_id1}

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id2}


Create And Delete User Initiated BMC Dump Multiple Times
    [Documentation]  Create and delete user initiated BMC dump multiple times.
    [Tags]  Create_And_Delete_User_Initiated_BMC_Dump_Multiple_Times

    Redfish Power Off  stack_mode=skip
    FOR  ${INDEX}  IN  1  10
      ${dump_id}=  Create User Initiated BMC Dump Via Redfish
      Wait Until Keyword Succeeds  15 sec  5 sec  Redfish Delete BMC Dump  ${dump_id}
    END


Verify Maximum BMC Dump Creation
    [Documentation]  Create maximum BMC dump and verify error when dump runs out of space.
    [Tags]  Verify_Maximum_BMC_Dump_Creation
    [Teardown]  Redfish Delete All BMC Dumps

    # Maximum allowed space for dump is 1024 KB. BMC typically hold 8-14 dumps
    # before running out of this dump space. So trying to create dumps in 20
    # iterations to run out of space.
    # User can key in the Maximum allowed space for bmc dump and how many iteration.
    FOR  ${n}  IN RANGE  0  ${MAX_DUMP_COUNT}
      Create User Initiated BMC Dump Via Redfish
      ${dump_space}=  Get Disk Usage For Dumps
      Exit For Loop If  ${dump_space} >= (${BMC_DUMP_TOTAL_SIZE} - ${BMC_DUMP_MIN_SPACE_REQD})
    END

    # Check error while creating dump when dump size is full.
    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    Redfish.Post  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR}]


Verify BMC Core Dump When Host Powered Off
    [Documentation]  Verify BMC core dump after application crash at host powered off state.
    [Tags]  Verify_BMC_Core_Dump_When_Host_Powered_Off

    Redfish Power Off  stack_mode=skip

    # Ensure all dumps are cleaned out.
    Redfish Delete All BMC Dumps
    Trigger Core Dump

    # Verify that BMC dump is available.
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available


Verify Core Dump Size
    [Documentation]  Verify BMC core dump size is under 20 MB.
    [Tags]  Verify_Core_Dump_Size

    Redfish Power Off  stack_mode=skip

    # Ensure all dumps are cleaned out.
    Redfish Delete All BMC Dumps
    Trigger Core Dump

    # Verify that BMC dump is available.
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available
    ${dump_entries}=  Get BMC Dump Entries
    ${resp}=  Redfish.Get Properties
    ...  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_entries[0]}

    # Max size for dump is 20 MB = 20x1024x1024 Byte.
    Should Be True  0 < ${resp["AdditionalDataSizeBytes"]} < 20971520


Verify Error While Initiating BMC Dump During Dumping State
    [Documentation]  Verify error while initiating BMC dump during dumping state.
    [Tags]  Verify_Error_While_Initiating_BMC_Dump_During_Dumping_State

    Redfish Power Off  stack_mode=skip
    ${task_id}=  Create User Initiated BMC Dump Via Redfish  ${1}

    # Check error while initiating BMC dump while dump in progress.
    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    Redfish.Post
    ...  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_SERVICE_UNAVAILABLE}]

    # Wait for above initiated dump to complete. Otherwise, on going dump would impact next test.
    Wait Until Keyword Succeeds  5 min  15 sec  Check Task Completion  ${task_id}


Verify BMC Dump Create Errors While Another BMC Dump In Progress
    [Documentation]  Verify BMC dump creation error until older BMC dump completion.
    [Tags]  Verify_BMC_Dump_Create_Errors_While_Another_BMC_Dump_In_Progress

    Redfish Power Off  stack_mode=skip

    # Initiate a BMC dump that returns without completion.
    ${task_id}=  Create User Initiated BMC Dump Via Redfish  ${1}
    ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    IF  '${task_dict['TaskState']}' != 'Completed'
        ${resp}=  Redfish.Post
        ...  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Actions/LogService.CollectDiagnosticData
        ...  body=${payload}  valid_status_codes=[${HTTP_SERVICE_UNAVAILABLE}]
    END

    # Wait for above initiated dump to complete. Otherwise, on going dump would impact next test.
    Wait Until Keyword Succeeds  5 min  15 sec  Check Task Completion  ${task_id}


Verify Core Dump After Terminating Dump Manager Service
    [Documentation]  Verify initiate core dumps and kill Phosphor-dump-manager.
    [Tags]  Verify_Core_Dump_After_Terminating_Dump_Manager_Service

    Redfish Power Off  stack_mode=skip

    # Remove all available dumps in BMC.
    Redfish Delete All BMC Dumps

    # Find the pid of the phosphor-dump-manage process and kill it.
    ${cmd_buf}=  Catenate  kill -s SEGV $(pgrep phosphor-dump-manager)
    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd_buf}
    Should Be Equal As Integers  ${rc}  ${0}

    # Verify that BMC dump is available.
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Dump Available

    # Verifying that there is only one dump.
    ${dump_entries}=  Get BMC Dump Entries
    ${length}=  Get length  ${dump_entries}
    Should Be Equal As Integers  ${length}  ${1}


Verify User Initiated BMC Dump Type
    [Documentation]  Download user initiate BMC dump and validates its type.
    [Tags]  Verify_User_Initiated_BMC_Dump_Type

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish

    # Download BMC dump and verify its size.
    ${resp}=  Redfish.Get  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_id}
    ${redfish_dump_creation_timestamp}=  Set Variable  ${resp.dict["Created"]}
    # Download BMC dump and verify its size.
    ${tarfile}=  Download BMC Dump  ${dump_id}

    # Extract dump and verify type of dump from summary.log content:
    # Wed Aug 30 17:23:29 UTC 2023 Name:          BMCDUMP.XXXXXXX.0001005.20230830172329
    # Wed Aug 30 17:23:29 UTC 2023 Epochtime:     1693416209
    # Wed Aug 30 17:23:29 UTC 2023 ID:            0001005
    # Wed Aug 30 17:23:29 UTC 2023 Type:          user
    ${extracted_dump_folder}=  Extract BMC Dump  BMC_dump.tar.gz  ${redfish_dump_creation_timestamp}
    ${contents}=  OperatingSystem.Get File  ${extracted_dump_folder}/summary.log
    Should Match Regexp  ${contents}  Type:[ ]*user

    # Clean extracted dump files.
    Remove Files  output  output.zst
    Remove Directory  ${extracted_dump_folder}  True


Verify Retrieve Core Initiated BMC Dump
    [Documentation]  Verify retrieval of core initiated BMC dump.
    [Tags]  Verify_Retrieve_Core_Initiated_BMC_Dump

    Redfish Power Off  stack_mode=skip

    # Ensure all dumps are cleaned out.
    Redfish Delete All BMC Dumps
    Trigger Core Dump

    # Verify that BMC dump is available.
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available

    ${dump_entries}=  Get BMC Dump Entries
    # Download BMC dump and verify its size.
    Download BMC Dump  ${dump_entries[0]}


Verify Retrieve User Initiated BMC Dump
    [Documentation]  Verify retrieval of user initiated BMC dump.
    [Tags]  Verify_Retrieve_User_Initiated_BMC_Dump

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish

    # Download BMC dump.
    Download BMC Dump  ${dump_id}


Verify Core Initiated BMC Dump Type
    [Documentation]  Download core initiate BMC dump and validates its type.
    [Tags]  Verify_Core_Initiated_BMC_Dump_Type

    Redfish Power Off  stack_mode=skip

    # Ensure all dumps are cleaned out.
    Redfish Delete All BMC Dumps
    Trigger Core Dump

    # Verify that BMC dump is available.
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available

    ${dump_entries}=  Get BMC Dump Entries

    # Find the timestamp of BMC dump.
    ${resp}=  Redfish.Get  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_entries[0]}
    ${redfish_dump_creation_timestamp}=  Set Variable  ${resp.dict["Created"]}

    # Download BMC dump and verify its size.
    ${tarfile}=  Download BMC Dump  ${dump_entries[0]}

    # Extract dump and verify type of dump from summary.log content:
    # Wed Aug 30 17:23:29 UTC 2023 Name:          BMCDUMP.XXXXXXX.0001005.20230830172329
    # Wed Aug 30 17:23:29 UTC 2023 Epochtime:     1693416209
    # Wed Aug 30 17:23:29 UTC 2023 ID:            0001005
    # Wed Aug 30 17:23:29 UTC 2023 Type:          core

    ${extracted_dump_folder}=  Extract BMC Dump  ${tarfile}  ${redfish_dump_creation_timestamp}
    ${contents}=  OperatingSystem.Get File  ${extracted_dump_folder}/summary.log
    Should Match Regexp  ${contents}  Type:[ ]*core

    # Clean extracted dump files.
    Remove Files  output  output.zst
    Remove Directory  ${extracted_dump_folder}  True


Verify Core Watchdog Initiated BMC Dump
    [Documentation]  Verify core watchdog timeout initiated BMC dump.
    [Tags]  Verify_Core_Watchdog_Initiated_BMC_Dump

    Redfish Delete All BMC Dumps
    Redfish Power Off  stack_mode=skip

    # Trigger watchdog timeout.
    Redfish Initiate Auto Reboot  2000

    # Wait for BMC dump to get generated after injecting watchdog timeout.
    Wait Until Keyword Succeeds  4 min  20 sec  Is BMC Dump Available

    # Verify that only one BMC dump is available.
    ${dump_entry_list}=  Get BMC Dump Entries
    ${length}=  Get length  ${dump_entry_list}
    Should Be Equal As Integers  ${length}  ${1}


*** Keywords ***

Download BMC Dump
    [Documentation]  Download BMC dump and verify its size.
    [Arguments]  ${dump_id}

    # Description of argument(s):
    # dump_id                An integer value that identifies a particular dump (e.g. 1, 3).

    ${resp}=  Redfish.Get  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_id}
    ${redfish_bmc_dump_size}=  Set Variable  ${resp.dict["AdditionalDataSizeBytes"]}

    Initialize OpenBMC
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream  X-Auth-Token=${XAUTH_TOKEN}

    ${ret}=  GET On Session  openbmc  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_id}/attachment  headers=${headers}

    Should Be Equal As Numbers  ${ret.status_code}  200

    Create Binary File  BMC_dump.tar.gz  ${ret.content}
    ${downloaded_dump_size}=  Get File Size  BMC_dump.tar.gz
    Should Be Equal  ${downloaded_dump_size}  ${redfish_bmc_dump_size}
    RETURN  BMC_dump.tar.gz


Extract BMC Dump
    [Documentation]  Extract BMC dump from the tar file and returns the name of
    ...  extracted folder like BMCDUMP.XXXXXXX.0000070.20230706063841.
    [Arguments]  ${filename}   ${bmc_dump_timestamp}

    # Description of argument(s):
    # filename                name of BMC dump tar file.
    # bmc_dump_timestamp      timestamp of generated BMC dump.

    OperatingSystem.File Should Exist  ${filename}
    ${rc}=  Run And Return RC  dd if=${filename} of=output.zst bs=1 skip=628
    Should Be True  0 == ${rc}

    ${rc}=  Run And Return RC  zstd -d output.zst
    Should Be True  0 == ${rc}

    ${rc}=  Run And Return RC  tar -xvf output
    Should Be True  0 == ${rc}

    # Find the extracted dump folder identified with BMCDUMP as prefix and
    # timestamp of dump generation where timestamp format is : 2023-09-27T08:30:17.000000+00:00.
    ${var}=  Fetch From Left  ${bmc_dump_timestamp}  .
    ${var}=  Remove String  ${var}  -  T  :
    ${bmc_extraction_folders}=  OperatingSystem.List Directories In Directory  .  BMCDUMP*${var}
    ${cnt}=  Get length  ${bmc_extraction_folders}
    should be equal as numbers  ${cnt}  1

    RETURN  ${bmc_extraction_folders}[0]


Get BMC Dump Entries
    [Documentation]  Return BMC dump ids list.

    ${dump_uris}=  redfish_utils.get_member_list  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries
    ${dump_ids}=  Create List

    FOR  ${dump_uri}  IN  @{dump_uris}
      ${dump_id}=  Fetch From Right  ${dump_uri}  /
      Append To List  ${dump_ids}  ${dump_id}
    END

    RETURN  ${dump_ids}


Is BMC Dump Available
    [Documentation]  Verify if BMC dump is available.

    ${dump_entries}=  Get BMC Dump Entries

    # Verifying that BMC dump is available.
    ${length}=  Get length  ${dump_entries}
    Should Be True  0 < ${length}


Get Disk Usage For Dumps
    [Documentation]  Return disk usage in kilobyte for BMC dumps.

    ${usage_output}  ${stderr}  ${rc}=  BMC Execute Command  du -s ${BMC_DUMP_COLLECTOR_PATH}

    # Example of output from above BMC cli command.
    # $ du -s /var/lib/phosphor-debug-collector/dumps
    # 516    /var/lib/phosphor-debug-collector/dumps

    ${usage_output}=  Fetch From Left  ${usage_output}  /
    ${usage_output}=  Convert To Integer  ${usage_output}

    RETURN  ${usage_output}


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
