*** Settings ***
Documentation    Test suite to verify BIOS POST code log entries.

Resource         ../../../lib/resource.robot
Resource         ../../../lib/bmc_redfish_resource.robot
Resource         ../../../lib/openbmc_ffdc.robot
Resource         ../../../lib/logging_utils.robot

Suite Setup      Suite Setup Execution
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Suite Teardown Execution

Force Tags       Post_Codes

*** Variables ***
${max_view_count}    1000


*** Test Cases ***

Test PostCodes When Host Boots
    [Documentation]  Boot the system and verify PostCodes from host are logged.
    [Tags]  Test_PostCodes_When_Host_Boots

    Redfish Power On
    ${post_code_list}=  Redfish Get PostCodes
    Rprint Vars  post_code_list

    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    Log To Console  BIOS POST Codes count: ${post_codes['Members@odata.count']}
    Should Be True  ${post_codes['Members@odata.count']} >= 1  msg=No BIOS POST Codes populated.


Test PostCodes When Host Reboot
    [Documentation]  Initiate Host reboot the system and verify PostCodes from host are logged.
    [Tags]  Test_PostCodes_When_Host_Reboot

    # Boot to runtime and clear post codes.
    Redfish Power On  stack_mode=skip
    Redfish Clear PostCodes

    RF SYS GracefulRestart
    ${post_code_list}=  Redfish Get PostCodes
    Rprint Vars  post_code_list

    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    Log To Console  BIOS POST Codes count: ${post_codes['Members@odata.count']}
    Should Be True  ${post_codes['Members@odata.count']} >= 1  msg=No BIOS POST Codes populated.


Test PostCodes When Host Powered Off
    [Documentation]  Power off the system and verify PostCodes from host are logged.
    [Tags]  Test_PostCodes_When_Host_Powered_Off

    # Boot to runtime and clear post codes.
    Redfish Power On  stack_mode=skip
    Redfish Clear PostCodes

    Redfish Power Off
    ${post_code_list}=  Redfish Get PostCodes
    Rprint Vars  post_code_list

    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    Log To Console  BIOS POST Codes count: ${post_codes['Members@odata.count']}
    Should Be True  ${post_codes['Members@odata.count']} == 0
    ...  msg=BIOS POST Codes populated.


Test PostCode Id Value Incremented On Host Reboot
    [Documentation]  Verify the value of ID in postcode entry is incremented
    ...  on host reboot. In the ID value 'B2-49', '2' represents
    ...  the boot cycle count of the host system.
    [Tags]  Test_PostCode_Id_Value_Incremented_On_Host_Reboot
    [Setup]  Populate PostCode Logs Incase No Prior Entries Available

    # Get boot count of current postcode logs.
    ${initial_boot_count}=  Get Boot Count For Last PostCode Entry
    ${expected_boot_count}=  Evaluate  ${initial_boot_count} + 1

    # Perform host reboot and verify boot count incremented in ID value.
    RF SYS GracefulRestart
    ${current_boot_count}=  Get Boot Count For Last PostCode Entry
    Should Be True  ${current_boot_count} == ${expected_boot_count}


Test PostCode Log Perisistency After BMC Reboot
    [Documentation]  Verify the post code log entries persist after BMC reboot.
    [Tags]  Test_PostCode_Log_Perisistency_After_BMC_Reboot
    [Setup]  Populate PostCode Logs Incase No Prior Entries Available

    Redfish Power On  stack_mode=skip

    # Get log count before BMC reboot.
    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    ${initial_log_count}=  Set Variable  ${post_codes['Members@odata.count']}

    # Reboot BMC.
    OBMC Reboot (run)

    # Get log count after BMC reboot and compare with initial log count.
    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    ${current_log_count}=  Set Variable  ${post_codes['Members@odata.count']}
    Should Be True  ${current_log_count} == ${initial_log_count}


Test Clear Post Code Log Action
    [Documentation]  Verify clear log action for post code entries.
    [Tags]  Test_Clear_Post_Code_Log_Action
    [Setup]  Populate PostCode Logs Incase No Prior Entries Available

    # Perform clear postcode log action.
    Redfish Clear PostCodes
    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries

    # Verify if log count becomes zero.
    Should Be True  ${post_codes['Members@odata.count']} == 0
    ...  msg=BIOS POST code logs not cleared.


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test setup operation.

    Redfish.Login
    Redfish Clear PostCodes


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail


Suite Setup Execution
    [Documentation]  Do suite setup operation.

    Redfish.Login
    Redfish Power Off  stack_mode=skip

    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Purge Event Log
    Run Keyword And Ignore Error  Delete All Redfish Sessions


Suite Teardown Execution
    [Documentation]  Do suite teardown operation.

    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Purge Event Log
    Run Keyword And Ignore Error  Delete All Redfish Sessions


Get Boot Count For Last PostCode Entry
    [Documentation]  Get the latest boot count from post code log entry.
    ...  log entry has ID "B2-1000", latest boot count "2" is returned.

    # {
    #     "@odata.id": "/redfish/v1/Systems/system/LogServices/PostCodes/Entries",
    #     "@odata.type": "#LogEntryCollection.LogEntryCollection",
    #     "Description": "Collection of POST Code Log Entries",
    #     "Members": [
    #         {
    #             "@odata.id": "/redfish/v1/Systems/system/LogServices/PostCodes/Entries/B1-1000",
    #             "@odata.type": "#LogEntry.v1_8_0.LogEntry",
    #             "Created": "1970-01-01T00:16:40+00:00",
    #             "EntryType": "Event",
    #             "Id": "B2-1000",
    #             "Message": "Boot Count: 2; Time Stamp Offset: 117.4928 seconds; POST Code: 0xac10",
    #             "MessageArgs": [
    #                 "2",
    #                 "117.4928",
    #                 "0xac10"
    #             ],
    #             "MessageId": "OpenBMC.0.2.BIOSPOSTCode",
    #             "Name": "POST Code Log Entry",
    #             "Severity": "OK"
    #         }
    #     ],
    #     "Members@odata.count": 2240,
    #     "Members@odata.nextLink": "/redfish/v1/Systems/system/LogServices/PostCodes/Entries?$skip=1000",
    #     "Name": "BIOS POST Code Log Entries"
    # }
    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    ${total_log_count}=  Set Variable  ${post_codes['Members@odata.count']}

    IF  ${total_log_count} > ${max_view_count}
        ${skip_count}=  Evaluate  (${total_log_count}//${max_view_count})*${max_view_count}
        ${uri}=  Set Variable
        ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries?$skip=${skip_count}
        ${post_codes}=  Redfish.Get Properties  ${uri}
    END

    ${last_id}=  Set Variable  ${post_codes['Members'][-1]['Id']}
    ${last_id}=  Split String  ${last_id}  -
    ${boot_count}=  Set Variable  ${last_id[0][1]}

    Return From Keyword  ${boot_count}


Populate PostCode Logs Incase No Prior Entries Available
    [Documentation]  Trigger Redfish graceful restart action on host system
    ...  to populate postcode logs if there are no prior log entries.

    ${post_codes}=  Redfish.Get Properties
    ...  /redfish/v1/Systems/system/LogServices/PostCodes/Entries
    Run Keyword If  ${post_codes['Members@odata.count']} == 0
    ...  RF SYS GracefulRestart

