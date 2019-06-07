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
    # Add 3 days to current date.
    ${new_bmc_time}=  Add Time to Date  ${old_bmc_time}  3 Days
    Redfish Set DateTime  ${new_bmc_time}
    ${cli_bmc_time}=  CLI Get BMC DateTime
    ${time_diff}=  Subtract Date From Date  ${cli_bmc_time}
    ...  ${new_bmc_time}
    ${time_diff}=  Evaluate  abs(${time_diff})
    Rprint Vars   old_bmc_time  new_bmc_time  cli_bmc_time  time_diff  max_time_diff_in_seconds
    Should Be True  ${time_diff} < ${max_time_diff_in_seconds}
    ...  The difference between Redfish time and CLI time exceeds the allowed time difference.
    # Setting back to old bmc time.
    Redfish Set DateTime  ${old_bmc_time}


Verify Set DateTime With Invalid Data Using Redfish
    [Documentation]  Verify set DateTime with invalid data using redfish API.
    [Tags]  Verify_Set_DateTime_With_Invalid_Data_Using_Redfish

    ${invalid_bmc_time}=  Set Variable  "2019-04-251T12:24:46+00:00"
    ${return_resp}=  Redfish Set DateTime  ${invalid_bmc_time}
    ${return_resp}=  Convert To String  ${return_resp}
    Rprint Vars  return_resp  HTTP_BAD_REQUEST
    Should Be Equal  ${return_resp}  ${HTTP_BAD_REQUEST}
    ...  Invalid DateTime is accepted.


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
    [Arguments]  ${date_time}
    # Description of argument(s):
    # date_time          New time to set for BMC (eg. 2019-06-30 09:21:28).

    ${payload}=  Create Dictionary  DateTime=${date_time}
    ${resp}=  Redfish.Patch  ${REDFISH_BASE_URI}Managers/bmc  body=&{payload}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_BAD_REQUEST}]
    [Return]  ${resp.status}


