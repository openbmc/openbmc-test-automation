*** Settings ***
Documentation    Test BMC manager time functionality.
Resource                     ../../lib/resource.robot
Resource                     ../../lib/bmc_redfish_resource.robot
Resource                     ../../lib/common_utils.robot
Resource                     ../../lib/openbmc_ffdc.robot
Resource                     ../../lib/utils.robot

Test Setup                   Run Keywords  Printn  AND  redfish.Login
Test Teardown                Test Teardown Execution

*** Variables ***
${max_time_diff_in_seconds}  6

*** Test Cases ***

Verify Redfish BMC Time
    [Documentation]  Verify that date/time obtained via redfish matches
    ...  date/time obtained via BMC command line.
    [Tags]  Verify_Redfish_BMC_Time

    ${redfish_date_time}=  Redfish Get DateTime
    ${cli_date_time}=  CLI Get BMC DateTime
    ${time_diff}=  Subtract Date From Date  ${cli_date_time}
    ...  ${redfish_date_time}
    ${time_diff}=  Evaluate  abs(${time_diff})
    Rprint Vars  redfish_date_time  cli_date_time  time_diff
    Should Be True  ${time_diff} < ${max_time_diff_in_seconds}
    ...  The difference between Redfish time and CLI time exceeds the allowed time difference.


Verify Set Time Using Redfish
    [Documentation]  Verify set time using redfish API.
    [Tags]  Verify_Set_Time_Using_Redfish

    ${old_bmc_time}=  CLI Get BMC DateTime
    # Add 3 days to current date
    ${new_bmc_time}=  Add Time to Date  ${old_bmc_time}  3 days
    Redfish Set DateTime  ${new_bmc_time}
    ${cli_bmc_time}=  CLI Get BMC DateTime
    ${time_diff}=  Subtract Date From Date  ${cli_bmc_time}
    ...  ${new_bmc_time}
    ${time_diff}=  Evaluate  abs(${time_diff})
    Rprint Vars   old_bmc_time  new_bmc_time  cli_bmc_time  time_diff  max_time_diff_in_seconds
    Should Be True  ${time_diff} < ${max_time_diff_in_seconds}
    ...  The difference between Redfish time and CLI time exceeds the allowed time difference.
    Validate Set DateTime  ${new_bmc_time}  ${old_bmc_time}  3
    # Setting back to old bmc time
    Redfish Set DateTime  ${old_bmc_time}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


Redfish Get DateTime
    [Documentation]  Returns BMC Datetime value from Redfish.

    ${date_time}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/bmc  DateTime
    [Return]  ${date_time}


Redfish Set DateTime
    [Documentation]  Set DateTime using Redfish.
    [Arguments]  ${date_time_to_set}
    # Description of argument(s):
    # date_time_to_set          New time to set for BMC (eg. 2019-06-30 09:21:28).

    ${payload}=  Create Dictionary  DateTime=${date_time_to_set}
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/bmc  body=&{payload}
    ...  valid_status_codes=[200, 400]


Validate Set DateTime
    [Documentation]  Verify Set DateTime works fine.
    [Arguments]  ${new_time}  ${old_time}  ${no_of_days}
    # Description of argument(s):
    # new_time            New time to set for BMC (eg. 2019-06-30 09:21:28).
    # old_time            BMC old time (eg. 2019-06-27 09:21:28).
    # no_of_days          Number of days to add from current date (eg. 3).


    ${time_diff}=  Subtract Date From Date  ${new_time}
    ...  ${old_time}  verbose
    Should Be Equal  ${time_diff}  3 days
    ...  msg=Time difference ${time_diff} not 3 days as expected.
