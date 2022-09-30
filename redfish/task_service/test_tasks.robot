*** Settings ***

Documentation       Test task service and tasks URI functionality of OpenBMC.

Library             OperatingSystem

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
Test Teardown       FFDC On Test Case Fail


*** Test Cases ***

Verify Task Service Attributes
    [Documentation]  Validate attributes and default values in task service URI.
    [Tags]  Verify_Task_Service_Attributes

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
    Should Be True
    ...  '${resp["CompletedTaskOverWritePolicy"]}' in ${allowed_completed_task_overwrite_policy}

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


Test Validity Of Generated Task Instance And Task State
    [Documentation]  Trigger a Redfish event that generates task instance and
    ...  verify the values of generated task instance.
    [Tags]  Test_Validity_Of_Generated_Task_Instance_And_Task_State

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
    #         "TargetUri": "/redfish/v1/Managers/bmc/LogServices/Dump/Actions
    #                      /LogService.CollectDiagnosticData"
    #     },
    #     "PercentComplete": 0,
    #     "StartTime": "2022-08-09T12:57:06+00:00",
    #     "TaskMonitor": "/redfish/v1/TaskService/Tasks/3/Monitor",
    #     "TaskState": "Running",
    #     "TaskStatus": "OK"
    # }

    # Trigger a Redfish event that generates task instance
    ${task_id}=  Generate Task Instance And Return Task Id

    # Verify task monitor before task completion
    ${resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}/Monitor
    ...  valid_status_codes=[${HTTP_ACCEPTED}]

    # Get current time from BMC console before generating task
    ${cur_time}=  Get Current Date from BMC

    # Verify task start time is within 10s of current time
    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    ${start_time}=  Split String  ${resp["StartTime"]}  +
    ${time_diff}=  Subtract Date From Date  ${cur_time}  ${start_time[0]}
    ...  date1_format=%m/%d/%Y %H:%M:%S  date2_format=%Y-%m-%dT%H:%M:%S
    ${time_diff}=  Evaluate  ${time_diff} < 10
    Should Be Equal  ${time_diff}  ${TRUE}  Time Diff. greater than 10 seconds

    # Verify HttpOperation in task payload
    Should Be Equal  ${resp["Payload"]["HttpOperation"]}  POST

    # Verify TargetUri
    Should Be Equal  ${resp["Payload"]["TargetUri"]}
    ...  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData

    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}
    ...  check_state=yes

    # Verify task monitor URI after task completion
    ${resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}/Monitor
    ...  valid_status_codes=[${HTTP_NOT_FOUND}]

    # Verify end time is greater than start time post task completion
    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    ${end_time}=  Split String  ${resp["EndTime"]}  +
    ${time_diff}=  Subtract Date From Date  ${end_time[0]}  ${start_time[0]}
    ${time_diff}=  Evaluate  ${time_diff} >= 0
    Should Be Equal  ${time_diff}  ${TRUE}
    ...  End time not greater than start time


Check Task Persistency After BMC Reboot
    [Documentation]  Verify task collection persistency after BMC reboot.
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
    Load Properties Data


Suite Teardown Execution
    [Documentation]  Do suite teardown operation.

    Run Keyword And Ignore Error  Redfish.Logout
    Close All Connections


Generate Task Instance And Return Task Id
    [Documentation]  Trigger Redfish event to generate task instance
    ...  and return the task id.
    [Arguments]  ${task_type}=dump

    # Description of argument(s):
    # task_type         Default value for task_type is dump. When 'task_type'
    #                   is 'dump', then keyword will initiate bmc user dump
    #                   creation and will return the task id.

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
    [Documentation]  Check whether the state of task instance matches any of the
    ...  expected completion states before maximum number of retries exceeds and
    ...  exit loop in case completion state is met.

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
    [Documentation]  Trigger Redfish event to generate task and wait until
    ...  task gets completed.
    [Arguments]  ${task_type}=dump

    # Description of argument(s):
    # task_type         If 'task_type' set as 'dump', the keyword will
    #                   initiate bmc user dump creation and wait until
    #                   task is completed. If 'task_type' set as 'fwupdate',
    #                   firmware update task with dummy image is initiated
    #                   and wait until task completion is reached.

    ${task_id}=  Generate Task Instance And Return Task Id  ${task_type}
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}


Load Properties Data
    [Documentation]  Load the properties.json file and get the task service
    ...  related variable values.

    ${json}=  OperatingSystem.Get File  data/properties.json
    ${properties}=  Evaluate  json.loads('''${json}''')  json

    Set Suite Variable  ${allowed_completed_task_overwrite_policy}
    ...  ${properties["task_service"]["completed_task_overwrite_policy"]["allowed_values"]}

    Set Suite Variable  ${allowed_task_state}
    ...  ${properties["task"]["task_state"]["allowed_values"]}

    Set Suite Variable  ${allowed_task_completion_state}
    ...  ${properties["task"]["task_state"]["allowed_completion_task_state"]}