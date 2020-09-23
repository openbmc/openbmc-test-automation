*** Settings ***

Documentation       Test BMC dump functionality of OpenBMC.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/dump_utils.robot

Test Setup          Delete All Dumps
Test Teardown       Test Teardown Execution


*** Test Cases ***

Verify User Initiated BMC Dump When Host Powered Off
    [Documentation]  Create user initiated BMC dump at host off state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Powered_Off

    Redfish Power Off  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


Verify User Initiated BMC Dump When Host Booted
    [Documentation]  Create user initiated BMC dump at host booted state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Booted

    Redfish Power On  stack_mode=skip
    ${dump_id}=  Create User Initiated BMC Dump
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id}


Verify Dump Persistency On Service Restart
    [Documentation]  Create user dump, restart BMC service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Service_Restart

    Create User Initiated BMC Dump
    ${dump_entries_before}=  Get BMC Dump Entries

    # Restart dump service.
    BMC Execute Command  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly

    ${dump_entries_after}=  Get BMC Dump Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Verify Dump Persistency On Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_Reset

    Create User Initiated BMC Dump
    ${dump_entries_before}=  Get BMC Dump Entries

    # Reset BMC.
    OBMC Reboot (off)

    ${dump_entries_after}=  Get BMC Dump Entries
    Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Delete User Initiated BMC Dump And Verify
    [Documentation]  Delete user initiated dump and verify.
    [Tags]  Delete_User_Initiated_BMC_Dump_And_Verify

    ${dump_id}=  Create User Initiated BMC Dump
    Delete Dump  ${dump_id}

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  0


Create Two User Initiated BMC Dumps
    [Documentation]  Create two user initieated BMC dumps.
    [Tags]  Create_Two_User_Initiated_BMC_Dumps

    ${dump_id1}=  Create User Initiated BMC Dump
    ${dump_id2}=  Create User Initiated BMC Dump

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  2
    Should Contain  ${dump_entries}  ${dump_id1}  ${dump_id2}


Create Two User Initiated BMC Dumps And Delete One
    [Documentation]  Create two dumps and delete the first.
    [Tags]  Create_Two_User_Initiated_BMC_Dumps_And_Delete_One

    ${dump_id1}=  Create User Initiated BMC Dump
    ${dump_id2}=  Create User Initiated BMC Dump

    Delete Dump  ${dump_id1}

    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1
    List Should Contain Value  ${dump_entries}  ${dump_id2}


Create And Delete User Initiated BMC Dump Multiple Times
    [Documentation]  Create and delete user initiated BMC dump multiple times.
    [Tags]  Create_And_Delete_User_Initiated_BMC_Dump_Multiple_Times

    FOR  ${INDEX}  IN  1  5
      ${dump_id}=  Create User Initiated BMC Dump
      Delete Dump  ${dump_id}
    END


Delete All User Initiated BMC Dumps And Verify
    [Documentation]  Delete all user initiated BMC dumps and verify.
    [Tags]  Delete_All_User_Initiated_BMC_Dumps_And_Verify

    # Create some dump.
    Create User Initiated BMC Dump
    Create User Initiated BMC Dump

    Delete All Dumps
    ${dump_entries}=  Get BMC Dump Entries
    Should Be Empty  ${dump_entries}


*** Keywords ***

Create User Initiated BMC Dump
    [Documentation]  Generate user initiated BMC dump and return
    ...  the dump id number (e.g., "5").

    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    ${resp}=  redfish.Post  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}]

    Wait Until Keyword Succeeds  5 min  15 sec  Is Task Completed  ${resp.dict['Id']}
    ${task_details}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${resp.dict['Id']}

    ${resp}=  Set Variable  ${task_details["Payload"]["HttpHeaders"]} 
    ${dump_id}=  Fetch From Right  ${resp[5]}  /

    [Return]  ${dump_id}


Is Task Completed
    [Documentation]  Verify if the given task is completed.
    [Arguments]   ${task_id}

    # Description of argument(s):
    # task_id        Id of task which needs to be checked.

    ${task_details}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    Should Be Equal As Strings  ${task_details['TaskState']}  Completed


Test Teardown Execution
    [Documentation]  Do post test teardown operation.

    FFDC On Test Case Fail
    Close All Connections


Delete All Dumps
    [Documentation]  Delete all BMC dumps.

    # Check if dump entries exist, if not return.
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
    Return From Keyword If  ${resp.dict["Members@odata.count"]} == ${0}

    # Get the list of dump entries and delete them all.
    ${dump_entries}=  Redfish_Utils.List Request  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
    FOR  ${entry}  IN  @{dump_entries}
        ${dump_id}=  Fetch From Right  ${entry}  /
        Delete Dump  ${dump_id}
    END


Delete Dump
    [Documentation]  Deletes a given BMC dump.
    [Arguments]  ${dump_id}

    # Description of Argument(s):
    # dump_id  An integer value that identifies a particular dump (e.g. 1, 3).

    Redfish.Delete  /redfish/v1/Managers/bmc/LogServices/Dump/Entries/${dump_id}


Get BMC Dump Entries
    [Documentation]  Return list of dump entries.

    ${dump_id_list}=  Create List
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc/LogServices/Dump/Entries

    FOR  ${entry}  IN RANGE  0  ${resp.dict["Members@odata.count"]}
      ${dump_uri}=  Set Variable  ${resp.dict["Members"][${entry}]["@odata.id"]}
      ${dump_id}=  Fetch From Right  ${dump_uri}  /
      Append To List  ${dump_id_list}  ${dump_id}
    END

    [Return]  ${dump_id_list}
