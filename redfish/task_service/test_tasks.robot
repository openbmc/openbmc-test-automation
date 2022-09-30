*** Settings ***

Documentation       Test task service & tasks URI functionality of OpenBMC.

Resource            ../../lib/resource.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/rest_client.robot
Resource            ../../lib/code_update_utils.robot
Resource            ../../lib/common_utils.robot
Resource            ../../lib/utils.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution


*** Variables ***

@{allowed_completed_task_overwrite_policy}  Manual  Oldest
@{allowed_task_state}  Cancelled  Completed  Exception  Interrupted  New  Pending
...  Running  Service  Starting  Stopping  Suspended
@{allowed_task_completion_state}  Cancelled  Completed  Exception


*** Test Cases ***

Verify Task Service Defaults
    [Documentation]  Validate attributes and default values in task service URI
    [Tags]  Verify_Task_Service_Defaults

    # {
    #     "@odata.id": "/redfish/v1/TaskService",
    #     "@odata.type": "#TaskService.v1_1_4.TaskService",
    #     "CompletedTaskOverWritePolicy": "Oldest",
    #     "DateTime": "2022-08-08T06:04:11+00:00",
    #     "Id": "TaskService",
    #     "LifeCycleEventOnTaskStateChange": true,
    #     "Name": "Task Service",
    #     "ServiceEnabled": true,
    #     "Status": {
    #         "Health": "OK",
    #         "HealthRollup": "OK",
    #         "State": "Enabled"
    #     },
    #     "Tasks": {
    #         "@odata.id": "/redfish/v1/TaskService/Tasks"
    #     }
    # }

    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService

    # Verify CompletedTaskOverWritePolicy is valid value
    List Should Contain Value  ${allowed_completed_task_overwrite_policy}
    ...  ${resp["CompletedTaskOverWritePolicy"]}

    # Verify service enabled property
    Should Be Equal  ${resp["ServiceEnabled"]}  ${TRUE}

    # Verify status
    Should Be Equal  ${resp["Status"]["Health"]}  OK
    Should Be Equal  ${resp["Status"]["HealthRollup"]}  OK
    Should Be Equal  ${resp["Status"]["State"]}  Enabled

    # Get current time from BMC console
    ${cur_time}=  Get Current Date from BMC
    # Remove offset from taskservice time
    ${bmc_time}=  Split String  ${resp["DateTime"]}  +
    # Compare system time and time displayed in taskservice URI
    ${time_diff}=  Subtract Date From Date  ${cur_time}  ${bmc_time[0]}
    ...  date1_format=%m/%d/%Y %H:%M:%S  date2_format=%Y-%m-%dT%H:%M:%S
    ${time_diff}=  Evaluate  ${time_diff} < 5
    Should Be Equal  ${time_diff}  ${TRUE}
    ...  Time Difference between BMC time & time displayed in task URI is higher


Generate Task Instance And Verify Task State Is Valid
    [Documentation]  Trigger a redfish event that generates task instance and
    ...  verify task state is valid throughout task lifecycle
    [Tags]  Generate_Task_Instance_And_Verify_Task_State_Is_Valid

    ${task_id}=  Generate Task Instance And Return Task Id
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}
    ...  check_state=yes


Verify Task Start Time And End Time
    [Documentation]  Verify whether the start & end time for task is valid
    [Tags]  Verify_Task_Start_Time_And_End_Time

    # Get current time from BMC console before generating task
    ${cur_time}=  Get Current Date from BMC

    # Generate any action to trigger task instanc creation
    ${task_id}=  Generate Task Instance And Return Task Id
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}

    # Verify task start time is within 10s of current time
    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    ${start_time}=  Split String  ${resp["StartTime"]}  +
    ${time_diff}=  Subtract Date From Date  ${cur_time}  ${start_time[0]}
    ...  date1_format=%m/%d/%Y %H:%M:%S  date2_format=%Y-%m-%dT%H:%M:%S

    ${time_diff}=  Evaluate  ${time_diff} < 10
    Should Be Equal  ${time_diff}  ${TRUE}  Time Diff. greater than 10 seconds

    # Verify end time is greater than start time
    ${end_time}=  Split String  ${resp["EndTime"]}  +
    ${time_diff}=  Subtract Date From Date  ${end_time[0]}  ${start_time[0]}
    ${time_diff}=  Evaluate  ${time_diff} >= 0
    Should Be Equal  ${time_diff}  ${TRUE}
    ...  End time not greater than start time


Verify Task Monitor
    [Documentation]  Verify the task monitor functionality in tasks instance
    [Tags]  Verify_Task_Monitor

    ${task_id}=  Generate Task Instance And Return Task Id

    # Verify task monitor before task completion
    ${resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}/Monitor
    ...  valid_status_codes=[${HTTP_ACCEPTED}]

    # Verify task monitor after task completion
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}
    ${resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}/Monitor
    ...  valid_status_codes=[${HTTP_NOT_FOUND}]


Verify Payload Properties
    [Documentation]  Verify the payload properties in task instance
    [Tags]  Verify_Payload_Properties

    # {
    #     "@odata.id": "/redfish/v1/TaskService/Tasks/3",
    #     "@odata.type": "#Task.v1_4_3.Task",
    #     "Id": "3",
    #     "Messages": [
    #         {
    #             "@odata.type": "#Message.v1_0_0.Message",
    #             "Message": "The task with id 3 has started.",
    #             "MessageArgs": [
    #                 "3"
    #             ],
    #             "MessageId": "TaskEvent.1.0.1.TaskStarted",
    #             "Resolution": "None.",
    #             "Severity": "OK"
    #         }
    #     ],
    #     "Name": "Task 3",
    #     "Payload": {
    #         "HttpHeaders": [
    #             "User-Agent: PostmanRuntime/7.26.8",
    #             "Accept: */*",
    #             "Host: 10.0.123.113",
    #             "Accept-Encoding: gzip, deflate, br",
    #             "Connection: keep-alive",
    #             "Content-Length: 41"
    #         ],
    #         "HttpOperation": "POST",
    #         "JsonBody": "{\n  \"DiagnosticDataType\": \"Manager\"\n}",
    #         "TargetUri": "/redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData"
    #     },
    #     "PercentComplete": 0,
    #     "StartTime": "2022-08-09T12:57:06+00:00",
    #     "TaskMonitor": "/redfish/v1/TaskService/Tasks/3/Monitor",
    #     "TaskState": "Running",
    #     "TaskStatus": "OK"
    # }

    ${task_id}=  Generate Task Instance And Return Task Id
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}

    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}

    # Verify HttpOperation in task payload
    Should Be Equal  ${resp["Payload"]["HttpOperation"]}  POST

    # Verify TargetUri
    Should Be Equal  ${resp["Payload"]["TargetUri"]}
    ...  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData

    # Verify JsonBody in task payload
    ${payload}=  Create Dictionary   DiagnosticDataType=Manager
    ${resp_payload}=  Strip String  ${resp["Payload"]["JsonBody"]}  characters=\n
    ${resp_payload}=  Evaluate  json.loads(r'''${resp_payload}''')  json
    ${resp_payload}=  Convert To Dictionary  ${resp_payload}

    Should Be Equal  ${resp_payload}  ${payload}


Check Task Persistency After BMC Reboot
    [Documentation]  Verify task collection persistency after BMC reboot
    [Tags]  Check_Task_Persistency_After_BMC_Reboot

    Generate Task Instance And Wait For Completion
    ${initial_task_count}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks
    ...  Members@odata.count
    Redfish BMC Reset Operation  reset_type=ForceRestart
    ${current_task_count}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks
    ...  Members@odata.count
    Should Be Equal  ${initial_task_count}  ${current_task_count}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup operation.

    Redfish.login


Suite Teardown Execution
    [Documentation]  Do suite teardown operation.

    Run Keyword And Ignore Error  Redfish.Logout
    FFDC On Test Case Fail
    Close All Connections


Generate Task Instance And Return Task Id
    [Documentation]  Trigger redfish event to generate task instance
    ...  and return the task id
    [Arguments]  ${task_type}=dump

    # Description of argument(s):
    # task_type         If 'task_type' set as 'dump', the keyword will
    #                   initiate bmc user dump creation and will return
    #                   the task id.

    IF  '${task_type}' == 'dump'
        ${task_id}=  Create BMC User Dump And Return Task Id
    END
    Return From Keyword  ${task_id}


Create BMC User Dump And Return Task Id
    [Documentation]  Generate user initiated BMC dump via Redfish and return
    ...  the task instance number (e.g., "5").

    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    ${resp}=  Redfish.Post  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}]

    ${ip_resp}=  Evaluate  json.loads(r'''${resp.text}''')  json

    Return From Keyword  ${ip_resp["Id"]}


Wait For Task Completion
    [Arguments]  ${task_id}  @{expected_completion}  ${retry_max_count}=300
    ...  ${check_state}=no

    # Description of argument(s):
    # task_id                     the task id for which completion is
    #                             to be monitored.
    # expected_completion         the task state which is to be considered the
    #                             end of task life cycle
    # retry_max_count             the maximum number of retry count to wait for
    #                             task to reach its completion state
    # check_state                 if set as 'yes', the task state will be
    #                             monitored whether the task state value is
    #                             valid throughout task life cycle until
    #                             expected completion state is reached

    FOR  ${retry}  IN RANGE  ${retry_max_count}
        ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
        ${current_task_state}=  Set Variable  ${resp["TaskState"]}
        Rprint Vars  current_task_state

        Run Keyword If  '${check_state}' == 'yes'  List Should Contain Value
        ...  ${allowed_task_state}  ${resp["TaskState"]}
        ...  msg=Verify task state is valid

        ${out}=  Evaluate  '${resp["TaskState"]}' in @{allowed_task_completion_state}
        Exit For Loop If  ${out}

        Sleep  5s
    END


Generate Task Instance And Wait For Completion
    [Documentation]  Trigger redfish event to generate task and wait until
    ...  task gets completed
    [Arguments]  ${task_type}=dump

    # Description of argument(s):
    # task_type         If 'task_type' set as 'dump', the keyword will
    #                   initiate bmc user dump creation and wait until
    #                   task is completed. If 'task_type' set as 'fwupdate',
    #                   firmware update task with dummy image is initiated
    #                   and wait until task completetion is reached.

    ${task_id}=  Generate Task Instance And Return Task Id  ${task_type}
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}


Get First And Last Task Instance Id
    [Documentation]  Fetch the first and last task instance id from task collection

    ${resp}=  Redfish.Get Attribute
    ...  /redfish/v1/TaskService/Tasks  Members
    ${oldest_task_instance}=  Split String  ${resp[0]["@odata.id"]}  /
    ${oldest_task_instance_id}=  Set Variable  ${oldest_task_instance[-1]}
    ${oldest_task_instance_id}=  Convert To Integer  ${oldest_task_instance_id}

    ${latest_task_instance}=  Split String  ${resp[-1]["@odata.id"]}  /
    ${latest_task_instance_id}=  Set Variable  ${latest_task_instance[-1]}
    ${latest_task_instance_id}=  Convert To Integer  ${latest_task_instance_id}

    @{task_id}=  Create List  ${oldest_task_instance_id}  ${latest_task_instance_id}

    Return From Keyword  @{task_id}