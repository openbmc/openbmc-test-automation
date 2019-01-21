*** Settings ***
Documentation          This suite is for testing System time in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/state_manager.robot
Resource               ../lib/resource.txt

Library                OperatingSystem
Library                DateTime

Test Setup             Open Connection And Log In
Test Teardown          Post Test Case Execution

Force Tags  Clock_Time

*** Variables ***
${SYSTEM_TIME_INVALID}      01/01/1969 00:00:00
${SYSTEM_TIME_VALID}        02/29/2016 09:10:00
${ALLOWED_TIME_DIFF}        3
# Equivalent epoch time for 02/17/2017 04:11:40
${SYSTEM_TIME_VALID_EPOCH}  ${1487304700000000}

*** Test Cases ***

Get System Time
    [Documentation]  Get system time using IPMI and verify that it matches
    ...              with BMC date time.
    [Tags]  Get_System_Time

    ${resp}=  Run IPMI Standard Command  sel time get
    ${ipmidate}=  Convert Date  ${resp}  date_format=%m/%d/%Y %H:%M:%S
    ...  exclude_millis=yes
    ${bmcdate}=  Get BMC Time Using IPMI
    ${diff}=  Subtract Date From Date  ${bmcdate}  ${ipmidate}
    ${diff}=  Convert To Number  ${diff}
    Should Be True  ${diff} < ${ALLOWED_TIME_DIFF}
    ...  Open BMC time does not match with IPMI sel time

Set Valid System Time
    [Documentation]  Set system time using IPMI and verify that it is
    ...              correctly set in BMC.
    [Tags]  Set_Valid_System_Time

    Set Time Owner  ${HOST_OWNER}
    Set Time Mode  ${MANUAL_MODE}

    ${resp}=  Run IPMI Standard Command  sel time set "${SYSTEM_TIME_VALID}"
    ${setdate}=  Convert Date  ${SYSTEM_TIME_VALID}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=yes
    ${bmcdate}=  Get BMC Time Using IPMI
    ${diff}=  Subtract Date From Date  ${bmcdate}  ${setdate}
    ${diff}=  Convert To Number  ${diff}
    Should Be True  ${diff} < ${ALLOWED_TIME_DIFF}
    ...  Open BMC time does not match with set time

Set Invalid System Time
    [Documentation]  Set system time with invalid time using IPMI and verify
    ...              that it should throw error.
    [Tags]  Set_Invalid_System_Time

    Set Time Owner  ${HOST_OWNER}
    Set Time Mode  ${MANUAL_MODE}

    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sel time set "${SYSTEM_TIME_INVALID}"
    Should Start With  ${msg}  Specified time could not be parsed

Set System Time with no time
    [Documentation]  Set system time with no time using IPMI and verify
    ...              that it should throw error.
    [Tags]  Set_System_Time_with_no_time

    Set Time Owner  ${HOST_OWNER}
    Set Time Mode  ${MANUAL_MODE}

    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  sel time set ""
    Should Start With  ${msg}  Specified time could not be parsed


Set BMC Time With BMC And Manual
    [Documentation]  Set BMC time when time owner is BMC and time mode is
    ...              manual.
    [Tags]  Set_BMC_Time_With_BMC_And_Manual
    [Template]  Set Time Using REST

    #Operation    Owner          Mode            Status  BMC Time  Host Time
    Set BMC Time  ${BMC_OWNER}   ${MANUAL_MODE}  ok      Set       Change


Set BMC Time With Both And Manual
    [Documentation]  Set BMC time when time owner is Both and time mode is
    ...              manual.
    [Tags]  Set_BMC_Time_With_Both_And_Manual
    [Template]  Set Time Using REST

    #Operation    Owner          Mode            Status  BMC Time  Host Time
    Set BMC Time  ${BOTH_OWNER}  ${MANUAL_MODE}  ok      Set       Change


Set BMC Time With Split And Manual
    [Documentation]  Set BMC time when time owner is Split and time mode is
    ...              manual.
    [Tags]  Set_BMC_Time_With_Split_And_Manual
    [Template]  Set Time Using REST

    #Operation    Owner           Mode            Status  BMC Time  Host Time
    Set BMC Time  ${SPLIT_OWNER}  ${MANUAL_MODE}  ok      Set       No Change


Set BMC Time With BMC And NTP
    [Documentation]  Set BMC time when time owner is BMC and time mode is
    ...              NTP.
    [Tags]  Set_BMC_Time_With_BMC_And_NTP
    [Template]  Set Time Using REST

    #Operation    Owner           Mode            Status  BMC Time  Host Time
    Set BMC Time  ${BMC_OWNER}    ${NTP_MODE}     error   Not Set   No Change


Set BMC Time With Host And Manual
    [Documentation]  Set BMC time when time owner is Host and time mode is
    ...              Manual.
    [Tags]  Set_BMC_Time_With_Host_And_Manual
    [Template]  Set Time Using REST

    #Operation    Owner           Mode            Status  BMC Time  Host Time
    Set BMC Time  ${HOST_OWNER}   ${MANUAL_MODE}  error   Not Set   No Change


Set BMC Time With Both And NTP
    [Documentation]  Set BMC time when time owner is Both and time mode is
    ...              NTP.
    [Tags]  Set_BMC_Time_With_Both_And_NTP
    [Template]  Set Time Using REST

    #Operation    Owner           Mode            Status  BMC Time  Host Time
    Set BMC Time  ${BOTH_OWNER}   ${NTP_MODE}     error   Not Set   No Change


Set BMC Time With Split And NTP
    [Documentation]  Set BMC time when time owner is Split and time mode is
    ...              NTP.
    [Tags]  Set_BMC_Time_With_Split_And_NTP
    [Template]  Set Time Using REST

    #Operation    Owner           Mode            Status  BMC Time  Host Time
    Set BMC Time  ${SPLIT_OWNER}  ${NTP_MODE}     error   Not Set   No Change


Set BMC Time With Host And NTP
    [Documentation]  Set BMC time when time owner is Host and time mode is
    ...              NTP.
    [Tags]  Set_BMC_Time_With_Host_And_NTP
    [Template]  Set Time Using REST

    #Operation    Owner           Mode            Status  BMC Time  Host Time
    Set BMC Time  ${HOST_OWNER}   ${NTP_MODE}     error   Not Set   No Change


Set Host Time With Host And Manual
    [Documentation]  Set host time when time owner is host and time mode is
    ...              manual.
    [Tags]  Set_Host_Time_With_Host_And_Manual
    [Template]  Set Time Using REST

    #Operation     Owner          Mode            Status  BMC Time  Host Time
    Set Host Time  ${HOST_OWNER}  ${MANUAL_MODE}  ok      Change    Set


Set Host Time With Both And Manual
    [Documentation]  Set host time when time owner is both and time mode is
    ...              manual.
    [Tags]  Set_Host_Time_With_Both_And_Manual
    [Template]  Set Time Using REST

    #Operation     Owner          Mode            Status  BMC Time  Host Time
    Set Host Time  ${BOTH_OWNER}  ${MANUAL_MODE}  ok      Change    Set


Set Host Time With Both And NTP
    [Documentation]  Set host time when time owner is both and time mode is
    ...              NTP.
    [Tags]  Set_Host_Time_With_Both_And_NTP
    [Template]  Set Time Using REST

    #Operation     Owner           Mode           Status  BMC Time   Host Time
    Set Host Time  ${BOTH_OWNER}   ${NTP_MODE}    error   No Change  Not Set


Set Host Time With Split And Manual
    [Documentation]  Set host time when time owner is split and time mode is
    ...              manual.
    [Tags]  Set_Host_Time_With_Split_And_Manual
    [Template]  Set Time Using REST

    #Operation     Owner           Mode            Status  BMC Time   Host Time
    Set Host Time  ${SPLIT_OWNER}  ${MANUAL_MODE}  ok      No Change  Set


Set Host Time With Split And NTP
    [Documentation]  Set host time when time owner is split and time mode is
    ...              NTP.
    [Tags]  Set_Host_Time_With_Split_And_NTP
    [Template]  Set Time Using REST

    #Operation     Owner           Mode            Status   BMC Time   HOST Time
    Set Host Time  ${SPLIT_OWNER}  ${NTP_MODE}     ok       No Change  Set


Set Host Time With BMC And Manual
    [Documentation]  Set host time when time owner is BMC and time mode is
    ...              Manual.
    [Tags]  Set_Host_Time_With_BMC_And_Manual
    [Template]  Set Time Using REST

    #Operation     Owner           Mode            Status   BMC Time   HOST Time
    Set Host Time  ${BMC_OWNER}    ${MANUAL_MODE}  error    No Change  Not Set


Set Host Time With BMC Owner NTP
    [Documentation]  Set host time when time owner is BMC and time mode is
    ...              NTP.
    [Tags]  Set_Host_Time_With_BMC_And_NTP
    [Template]  Set Time Using REST

    #Operation     Owner           Mode            Status   BMC Time   HOST Time
    Set Host Time  ${BMC_OWNER}    ${NTP_MODE}     error    No Change  Not Set


Set Host Time With Host And NTP
    [Documentation]  Set host time when time owner is Host and time mode is
    ...              NTP.
    [Tags]  Set_Host_Time_With_Host_And_NTP
    [Template]  Set Time Using REST

    #Operation     Owner           Mode            Status  BMC Time    Host Time
    Set Host Time  ${HOST_OWNER}   ${NTP_MODE}     error   Not Change  No Set


Set Invalid Time Mode
    [Documentation]  Set time mode with invalid value using REST and verify
    ...              that it should throw error.
    [Tags]  Set_Invalid_Time_Mode

    ${timemode}=
    ...  Set Variable  xyz.openbmc_project.Time.Synchronization.Method.abc
    ${valueDict}=  Create Dictionary  data=${timemode}

    ${resp}=  OpenBMC Put Request
    ...  ${TIME_MANAGER_URI}sync_method/attr/TimeSyncMethod  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}
    Should Be Equal  ${jsondata['status']}  error

    ${mode}=  Read Attribute  ${TIME_MANAGER_URI}sync_method  TimeSyncMethod
    Should Not Be Equal  ${mode}
    ...  xyz.openbmc_project.Time.Synchronization.Method.abc

Set Invalid Time Owner
    [Documentation]  Set time owner with invalid value using REST and verify
    ...              that it should throw error.
    [Tags]  Set_Invalid_Time_Owner

    ${timeowner}=  Set Variable  xyz.openbmc_project.Time.Owner.Owners.xyz
    ${valueDict}=  Create Dictionary  data=${timeowner}

    ${resp}=  OpenBMC Put Request
    ...  ${TIME_MANAGER_URI}owner/attr/TimeOwner  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}
    Should Be Equal  ${jsondata['status']}  error

    ${owner}=  Read Attribute  ${TIME_MANAGER_URI}owner  TimeOwner
    Should Not Be Equal  ${owner}  xyz.openbmc_project.Time.Owner.Owners.xyz


*** Keywords ***

Get BMC Time Using IPMI
    [Documentation]  Returns BMC time of the system via IPMI

    ${stdout}  ${stderr}  ${output}=
    ...  Execute Command  date "+%m/%d/%Y %H:%M:%S"
    ...  return_stdout=True  return_stderr= True  return_rc=True
    Should Be Equal  ${output}  ${0}  msg=${stderr}

    ${resp}=  Convert Date  ${stdout}  date_format=%m/%d/%Y %H:%M:%S
    ...  exclude_millis=yes
    Should Not Be Empty  ${resp}
    [Return]  ${resp}


Set Time Via REST
    [Documentation]  Set time via REST.
    [Arguments]  ${operation}  ${status}
    # Description of argument(s):
    # operation    Set BMC/Host time
    # status       Expected status of set time operation

    ${time_owner_url}=  Set Variable If
    ...  '${operation}' == 'Set BMC Time'  ${TIME_MANAGER_URI}bmc
    ...  '${operation}' == 'Set Host Time'  ${TIME_MANAGER_URI}host

    ${valueDict}=  Create Dictionary  data=${SYSTEM_TIME_VALID_EPOCH}
    ${resp}=  OpenBMC Put Request
    ...  ${time_owner_url}/attr/Elapsed  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}
    Should Not Be Equal As Strings  ${jsondata['message']}  403 Forbidden
    Should Be Equal As Strings  ${jsondata['status']}  ${status}


Set Time Owner
    [Arguments]  ${args}
    [Documentation]  Set time owner of the system via REST

    ${timeowner}=  Set Variable  ${args}
    ${valueDict}=  Create Dictionary  data=${timeowner}

    ${resp}=  OpenBMC Put Request
    ...  ${TIME_MANAGER_URI}owner/attr/TimeOwner  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}

    ${host_state}=  Get Host State

    Run Keyword If  '${host_state}' == 'Off'
    ...  Log  System is in off state so owner change will get applied.
    ...  ELSE   Run keyword
    ...  Initiate Host PowerOff

    ${owner}=  Read Attribute  ${TIME_MANAGER_URI}owner  TimeOwner
    Should Be Equal  ${owner}  ${args}

    [Return]  ${jsondata['status']}


Set Time Mode
    [Arguments]  ${args}
    [Documentation]  Set time mode of the system via REST

    ${timemode}=  Set Variable  ${args}
    ${valueDict}=  Create Dictionary  data=${timemode}

    ${resp}=  OpenBMC Put Request
    ...  ${TIME_MANAGER_URI}sync_method/attr/TimeSyncMethod  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}
    Sleep  5s

    ${mode}=  Read Attribute  ${TIME_MANAGER_URI}sync_method  TimeSyncMethod
    Should Be Equal  ${mode}  ${args}


Get BMC Time Using REST
    [Documentation]  Returns BMC time of the system via REST
    ...              Time Format : epoch time in microseconds
    ...              e.g 1507809604687329

    ${resp}=  Read Attribute  ${TIME_MANAGER_URI}/bmc  Elapsed
    [Return]  ${resp}


Get HOST Time Using REST
    [Documentation]  Returns HOST time of the system via REST
    ...              Time Format : epoch time in microseconds
    ...              e.g 1507809604687329

    ${resp}=  Read Attribute  ${TIME_MANAGER_URI}/host  Elapsed
    [Return]  ${resp}


Set Time Using REST
    [Arguments]  ${operation}  ${owner}  ${mode}  ${status}  ${bmc_time}
    ...  ${host_time}
    [Documentation]  Set BMC or Host time on system via REST.
    ...              Description of arguments:
    ...              operation :  Set BMC/Host time
    ...              owner: Time owner
    ...              mode:  Time mode
    ...              status:   Expected status of set BMC time URI
    ...              bmc_time:   Status of BMC time after operation
    ...              host_time:  Status of HOST time after operation
    ...                Set - Given time is set
    ...                Not Set - Given time is not set
    ...                Change - time is change
    ...                No Change - time is not change

    Set Time Owner  ${owner}
    Set Time Mode  ${mode}

    ${setdate}=  Set Variable  ${SYSTEM_TIME_VALID_EPOCH}

    ${start_time}=  Get Current Date

    ${old_bmc_time}=  Get BMC Time Using REST
    ${old_host_time}=  Get HOST Time Using REST

    Wait Until Keyword Succeeds  5 min  15 sec  Set Time Via REST
    ...  ${operation}  ${status}

    ${new_bmc_time}=  Get BMC Time Using REST
    ${new_host_time}=  Get HOST Time Using REST

    ${end_time}=  Get Current Date
    ${time_duration}=  Subtract Date From Date  ${start_time}  ${end_time}
    ${time_duration}  Evaluate  abs(${time_duration})

    # Convert epoch to date format: YYYY-MM-DD hh:mm:ss.mil
    ${setdate}=  Convert epoch to date  ${setdate}
    ${new_bmc_time}=  Convert epoch to date  ${new_bmc_time}
    ${old_bmc_time}=  Convert epoch to date  ${old_bmc_time}
    ${new_host_time}=  Convert epoch to date  ${new_host_time}
    ${old_host_time}=  Convert epoch to date  ${old_host_time}


    ${bmc_diff_set_new}=
    ...  Subtract Date From Date  ${setdate}  ${new_bmc_time}
    ${bmc_diff_set_new}=  Evaluate  abs(${bmc_diff_set_new})
    ${bmc_diff_old_new}=
    ...  Subtract Date From Date  ${old_bmc_time}  ${new_bmc_time}
    ${bmc_diff_old_new}=  Evaluate  abs(${bmc_diff_old_new})

    ${host_diff_set_new}=
    ...  Subtract Date From Date  ${setdate}  ${new_host_time}
    ${host_diff_set_new}=  Evaluate  abs(${host_diff_set_new})
    ${host_diff_old_new}=
    ...  Subtract Date From Date  ${old_host_time}  ${new_host_time}
    ${host_diff_old_new}=  Evaluate  abs(${host_diff_old_new})

    Run Keyword If   '${bmc_time}' == 'Not Set'
    ...    Should Be True  ${bmc_diff_set_new} >= ${time_duration}
    ...  ELSE IF  '${bmc_time}' == 'Set'
    ...    Should Be True  ${bmc_diff_set_new} <= ${time_duration}
    ...  ELSE IF  '${bmc_time}' == 'No Change'
    ...    Should Be True  ${bmc_diff_old_new} <= ${time_duration}
    ...  ELSE IF  '${bmc_time}' == 'Change'
    ...    Should Be True  ${bmc_diff_old_new} >= ${time_duration}

    Run Keyword If  '${host_time}' == 'No Change'
    ...    Should Be True  ${host_diff_old_new} <= ${time_duration}
    ...  ELSE IF  '${host_time}' == 'Change'
    ...    Should Be True  ${host_diff_old_new} >= ${time_duration}
    ...  ELSE IF  '${host_time}' == 'Not Set'
    ...    Should Be True  ${host_diff_set_new} >= ${time_duration}
    ...  ELSE IF  '${host_time}' == 'Set'
    ...    Should Be True  ${host_diff_set_new} <= ${time_duration}

Convert epoch to date
    [Documentation]  Convert epoch time to date format.
    [Arguments]  ${epoch_time}
    # Description of argument(s):
    # epoch_time  epoch time in milliseconds.
    #             (e.g. 1487304700000000)

    # Convert epoch_time into floating point number.
    ${epoch_time}=  Convert To Number  ${epoch_time}

    # Convert epoch time from microseconds to seconds
    ${epoch_time_sec}=  Evaluate  ${epoch_time}/1000000

    # Convert epoch time to date format: YYYY-MM-DD hh:mm:ss.mil
    # e.g. 2017-02-16 22:14:11.000
    ${date}=  Convert Date  ${epoch_time_sec}

    [Return]  ${date}


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Sets defaults for time mode and owner.
    ...  3. Close all open SSH connections.

    FFDC On Test Case Fail
    Set Time Owner  ${BMC_OWNER}
    Set Time Mode  ${NTP_MODE}
    Close All Connections
