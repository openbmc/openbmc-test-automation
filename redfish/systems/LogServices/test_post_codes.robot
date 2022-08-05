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
