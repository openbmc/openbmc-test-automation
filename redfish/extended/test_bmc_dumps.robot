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
    Create User Initiated Dump
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1


Verify User Initiated BMC Dump When Host Booted
    [Documentation]  Create user initiated BMC dump at host booted state and
    ...  verify dump entry for it.
    [Tags]  Verify_User_Initiated_BMC_Dump_When_Host_Booted

    Redfish Power On  stack_mode=skip
    Create User Initiated Dump
    ${dump_entries}=  Get BMC Dump Entries
    Length Should Be  ${dump_entries}  1


Verify Dump Persistency On Service Restart
    [Documentation]  Create user dump, restart BMC service and verify dump
    ...  persistency.
    [Tags]  Verify_Dump_Persistency_On_Service_Restart

    Create User Initiated Dump
    ${dump_entries_before}=  Get BMC Dump Entries

    # Restart dump service.
    BMC Execute Command  systemctl restart xyz.openbmc_project.Dump.Manager.service
    Sleep  10s  reason=Wait for BMC dump service to restart properly

    ${dump_entries_after}=  Get BMC Dump Entries
    Collections.Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


Verify Dump Persistency On Reset
    [Documentation]  Create user dump, reset BMC and verify dump persistency.
    [Tags]  Verify_Dump_Persistency_On_Reset

    Create User Initiated Dump
    ${dump_entries_before}=  Get BMC Dump Entries

    # Reset BMC.
    OBMC Reboot (off)

    ${dump_entries_after}=  Get BMC Dump Entries
    Collections.Lists Should Be Equal  ${dump_entries_before}  ${dump_entries_after}


*** Keywords ***

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
