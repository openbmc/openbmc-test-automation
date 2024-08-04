*** Settings ***
Documentation    Test BMC manager time functionality.
Resource                     ../../lib/openbmc_ffdc.robot
Resource                     ../../lib/bmc_date_and_time_utils.robot

Test Setup                   Printn
Test Teardown                Test Teardown Execution
Suite Setup                  Suite Setup Execution
Suite Teardown               Suite Teardown Execution

Test Tags                   Managers_BMC_Time

*** Variables ***

${max_time_diff_in_seconds}  6
# The "offset" consists of the value "26" specified for hours.  Redfish will
# convert that to the next day + 2 hours.
${date_time_with_offset}     2019-04-25T26:24:46+00:00
${expected_date_time}        2019-04-26T02:24:46+00:00
${invalid_datetime}          "2019-04-251T12:24:46+00:00"

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

    Set Time To Manual Mode

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


Verify Set DateTime With Offset Using Redfish
    [Documentation]  Verify set DateTime with offset using redfish API.
    [Tags]  Verify_Set_DateTime_With_Offset_Using_Redfish
    [Teardown]  Run Keywords  Redfish Set DateTime  AND  FFDC On Test Case Fail

    Redfish Set DateTime  ${date_time_with_offset}
    ${cli_bmc_time}=  CLI Get BMC DateTime

    ${date_time_diff}=  Subtract Date From Date  ${cli_bmc_time}
    ...  ${expected_date_time}  exclude_millis=yes
    ${date_time_diff}=  Convert to Integer  ${date_time_diff}
    Rprint Vars  date_time_with_offset  expected_date_time  cli_bmc_time
    ...  date_time_diff  max_time_diff_in_seconds
    Valid Range  date_time_diff  0  ${max_time_diff_in_seconds}


Verify Set DateTime With Invalid Data Using Redfish
    [Documentation]  Verify error while setting invalid DateTime using Redfish.
    [Tags]  Verify_Set_DateTime_With_Invalid_Data_Using_Redfish

    Redfish Set DateTime  ${invalid_datetime}  valid_status_codes=[${HTTP_BAD_REQUEST}]


Verify DateTime Persists After Reboot
    [Documentation]  Verify date persists after BMC reboot.
    [Tags]  Verify_DateTime_Persists_After_Reboot

    # Synchronize BMC date/time to local system date/time.
    ${local_system_time}=  Get Current Date
    Redfish Set DateTime  ${local_system_time}
    Redfish OBMC Reboot (off)
    Redfish.Login
    ${bmc_time}=  CLI Get BMC DateTime
    ${local_system_time}=  Get Current Date
    ${time_diff}=  Subtract Date From Date  ${bmc_time}
    ...  ${local_system_time}
    ${time_diff}=  Evaluate  abs(${time_diff})
    Rprint Vars   local_system_time  bmc_time  time_diff  max_time_diff_in_seconds
    Should Be True  ${time_diff} < ${max_time_diff_in_seconds}
    ...  The difference between Redfish time and CLI time exceeds the allowed time difference.


Verify Immediate Consumption Of BMC Date
    [Documentation]  Verify immediate change in BMC date time.
    [Tags]  Verify_Immediate_Consumption_Of_BMC_Date
    [Setup]  Run Keywords  Set Time To Manual Mode  AND
    ...  Redfish Set DateTime  valid_status_codes=[${HTTP_OK}]
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish Set DateTime  valid_status_codes=[${HTTP_OK}]
    [Template]  Set BMC Date And Verify

    # host_state
    on
    off



*** Keywords ***


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail


Suite Setup Execution
    [Documentation]  Do the suite level setup.

    Printn
    Redfish.Login
    Get NTP Initial Status
    ${old_date_time}=  CLI Get BMC DateTime
    ${year_status}=  Run Keyword And Return Status  Should Not Contain  ${old_date_time}  ${year_without_ntp}
    Run Keyword If  ${year_status} == False
    ...  Enable NTP And Add NTP Address
    Set Time To Manual Mode


Suite Teardown Execution
    [Documentation]  Do the suite level teardown.

    Set Time To Manual Mode
    Restore NTP Status
    Redfish.Logout
