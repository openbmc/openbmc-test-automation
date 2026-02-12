*** Settings ***

Documentation       Test task service and tasks URI functionality of OpenBMC.

Library             OperatingSystem

Resource            ../../lib/resource.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Teardown       FFDC On Test Case Fail

Test Tags          Tasks_Service

*** Variables ***
${TIME_REGEXP_PATTERN}   (.+)[\\-|\\+]\\d\\d\\:\\d\\d

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

    # Verify CompletedTaskOverWritePolicy is a valid value.
    Should Be True
    ...  '${resp["CompletedTaskOverWritePolicy"]}' in ${allowed_completed_task_overwrite_policy}

    # Verify service enabled property.
    Should Be Equal  ${resp["ServiceEnabled"]}  ${TRUE}

    # Verify status.
    Dictionaries Should Be Equal  ${resp["Status"]}  ${valid_status}

    # Get current time from BMC console.
    ${cur_time}=  Get Current Date From BMC

    # Remove offset from task service time.
    ${bmc_time}=  Get Regexp Matches  ${resp["DateTime"]}
    ...  ${TIME_REGEXP_PATTERN}  1

    ${time_diff}=  Subtract Date From Date  ${cur_time}  ${bmc_time[0]}
    ...  date1_format=%m/%d/%Y %H:%M:%S  date2_format=%Y-%m-%dT%H:%M:%S

    # Compare system time and time displayed in task service URI.
    ${time_diff}=  Evaluate  ${time_diff} < 5

    Should Be Equal  ${time_diff}  ${TRUE}
    ...  Time Difference between BMC time and time displayed in task URI is higher.


Test Generated Task Instance Validity And Task State
    [Documentation]  Trigger a Redfish event that generates task instance and
    ...  verify the values of generated task instance.
    [Tags]  Test_Generated_Task_Instance_Validity_And_Task_State

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
    #         "TargetUri": "/redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Actions
    #                      /LogService.CollectDiagnosticData"
    #     },
    #     "PercentComplete": 0,
    #     "StartTime": "2022-08-09T12:57:06+00:00",
    #     "TaskMonitor": "/redfish/v1/TaskService/Tasks/3/Monitor",
    #     "TaskState": "Running",
    #     "TaskStatus": "OK"
    # }

    # Trigger a Redfish event that generates task instance.
    ${task_id}  ${resp_obj}=  Generate Task Instance

    # Verify task monitor before task completion.
    ${resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}/Monitor
    ...  valid_status_codes=[${HTTP_ACCEPTED}]

    # Get current time from BMC console before generating task.
    ${cur_time}=  Get Current Date From BMC

    # Verify task start time is within 10s of current time.
    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}

    ${start_time}=  Get Regexp Matches  ${resp["StartTime"]}
    ...  ${TIME_REGEXP_PATTERN}  1

    # Compare system time and time displayed in task service URI.
    ${time_diff}=  Subtract Date From Date  ${cur_time}  ${start_time[0]}
    ...  date1_format=%m/%d/%Y %H:%M:%S  date2_format=%Y-%m-%dT%H:%M:%S


    ${time_diff}=  Evaluate  ${time_diff} < 10
    Should Be Equal  ${time_diff}  ${TRUE}  Time difference greater than 10 seconds.

    # Verify HttpOperation in task payload.
    Should Be Equal  ${resp["Payload"]["HttpOperation"]}  POST

    # Verify TargetUri.
    Should Be Equal  ${resp["Payload"]["TargetUri"]}
    ...  ${resp_obj.request.path}

    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}
    ...  check_state=${TRUE}

    # Verify task monitor URI after task completion.
    ${resp}=  Redfish.Get  /redfish/v1/TaskService/Tasks/${task_id}/Monitor
    ...  valid_status_codes=[${HTTP_NOT_FOUND}]

    # Verify end time is greater than start time post task completion.
    ${resp}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}

    ${end_time}=  Get Regexp Matches  ${resp["EndTime"]}
    ...  ${TIME_REGEXP_PATTERN}  1

    # Compare start time and end time displayed in task service URI.
    ${time_diff}=  Subtract Date From Date  ${end_time[0]}  ${start_time[0]}

    ${time_diff}=  Evaluate  ${time_diff} >= 0

    Should Be Equal  ${time_diff}  ${TRUE}
    ...  End time not greater than start time.


Verify Task Persistency Post BMC Reboot
    [Documentation]  Verify task collection persistency post BMC reboot.
    [Tags]  Verify_Task_Persistency_Post_BMC_Reboot

    Verify Generate Task Instance Completion

    ${initial_task_count}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks
    ...  Members@odata.count

    Redfish BMC Reset Operation  reset_type=ForceRestart

    ${current_task_count}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks
    ...  Members@odata.count

    Should Be Equal As Integers  ${initial_task_count}  ${current_task_count}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup operation.

    Redfish.Login
    Load Task Service Properties Data


Suite Teardown Execution
    [Documentation]  Do suite teardown operation.

    Run Keyword And Ignore Error  Redfish.Logout
    Close All Connections


Generate Task Instance
    [Documentation]  Trigger Redfish event to generate task instance
    ...  and return the task id.
    [Arguments]  ${task_type}=bmc_dump

    # Description of argument(s):
    # task_type         Default value for task_type is bmc_dump. When 'task_type'
    #                   is 'bmc_dump', then keyword will initiate bmc user dump
    #                   creation and will return the task id and response object.

    IF  '${task_type}' == 'bmc_dump'
        ${task_id}  ${resp}=  Create BMC User Dump
    ELSE
        Fail  Task type "${task_type}" is unknown.
    END

    RETURN  ${task_id}  ${resp}


Verify Generate Task Instance Completion
    [Documentation]  Trigger Redfish event to generate task and wait until
    ...  task gets completed.
    [Arguments]  ${task_type}=bmc_dump

    # Description of argument(s):
    # task_type         If 'task_type' set as 'bmc_dump', the keyword will
    #                   initiate bmc user dump creation and wait until
    #                   task is completed. Default value of task_type
    #                   is bmc_dump.

    ${task_id}  ${resp}=  Generate Task Instance  ${task_type}
    Wait For Task Completion  ${task_id}  ${allowed_task_completion_state}


Load Task Service Properties Data
    [Documentation]  Load the task service related properties from json file.

    # User input -v TASK_JSON_FILE_PATH:<path> else default path.
    # ${task_json_file}=  Get Variable Value  ${TASK_JSON_FILE_PATH}  data/task_state.json

    ${json}=  OperatingSystem.Get File  ${TASK_JSON_FILE_PATH}
    ${properties}=  Evaluate  json.loads('''${json}''')  json

    Set Suite Variable  ${allowed_completed_task_overwrite_policy}
    ...  ${properties["TaskService"]["CompletedTaskOverWritePolicy"]["AllowedValues"]}

    Set Suite Variable  ${allowed_task_state}
    ...  ${properties["Task"]["TaskState"]["AllowedValues"]}

    Set Suite Variable  ${allowed_task_completion_state}
    ...  ${properties["Task"]["TaskState"]["AllowedCompletionTaskState"]}

    Set Suite Variable  ${valid_status}
    ...  ${properties["TaskService"]["Status"]}


Get Current Date From BMC
    [Documentation]  Runs the date command from BMC and returns current date and time.

    # Get Current Date from BMC
    ${date}  ${stderr}  ${rc}=  BMC Execute Command   date

    # Split the string and remove first and 2nd last value from
    # the list and join to form %d %b %H:%M:%S %Y date format.

    ${date}=  Split String  ${date}

    Remove From List  ${date}  0
    Remove From List  ${date}  -2
    ${date}=  Evaluate  " ".join(${date})

    # Convert the date format to %m/%d/%Y %H:%M:%S
    ${date}=  Convert Date  ${date}  date_format=%b %d %H:%M:%S %Y  result_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    RETURN   ${date}
