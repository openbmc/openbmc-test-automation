*** Settings ***

Documentation       Module to support Redfish BMC Dump related functionalities.

*** Keywords ***

Create User Initiated BMC Dump
    [Documentation]  Trigger user initiated BMC dump and return task id.

    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    ${resp}=  Redfish.Post
    ...  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}]

    # Example of response from above Redfish POST request.
    # "@odata.id": "/redfish/v1/TaskService/Tasks/0",
    # "@odata.type": "#Task.v1_4_3.Task",
    # "Id": "0",
    # "TaskState": "Running",
    # "TaskStatus": "OK"

    ${task_id}=  Set Variable  ${resp.dict['Id']}
    [Return]  ${task_id}

Auto Generate BMC Dump
    [Documentation]  Auto generate BMC dump.

    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command
    ...  busctl --verbose call xyz.openbmc_project.Dump.Manager /xyz/openbmc_project/dump/bmc xyz.openbmc_project.Dump.Create CreateDump a{ss} 0
    [Return]  ${stdout}  ${stderr}  ${rc}

Get Dump Size
    [Documentation]  Get dump size.
    [Arguments]  ${dump_id}

    # Description of argument(s):
    # dump_id        Dump ID.

    # Example of BMC Dump entry.
    # "@odata.id": "/redfish/v1/Managers/bmc/LogServices/Dump/Entries/382",
    # "@odata.type": "#LogEntry.v1_7_0.LogEntry",
    # "AdditionalDataSizeBytes": 211072,
    # "AdditionalDataURI": "/redfish/v1/Managers/bmc/LogServices/Dump/attachment/382",
    # "Created": "2021-03-30T17:09:34+00:00",
    # "DiagnosticDataType": "Manager",
    # "EntryType": "Event",
    # "Id": "382",
    # "Name": "BMC Dump Entry"

    ${dump_data}=  Redfish.Get Properties  /redfish/v1/Managers/bmc/LogServices/Dump/Entries/${dump_id}
    [Return]  ${dump_data["AdditionalDataSizeBytes"]}

Get Dump ID And Status
    [Documentation]  Return task status.
    [Arguments]   ${task_id}

    # Description of argument(s):
    # task_id        Task ID.

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
    #     "TargetUri":
    # "/redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData"
    # }

    FOR  ${time}  IN RANGE  20
      ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
      Return From Keyword If  "${task_dict['TaskState']}" == "Completed" or "${task_dict['TaskState']}" == "Cancelled"
      ...  ${task_dict['TaskState']}
      ...  ${task_dict["Payload"]["HttpHeaders"][-1].split("/")[-1]}
      Sleep  15s
    END

Delete All BMC Dumps
    [Documentation]  Delete all BMC dumps.

    Redfish.Post
    ...  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.ClearLog
    ...  valid_status_codes=[${HTTP_OK}]