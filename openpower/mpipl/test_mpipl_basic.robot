*** Settings ***
Documentation    Test MPIPL (Memory preserving IPL).

#------------------------------------------------------------------
# This boot path will generated a BMC dump followed by system dump.
#------------------------------------------------------------------

Resource         ../../lib/resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/boot_utils.robot

Suite Setup      Redfish.Login
Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Suite Teardown Execution

*** Variables ***

# By default 1 iteration, user can key in nth number of iteration to control
# how many time it needs MPIPL test runs.
${MPIPL_LOOP_COUNT}     ${1}


** Test Cases **

Trigger User Tool Initiated MPIPL
    [Documentation]  Trigger And Verify user tool initiated dump using
    ...              obmc-host-crash target.
    [Tags]  Trigger_User_Tool_Initiated_MPIPL

    FOR  ${count}  IN RANGE  0  ${MPIPL_LOOP_COUNT}
        Log To Console   MPIPL LOOP_COUNT:${count} execution.
        Tool Initd MP Reboot
        Required Dumps Should Exist
    END


Trigger User Initiated MPIPL Using Redfish
    [Documentation]  Verify redfish triggered MPIPL flow using diagnostic
    ...              mode target.
    [Tags]  Trigger_User_Initiated_MPIPL_Using_Redfish

    FOR  ${count}  IN RANGE  0  ${MPIPL_LOOP_COUNT}
        Log To Console   MPIPL LOOP_COUNT:${count} execution.
        Redfish Initiated MPIPL
        Required Dumps Should Exist
    END


*** Keywords ***


Test Setup Execution
    [Documentation]  Do the post test setup cleanup.

    Test System Cleanup
    Run Keyword And Ignore Error  Clear All Subscriptions


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Test System Cleanup
    Run Keyword And Ignore Error  Delete All Redfish Sessions


Test System Cleanup
    [Documentation]  Cleanup errors before exiting.

    Run Keyword And Ignore Error  Redfish Purge Event Log
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Delete All System Dumps


Redfish Initiated MPIPL
    [Documentation]  Trigger redfish triggered MPIPL flow.

    # Power on
    Redfish Power On

    # Trigger MPIPL
    Log To Console  Trigger System dump
    ${payload} =  Create Dictionary
    ...  DiagnosticDataType=OEM  OEMDiagnosticDataType=System
    Redfish.Post  ${DUMP_URI}/Actions/LogService.CollectDiagnosticData  body=&{payload}
    ...  valid_status_codes=[${HTTP_ACCEPTED}]

    Sleep  10s

    Log To Console  Wait for system to transition DiagnosticMode
    Wait Until Keyword Succeeds  2 min  3 sec  Is Boot Progress Changed

    Log To Console  Wait for system to transition path DiagnosticMode to Runtime.
    Wait Until Keyword Succeeds  10 min  20 sec  Is Boot Progress Runtime Matched


Is Boot Progress Runtime Matched
    [Documentation]  Get BootProgress state and expect boot state mismatch.

    # Match any of the BootProgress state SystemHardwareInitializationComplete|OSBootStarted|OSRunning
    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress
    Should Contain Any  ${boot_progress}  SystemHardwareInitializationComplete  OSBootStarted  OSRunning


Required Dumps Should Exist
    [Documentation]  Check for BMC and system dump.

    #   {
    #       "@odata.id": "/redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/4",
    #       "@odata.type": "#LogEntry.v1_8_0.LogEntry",
    #       "AdditionalDataSizeBytes": 914254,
    #       "AdditionalDataURI": "/redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries/4/attachment",
    #       "Created": "2022-07-22T03:36:23+00:00",
    #       "DiagnosticDataType": "Manager",
    #       "EntryType": "Event",
    #       "Id": "4",
    #       "Name": "BMC Dump Entry"
    #   }
    ${bmc_dump}=  Redfish.Get Properties  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries
    Log To Console  BMC dumps generated: ${bmc_dump['Members@odata.count']}
    Should Be True  ${bmc_dump['Members@odata.count']} >= 1  msg=No BMC dump generated.

    #"Members": [
    #   {
    #       "@odata.id": "/redfish/v1/Systems/system/LogServices/Dump/Entries/System_1",
    #       "@odata.type": "#LogEntry.v1_8_0.LogEntry",
    #       "AdditionalDataSizeBytes": 2363839216,
    #       "AdditionalDataURI": "/redfish/v1/Systems/system/LogServices/Dump/Entries/System_1/attachment",
    #       "Created": "2022-07-22T03:38:58+00:00",
    #       "DiagnosticDataType": "OEM",
    #       "EntryType": "Event",
    #       "Id": "System_1",
    #       "Name": "System Dump Entry",
    #       "OEMDiagnosticDataType": "System"
    #   }
    ${sys_dump}=  Redfish.Get Properties  /redfish/v1/Systems/system/LogServices/Dump/Entries
    Log To Console  System dump generated: ${sys_dump['Members@odata.count']}
    Should Be True  ${sys_dump['Members@odata.count']} == 1  msg=No system dump generated.


Clear All Subscriptions
    [Documentation]  Delete all subscriptions.

    ${subscriptions}=  Redfish.Get Attribute  /redfish/v1/EventService/Subscriptions  Members
    FOR  ${subscription}  IN  @{subscriptions}
        Redfish.Delete  ${subscription['@odata.id']}
    END
