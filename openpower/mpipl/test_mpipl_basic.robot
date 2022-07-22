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
Test Setup       Test SetupExecution
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
    ${payload} =  Create Dictionary
    ...  DiagnosticDataType=OEM  OEMDiagnosticDataType=System
    Redfish.Post  ${DUMP_URI}/Actions/LogService.CollectDiagnosticData  body=&{payload}
    ...  valid_status_codes=[${HTTP_ACCEPTED}]


Required Dumps Should Exist
    [Documentation]  Check for BMC and system dump.

    #   {
    #       "@odata.id": "/redfish/v1/Managers/bmc/LogServices/Dump/Entries/4",
    #       "@odata.type": "#LogEntry.v1_8_0.LogEntry",
    #       "AdditionalDataSizeBytes": 914254,
    #       "AdditionalDataURI": "/redfish/v1/Managers/bmc/LogServices/Dump/Entries/4/attachment",
    #       "Created": "2022-07-22T03:36:23+00:00",
    #       "DiagnosticDataType": "Manager",
    #       "EntryType": "Event",
    #       "Id": "4",
    #       "Name": "BMC Dump Entry"
    #   }
    ${bmc_dump}=  Redfish.Get Properties  /redfish/v1/Managers/bmc/LogServices/Dump/Entries
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
