*** Settings ***
Documentation    Test BMC Manager time functionality.
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
    ...  date/time obtained via command line.
    [Tags]  Verify_Redfish_BMC_Time

    ${redfish_date_time}=  Get BMC DateTime Using Redfish
    ${cli_date_time}=  CLI Get BMC DateTime
    ${time_diff}=  Subtract Date From Date  ${cli_date_time}
    ...  ${redfish_date_time}
    ${time_diff}=  Evaluate  abs(${time_diff})
    Rprint Vars  redfish_date_time  cli_date_time  time_diff
    Should Be True  ${time_diff} < ${max_time_diff_in_seconds}
    ...  The difference between Redfish time and CLI time exceeds the allowed time difference.


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


Get BMC Time Using Date Command
    [Documentation]  Returns BMC time from date command

    ${bmc_time_via_date}  ${stderr}  ${rc}=  BMC Execute Command  date "+%m/%d/%Y %H:%M:%S"
    ${resp}=  Convert Date  ${bmc_time_via_date}  date_format=%m/%d/%Y %H:%M:%S
    ...  exclude_millis=yes
    Should Not Be Empty  ${resp}

    [Return]  ${resp}

Get BMC DateTime Using Redfish
    [Documentation]  Returns BMC Datetime value from Redfish

    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    [Return]  ${resp.dict["DateTime"]}
