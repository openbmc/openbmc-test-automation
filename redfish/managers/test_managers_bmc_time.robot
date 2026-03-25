*** Settings ***
Documentation        Test BMC manager time and timezone functionality.

Resource             ../../lib/openbmc_ffdc.robot
Resource             ../../lib/bmc_date_and_time_utils.robot
Library              ../../lib/bmc_ssh_utils.py

Test Setup           Printn
Test Teardown        Test Teardown Execution
Suite Setup          Suite Setup Execution
Suite Teardown       Suite Teardown Execution

Test Tags            Managers_BMC_Time

*** Variables ***

${max_time_diff_in_seconds}  6
${date_time_with_offset}     2019-04-25T26:24:46+00:00
${invalid_datetime}          2019-04-251T12:24:46+00:00

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
    [Documentation]  Verify error while setting DateTime with offset using redfish API.
    [Tags]  Verify_Set_DateTime_With_Offset_Using_Redfish
    [Teardown]  Run Keywords  Redfish Set DateTime  AND  FFDC On Test Case Fail

    Redfish Set DateTime  ${date_time_with_offset}  invalid


Verify Set DateTime With Invalid Data Using Redfish
    [Documentation]  Verify error while setting invalid DateTime using Redfish.
    [Tags]  Verify_Set_DateTime_With_Invalid_Data_Using_Redfish

    Redfish Set DateTime  ${invalid_datetime}  invalid


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
    ...  Redfish Set DateTime
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Redfish Set DateTime
    [Template]  Set BMC Date And Verify

    # host_state
    on
    off


Verify BMC Timezone Properties Are Exposed
    [Documentation]  Verify TimeZoneName, DateTimeLocalOffset and DateTime offset are exposed.
    [Tags]  Verify_BMC_Timezone_Properties_Are_Exposed

    ${tz}=  Redfish Get TimeZoneName
    Should Not Be Empty  ${tz}
    ${offset}=  Redfish Get DateTimeLocalOffset
    Should Not Be Empty  ${offset}
    ${dt}=  Redfish Get DateTime
    Should Match Regexp  ${dt}  .*[+-]\\d{2}:\\d{2}$


Verify Set Timezone
    [Documentation]  Set different timezones and verify properties.
    [Tags]  Verify_Set_Timezone
    [Template]  Set Timezone And Verify Offset

    # timezone        expected_offset
    Asia/Tokyo        +09:00
    Australia/Darwin  +09:30
    Etc/UTC           +00:00


Verify Set Timezone To Negative Offset
    [Documentation]  Set timezone to Etc/GMT-8 and verify positive offset.
    [Tags]  Verify_Set_Timezone_To_Negative_Offset
    [Template]  Set Timezone And Verify Offset

    # timezone     expected_offset
    Etc/GMT-8      +08:00


Verify Set Invalid Timezone Is Rejected
    [Documentation]  Verify that setting an invalid timezone is rejected.
    [Tags]  Verify_Set_Invalid_Timezone_Is_Rejected

    ${original_tz}=  Redfish Get TimeZoneName
    Redfish Set TimeZoneName  Invalid/Timezone
    ...  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR}]
    ${current_tz}=  Redfish Get TimeZoneName
    Should Be Equal As Strings  ${current_tz}  ${original_tz}


Verify DateTime Offset Does Not Change Timezone
    [Documentation]  Verify setting DateTime with UTC offset does not change timezone.
    [Tags]  Verify_DateTime_Offset_Does_Not_Change_Timezone

    # Set timezone to Asia/Tokyo (+09:00).
    Redfish Set TimeZoneName  Asia/Tokyo

    # Get current UTC time and PATCH DateTime with +00:00 offset.
    ${utc_time}=  Get Current Date  time_zone=UTC
    ${utc_formatted}=  Convert Date  ${utc_time}
    ...  result_format=%Y-%m-%dT%H:%M:%S+00:00
    Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}
    ...  body={'DateTime': '${utc_formatted}'}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    # Verify timezone and offset are unchanged.
    ${tz}=  Redfish Get TimeZoneName
    Should Be Equal As Strings  ${tz}  Asia/Tokyo
    ${offset}=  Redfish Get DateTimeLocalOffset
    Should Be Equal As Strings  ${offset}  +09:00
    ${dt}=  Redfish Get DateTime
    Should End With  ${dt}  +09:00

    # Verify time was correctly converted (local = UTC + 9 hours).
    ${local_from_redfish}=  Convert Date  ${dt}  result_format=epoch  date_format=%Y-%m-%dT%H:%M:%S%z
    ${utc_epoch}=  Convert Date  ${utc_time}  result_format=epoch
    ${time_diff}=  Evaluate  abs(${local_from_redfish} - ${utc_epoch})
    Should Be True  ${time_diff} < ${max_time_diff_in_seconds}


Verify CLI Timezone Matches Redfish
    [Documentation]  Verify BMC CLI timezone matches Redfish after setting timezone.
    [Tags]  Verify_CLI_Timezone_Matches_Redfish

    Redfish Set TimeZoneName  Asia/Tokyo

    # Verify /etc/localtime symlink points to Asia/Tokyo.
    ${localtime_link}  ${stderr}  ${rc}=  BMC Execute Command
    ...  readlink -f /etc/localtime
    Should Contain  ${localtime_link}  Asia/Tokyo

    # Verify date command reports +0900 offset (busybox date uses %z without colon).
    ${cli_offset}  ${stderr}  ${rc}=  BMC Execute Command  date +%z
    Should Be Equal As Strings  ${cli_offset}  +0900


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail


Set Timezone And Verify Offset
    [Documentation]  Set timezone and verify Redfish properties.
    [Arguments]  ${timezone}  ${expected_offset}
    # Description of argument(s):
    # timezone         IANA timezone name to set (e.g. "Asia/Tokyo").
    # expected_offset  Expected UTC offset string (e.g. "+09:00").

    Redfish Set TimeZoneName  ${timezone}
    ${tz}=  Redfish Get TimeZoneName
    Should Be Equal As Strings  ${tz}  ${timezone}
    ${offset}=  Redfish Get DateTimeLocalOffset
    Should Be Equal As Strings  ${offset}  ${expected_offset}
    ${dt}=  Redfish Get DateTime
    Should End With  ${dt}  ${expected_offset}


Suite Setup Execution
    [Documentation]  Do the suite level setup.

    Printn
    Redfish.Login
    Get NTP Initial Status
    ${old_date_time}=  CLI Get BMC DateTime
    ${year_status}=  Run Keyword And Return Status  Should Not Contain  ${old_date_time}  ${year_without_ntp}
    IF  ${year_status} == False
        Run Keyword And Ignore Error  Enable NTP And Add NTP Address
    END
    Run Keyword And Ignore Error  Set Time To Manual Mode
    # Save original timezone for restoration in teardown.
    ${original_timezone}=  Redfish Get TimeZoneName
    Set Suite Variable  ${original_timezone}


Suite Teardown Execution
    [Documentation]  Do the suite level teardown.

    # Restore original timezone.
    Run Keyword And Ignore Error  Redfish Set TimeZoneName  ${original_timezone}
    Run Keyword And Ignore Error  Set Time To Manual Mode
    Run Keyword And Ignore Error  Restore NTP Status
    Redfish.Logout
