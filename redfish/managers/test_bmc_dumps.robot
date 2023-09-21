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


Verify User Initiated BMC Dump When Host Booted
    [Documentation]  Create user initiated BMC dump at host booted state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Booted

    Redfish Power On  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


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

    # Now continue to initiate multiple dump request which is not expected to be accepted
    # till earlier BMC dump task is completed. A limit is set to avoid risk of infinite loop.
    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    WHILE  True  limit=1000
        ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
        IF  '${task_dict['TaskState']}' == 'Completed'  BREAK
        ${resp}=  Redfish.Post
        ...  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Actions/LogService.CollectDiagnosticData
        ...  body=${payload}  valid_status_codes=[${HTTP_SERVICE_UNAVAILABLE}, ${HTTP_ACCEPTED}]

        # Sample response of above POST request:
        # 503
        # Strict-Transport-Security max-age=31536000; includeSubdomains; preload
        # X-Frame-Options DENY
        # Pragma no-cache
        # Cache-Control no-Store,no-Cache
        # X-XSS-Protection 1; mode=block
        # X-Content-Type-Options nosniff
        # Content-Security-Policy default-src 'none'; img-src 'self' data:; font-src 'self'; style-src
        # 'self'; script-src 'self'; connect-src 'self' wss:; form-action 'none'; frame-ancestors 'none';
        # object-src 'none'; base-uri 'none'
        # Content-Type application/json
        # Date Thu, 16 Mar 2023 06:41:06 GMT
        # Content-Length 573
        # {
        # "error": {
        # "@Message.ExtendedInfo": [
        # {
        # "@odata.type": "#Message.v1_1_1.Message",
        # "Message": "The request could not be performed because the resource is in standby.",
        # "MessageArgs": [],
        # "MessageId": "Base.1.8.1.ResourceInStandby",
        # "MessageSeverity": "Critical",
        # "Resolution": "Ensure that the resource is in the correct power state and resubmit the request."
        # }
        # ],
        # "code": "Base.1.8.1.ResourceInStandby",
        # "message": "The request could not be performed because the resource is in standby."
        # }
        # }

        # At this point the request HTTPS response should be HTTP_SERVICE_UNAVAILABLE. However, if the
        # response contains the HTTPS response code HTTP_ACCEPTED, it means there is a dump initiation
        # request which is completed. We verify this with below check.
        ${resp}=  Convert To String  ${resp}
        ${contains}=  Run Keyword And Return Status  Should Contain  ${resp.split()[0]}  ${HTTP_ACCEPTED}
        IF  ${contains}
           ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
           Should Be True  '${task_dict['TaskState']}' == 'Completed'
        END
    END

    # The next BMC dump initiation request should be accepted as earlier dump is completed.
    # Wait for few seconds before initiating the dump.
    Sleep  2s
    ${resp}=  Redfish.Post
    ...  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}]

    # Wait for above initiated dump to complete. Otherwise, on going dump would impact next test.
    Wait Until Keyword Succeeds  5 min  15 sec  Check Task Completion  ${resp.dict['Id']}


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
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available

    # Verifying that there is only one dump.
    ${dump_entries}=  Get BMC Dump Entries
    ${length}=  Get length  ${dump_entries}
    Should Be Equal As Integers  ${length}  ${1}


Verify Error Log And Dump For Internal Failure
    [Documentation]  Verify error log and dump for internal failure.
    [Tags]  Verify_Error_Log_And_Dump_For_Internal_Failure

    Redfish Purge Event Log
    Redfish Delete All BMC Dumps

    # Create an internal failure error log.
    BMC Execute Command  ${CMD_INTERNAL_FAILURE}

    # With internal failure, an error log file is generated. Check if
    # BMC has only one error log for this internal failure.
    ${resp}=  Redfish.Get  /redfish/v1/Systems/system/LogServices/CELog/Entries
    Should Be True  ${resp.dict["Members@odata.count"]} == ${1}

    # Wait for the BMC dump to become available and verify its presence.
    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Dump Available
    ${dump_entries}=  Get BMC Dump Entries
    ${length}=  Get length  ${dump_entries}
    Should Be Equal As Integers  ${length}  ${1}


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
    ${resp}=  Redfish.Get  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/${dump_entries[0]} 
    ${original_dump_size}=  Set Variable  ${resp.dict["AdditionalDataSizeBytes"]}

    Initialize OpenBMC
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}

    ${ret}=  Get Request  openbmc
    ...  /redfish/v1/Managers/bmc/LogServices/Dump/Entries/${dump_id}/attachment
    ...  headers=${headers}

    Run Keyword And Continue On Failure    Should Be Equal As Numbers     ${ret.status_code}    200

    Create Binary File     BMC_dump.tar.gz     ${ret.content}
    ${offloaded_size}=  Get File Size  BMC_dump.tar.gz

    Should Be Equal  ${offloaded_size}  ${original_dump_size}


*** Keywords ***

Get BMC Dump Entries
    [Documentation]  Return BMC dump ids list.

    ${dump_uris}=  redfish_utils.get_member_list  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries
    ${dump_ids}=  Create List

    FOR  ${dump_uri}  IN  @{dump_uris}
      ${dump_id}=  Fetch From Right  ${dump_uri}  /
      Append To List  ${dump_ids}  ${dump_id}
    END

    [Return]  ${dump_ids}


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

    [return]  ${usage_output}


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
