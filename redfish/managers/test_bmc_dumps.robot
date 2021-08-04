*** Settings ***

Documentation       Test BMC dump functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Redfish.Login
Test Setup          Redfish Delete All BMC Dumps
Test Teardown       Test Teardown Execution

*** Variables ***

# Total size of the dump in kilo bytes
${BMC_DUMP_TOTAL_SIZE}       ${1024}

# Minimum space required for one bmc dump in kilo bytes
${BMC_DUMP_MIN_SPACE_REQD}   ${20}

*** Test Cases ***

Verify User Initiated BMC Dump When Host Powered Off
    [Documentation]  Create user initiated BMC dump at host off state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Powered_Off

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}

Verify User Initiated BMC Dump When Host Booted
    [Documentation]  Create user initiated BMC dump at host booted state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Booted

    Redfish Power On  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


Verify User Initiated BMC Dump Size
    [Documentation]  Verify user initiated BMC dump size is under 200 KB.
    [Tags]  Verify_User_Initiated_BMC_Dump_Size

    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    ${resp}=  Redfish.Get Properties  /redfish/v1/Managers/bmc/LogServices/Dump/Entries/${dump_id}

    # Example of response from above Redfish GET request.
    # "@odata.type": "#LogEntry.v1_7_0.LogEntry",
    # "AdditionalDataSizeBytes": 31644,
    # "AdditionalDataURI": "/redfish/v1/Managers/bmc/LogServices/Dump/attachment/9",
    # "Created": "2020-10-23T06:32:53+00:00",
    # "DiagnosticDataType": "Manager",
    # "EntryType": "Event",
    # "Id": "9",
    # "Name": "BMC Dump Entry"

    # Max size for dump is 200 KB = 200x1024 Byte.
    Should Be True  0 < ${resp["AdditionalDataSizeBytes"]} < 204800


Verify Dump Persistency On Dump Service Restart
    [Documentation]  Create user dump, restart dump manager service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Dump_Service_Restart

    Create User Initiated BMC Dump Via Redfish
    ${dump_entries_before}=  redfish_utils.get_member_list  /redfish/v1/Managers/bmc/LogServices/Dump/Entries

    # Restart dump service.
    BMC Execute Command  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly

    ${dump_entries_after}=  redfish_utils.get_member_list  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Verify Dump Persistency On BMC Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_BMC_Reset

    Create User Initiated BMC Dump Via Redfish
    ${dump_entries_before}=  redfish_utils.get_member_list  /redfish/v1/Managers/bmc/LogServices/Dump/Entries

    # Reset BMC.
    OBMC Reboot (off)  stack_mode=skip

    ${dump_entries_after}=  redfish_utils.get_member_list  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Delete User Initiated BMC Dump And Verify
    [Documentation]  Delete user initiated BMC dump and verify.
    [Tags]  Delete_User_Initiated_BMC_Dump_And_Verify

    ${dump_id}=  Create User Initiated BMC Dump Via Redfish
    Redfish Delete BMC Dump  ${dump_id}

    ${dump_entries}=  Get BMC Dump Entries
    Should Be Empty  ${dump_entries}


Delete All User Initiated BMC Dumps And Verify
    [Documentation]  Delete all user initiated BMC dumps and verify.
    [Tags]  Delete_All_User_Initiated_BMC_Dumps_And_Verify

    # Create some BMC dump.
    Create User Initiated BMC Dump Via Redfish
    Create User Initiated BMC Dump Via Redfish

    Redfish Delete All BMC Dumps
    ${dump_entries}=  Get BMC Dump Entries
    Should Be Empty  ${dump_entries}


Create Two User Initiated BMC Dumps
    [Documentation]  Create two user initiated BMC dumps.
    [Tags]  Create_Two_User_Initiated_BMC_Dumps

    ${dump_id1}=  Create User Initiated BMC Dump Via Redfish
    ${dump_id2}=  Create User Initiated BMC Dump Via Redfish

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  2
    Should Contain  ${dump_entries}  ${dump_id1}
    Should Contain  ${dump_entries}  ${dump_id2}


Create Two User Initiated BMC Dumps And Delete One
    [Documentation]  Create two dumps and delete the first.
    [Tags]  Create_Two_User_Initiated_BMC_Dumps_And_Delete_One

    ${dump_id1}=  Create User Initiated BMC Dump Via Redfish
    ${dump_id2}=  Create User Initiated BMC Dump Via Redfish

    Redfish Delete BMC Dump  ${dump_id1}

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id2}


Create And Delete User Initiated BMC Dump Multiple Times
    [Documentation]  Create and delete user initiated BMC dump multiple times.
    [Tags]  Create_And_Delete_User_Initiated_BMC_Dump_Multiple_Times

    FOR  ${INDEX}  IN  1  10
      ${dump_id}=  Create User Initiated BMC Dump Via Redfish
      Redfish Delete BMC Dump  ${dump_id}
    END


Verify Maximum BMC Dump Creation
    [Documentation]  Create maximum BMC dump and verify error when dump runs out of space.
    [Tags]  Verify_Maximum_BMC_Dump_Creation
    [Teardown]  Redfish Delete All BMC Dumps

    # Maximum allowed space for dump is 1024 KB. BMC typically hold 8-14 dumps
    # before running out of this dump space. So trying to create dumps in 20
    # iterations to run out of space.

    FOR  ${n}  IN RANGE  0  20
      Create User Initiated BMC Dump Via Redfish
      ${dump_space}=  Get Disk Usage For Dumps
      Exit For Loop If  ${dump_space} >= (${BMC_DUMP_TOTAL_SIZE} - ${BMC_DUMP_MIN_SPACE_REQD})
    END

    # Check error while creating dump when dump size is full.
    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    Redfish.Post  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR}]


*** Keywords ***

Create User Initiated BMC Dump Via Redfish
    [Documentation]  Generate user initiated BMC dump via Redfish and return the dump id number (e.g., "5").

    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    ${resp}=  Redfish.Post  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}]

    # Example of response from above Redfish POST request.
    # "@odata.id": "/redfish/v1/TaskService/Tasks/0",
    # "@odata.type": "#Task.v1_4_3.Task",
    # "Id": "0",
    # "TaskState": "Running",
    # "TaskStatus": "OK"

    Wait Until Keyword Succeeds  5 min  15 sec  Is Task Completed  ${resp.dict['Id']}
    ${task_id}=  Set Variable  ${resp.dict['Id']}

    ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}

    # Example of HttpHeaders field of task details.
    # "Payload": {
    #   "HttpHeaders": [
    #     "Host: <BMC_IP>",
    #      "Accept-Encoding: identity",
    #      "Connection: Keep-Alive",
    #      "Accept: */*",
    #      "Content-Length: 33",
    #      "Location: /redfish/v1/Managers/bmc/LogServices/Dump/Entries/2"]
    #    ],
    #    "HttpOperation": "POST",
    #    "JsonBody": "{\"DiagnosticDataType\":\"Manager\"}",
    #     "TargetUri": "/redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData"
    # }

    [Return]  ${task_dict["Payload"]["HttpHeaders"][-1].split("/")[-1]}


Get BMC Dump Entries
    [Documentation]  Return BMC dump ids list.

    ${dump_uris}=  redfish_utils.get_member_list  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
    ${dump_ids}=  Create List

    FOR  ${dump_uri}  IN  @{dump_uris}
      ${dump_id}=  Fetch From Right  ${dump_uri}  /
      Append To List  ${dump_ids}  ${dump_id}
    END

    [Return]  ${dump_ids}


Get Disk Usage For Dumps
    [Documentation]  Return disk usage in kilobyte for BMC dumps.

    ${usage_output}  ${stderr}  ${rc}=  BMC Execute Command  du -s /var/lib/phosphor-debug-collector/dumps

    # Example of output from above BMC cli command.
    # $ du -s /var/lib/phosphor-debug-collector/dumps
    # 516    /var/lib/phosphor-debug-collector/dumps

    ${usage_output}=  Fetch From Left  ${usage_output}  /
    ${usage_output}=  Convert To Integer  ${usage_output}

    [return]  ${usage_output}


Is Task Completed
    [Documentation]  Verify if the given task is completed.
    [Arguments]   ${task_id}

    # Description of argument(s):
    # task_id        Id of task which needs to be checked.

    ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    Should Be Equal As Strings  ${task_dict['TaskState']}  Completed


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
