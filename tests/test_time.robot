*** Settings ***
Documentation          This suite is for testing System time in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/resource.txt

Library                OperatingSystem
Library                DateTime

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          Post Test Execution

*** Variables ***
${SYSTEM_TIME_INVALID}     01/01/1969 00:00:00
${SYSTEM_TIME_VALID}       02/29/2016 09:10:00
${ALLOWED_TIME_DIFF}       2

${SETTING_HOST}     ${SETTINGS_URI}host0

*** Test Cases ***

Get System Time
    [Documentation]   ***GOOD PATH***
    ...               This test case tries to get system time using IPMI and
    ...               then tries to cross check with BMC date time.
    ...               Expectation is that BMC time and ipmi sel time should match.
    [Tags]  Get_System_Time

    ${resp}=    Run IPMI Standard Command    sel time get
    ${ipmidate}=    Convert Date    ${resp}    date_format=%m/%d/%Y %H:%M:%S    exclude_millis=yes
    ${bmcdate}=    Get BMC Time And Date
    ${diff}=    Subtract Date From Date    ${bmcdate}    ${ipmidate}
    Should Be True      ${diff} < ${ALLOWED_TIME_DIFF}    Open BMC time does not match with IPMI sel time

Set Valid System Time
    [Documentation]   ***GOOD PATH***
    ...               This test case tries to set system time using IPMI and
    ...               then tries to cross check if it is correctly set in BMC.
    ...               Expectation is that BMC time should match with new time.
    [Tags]  Set_Valid_System_Time

    ${resp}=    Run IPMI Standard Command    sel time set "${SYSTEM_TIME_VALID}"
    ${setdate}=    Convert Date    ${SYSTEM_TIME_VALID}    date_format=%m/%d/%Y %H:%M:%S    exclude_millis=yes
    ${bmcdate}=    Get BMC Time And Date
    ${diff}=    Subtract Date From Date    ${bmcdate}    ${setdate}
    Should Be True      ${diff} < ${ALLOWED_TIME_DIFF}     Open BMC time does not match with set time

Set Invalid System Time
    [Documentation]   ***BAD PATH***
    ...               This test case tries to set system time with invalid time using IPMI.
    ...               Expectation is that it should return error.
    [Tags]  Set_Invalid_System_Time

    ${msg}=    Run Keyword And Expect Error    *    Run IPMI Standard Command    sel time set "${SYSTEM_TIME_INVALID}"
    Should Start With    ${msg}    Specified time could not be parsed

Set System Time with no time
    [Documentation]   ***BAD PATH***
    ...               This test case tries to set system time with no time using IPMI.
    ...               Expectation is that it should return error.
    [Tags]  Set_System_Time_with_no_time

    ${msg}=    Run Keyword And Expect Error    *    Run IPMI Standard Command    sel time set ""
    Should Start With    ${msg}    Specified time could not be parsed

Set NTP Time Mode
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time mode as NTP using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_NTP_Time_Mode

    Set Time Mode   NTP

    ${boot}=   Read Attribute  ${SETTING_HOST}   time_mode
    Should Be Equal    ${boot}    NTP

Set Manual Time Mode
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time mode as manual using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_Manual_Time_Mode

    Set Time Mode   Manual

    ${boot}=   Read Attribute  ${SETTING_HOST}   time_mode
    Should Be Equal    ${boot}    Manual

Set Time Owner as BMC
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time owner as BMC using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_Time_Owner_as_BMC

    Set Time Owner   BMC

    ${boot}=   Read Attribute  ${SETTING_HOST}   time_owner
    Should Be Equal    ${boot}    BMC

Set Time Owner as Host
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time owner as Host using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_Time_Owner_as_Host

    Set Time Owner   Host

    ${boot}=   Read Attribute  ${SETTING_HOST}    time_owner
    Should Be Equal    ${boot}    Host

Set BMC Time On Invalid Config
    #Time Owner   Time Mode   Expected Status   Expected BMC Time   Expected HOST Time
    BMC           NTP         error             Not Set             No Change
    HOST          Manual      error             Not Set             No Change
    SPLIT         NTP         error             Not Set             No Change

    [Documentation]  ***BAD PATH***
    ...              Test to validate all bad paths of set BMC time
    ...              functionality via REST
    ...              Time Owner:
    ...                     Time owner before setting BMC time
    ...              Time Mode:
    ...                     Time mode before setting BMC time
    ...              Expected Time Status:
    ...                     Status of set BMC time URI
    ...              Expected BMC Time:
    ...                     Status of BMC time after set operation
    ...                     Set - Given time is set
    ...                     Not Set - Given time is not set
    ...              Expected HOST Time:
    ...                     Status of HOST time after set operation
    ...                     Change - HOST time is change
    ...                     No Change - HOST time is not change
    [Tags]   Set_BMC_Time_On_Invalid_Config
    [Template]    Set BMC Time

Set BMC Time With BMC Owner And Manual Mode
    BMC           Manual      ok                Set                 Change
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set given BMC time when time owner is BMC
    ...              and time mode is manual.
    ...              Expectation is that given BMC time is set and Host time is
    ...              also change to BMC time.
    [Tags]   Set_BMC_Time_With_BMC_Owner_And_Manual_Mode
    [Template]    Set BMC Time

Set BMC Time With Both Owner And Manual Mode
    BOTH          Manual      ok                Set                 Change
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set BMC time when time owner is both
    ...              and time mode is manual.
    ...              Expectation is that given BMC time is set and Host time is
    ...              also change to BMC time.
    [Tags]   Set_BMC_Time_With_Both_Owner_And_Manual_Mode
    [Template]    Set BMC Time

Set BMC Time With Split Owner And Manual Mode
    SPLIT         Manual      ok                Set                 No Change
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set BMC time when time owner is split
    ...              and time mode is manual.
    ...              Expectation is that given BMC time is set and Host time is
    ...              not change.
    [Tags]   Set_BMC_Time_With_Split_Owner_And_Manual_Mode
    [Template]    Set BMC Time

Set HOST Time On Invalid Config
    #Time Owner   Time Mode   Expected Status   Expected BMC Time   Expected HOST Time
    BMC           Manual      error             No Change           Not Set
    BMC           NTP         error             No Change           Not Set

    [Documentation]  ***BAD PATH***
    ...              Test to validate all bad paths of set HOST time
    ...              functionality via REST
    ...              Time Owner:
    ...                     Time owner before setting HOST time
    ...              Time Mode:
    ...                     Time mode before setting HOST time
    ...              Expected Status:
    ...                     Status of set HOST time URI
    ...              Expected HOST Time:
    ...                     Status of HOST time after set operation
    ...                     Set - Given time is set
    ...                     Not Set - Given time is not set
    ...              Expected BMC Time:
    ...                     Status of BMC time after set operation
    ...                     Change - BMC time is change
    ...                     No Change - BMC time is not change
    [Tags]   Set_HOST_Time_On_Invalid_Config
    [Template]    Set HOST Time

Set Host Time With Host Owner And Manual Mode
    HOST          Manual      ok                Change              Set
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set HOST time when time owner is HOST
    ...              and time mode is MANUAL.
    ...              Expectation is that given HOST time is set and BMC time is
    ...              also change to HOST time.
    [Tags]   Set_Host_Time_With_Host_Owner_And_Manual_Mode
    [Template]    Set HOST Time

Set Host Time With Both Owner And Manual Mode
    BOTH          Manual      ok                Change              Set
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set HOST time when time owner is BOTH
    ...              and time mode is MANUAL.
    ...              Expectation is that given HOST time is set and BMC time is
    ...              also change to HOST time.
    [Tags]   Set_Host_Time_With_Both_Owner_And_Manual_Mode
    [Template]    Set HOST Time

Set Host Time With Split Owner And Manual Mode
    SPLIT         Manual      ok                No Change           Set
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set HOST time when time owner is SPLIT
    ...              and time mode is MANUAL.
    ...              Expectation is that given HOST time is set and BMC time is
    ...              not change.
    [Tags]   Set_Host_Time_With_Split_Owner_And_Manual_Mode
    [Template]    Set HOST Time

Set Host Time With Split Owner And NTP Mode
    SPLIT         NTP         ok                No Change           Set
    [Documentation]  ***GOOD PATH***
    ...              This test tries to set HOST time when time owner is SPLIT
    ...              and time mode is NTP.
    ...              Expectation is that given HOST time is set and BMC time is
    ...              not change.
    [Tags]   Set_Host_Time_With_Split_Owner_And_NTP_Mode
    [Template]    Set HOST Time

Set Invalid Time Mode
    [Documentation]   ***BAD PATH***
    ...               This testcase is to verify that invalid value for time
    ...               mode can not be set and proper error is thrown by
    ...               REST API for the same.
    [Tags]  Set_Invalid_Time_Mode

    ${resp}=   Set Time Mode   abc
    Should Be Equal    ${resp}    error

    ${boot}=   Read Attribute   ${SETTING_HOST}   time_mode
    Should Not Be Equal    ${boot}    abc

Set Invalid Time Owner
    [Documentation]   ***BAD PATH***
    ...               This testcase is to verify that invalid value for time
    ...               owner can not be set and proper error is thrown by
    ...               REST API for the same.
    [Tags]  Set_Invalid_Time_Owner

    ${resp}=   Set Time Owner   xyz
    Should Be Equal    ${resp}    error

    ${boot}=   Read Attribute  ${SETTING_HOST}   time_owner
    Should Not Be Equal    ${boot}    xyz


*** Keywords ***

Get BMC Time And Date
    ${stdout}    ${stderr}    ${output}=
    ...          Execute Command    date "+%m/%d/%Y %H:%M:%S"
    ...          return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}

    ${resp}=     Convert Date    ${stdout}     date_format=%m/%d/%Y %H:%M:%S
    ...          exclude_millis=yes
    Should Not Be Empty    ${resp}
    [return]    ${resp}

Set Time Owner
    [Arguments]    ${args}
    ${timeowner}=   Set Variable   ${args}
    ${valueDict}=   create dictionary   data=${timeowner}

    ${resp}=   OpenBMC Put Request
    ...    ${SETTING_HOST}/attr/time_owner    data=${valueDict}
    ${jsondata}=    to json    ${resp.content}
    [return]    ${jsondata['status']}

Set Time Mode
    [Arguments]    ${args}
    ${timemode}=   Set Variable   ${args}
    ${valueDict}=   create dictionary   data=${timemode}

    ${resp}=   OpenBMC Put Request
    ...   ${SETTING_HOST}/attr/time_mode    data=${valueDict}
    ${jsondata}=    to json    ${resp.content}
    Sleep  5s
    [return]    ${jsondata['status']}

Get BMC Time
    [Documentation]  Returns BMC time of the system
    ...              Time Format : YYYY-MM-DD hh:mm:ss.mil
    ...              eg. 2016-12-14 07:09:58.000

    @{credentials}=   Create List   BMC
    ${data}=   create dictionary   data=@{credentials}
    ${resp}=   openbmc post request
    ...        /org/openbmc/TimeManager/action/GetTime   data=${data}
    ${jsondata}=   To Json    ${resp.content}
    ${time_epoch}=   Get From List   ${jsondata["data"]}   0
    ${resp}=   Convert Date
    ...        ${time_epoch}   date_format=%a %b %d %H:%M:%S %Y %Z
    [return]   ${resp}

Get HOST Time
    [Documentation]  Returns HOST time of the system
    ...              Time Format : YYYY-MM-DD hh:mm:ss.mil
    ...              eg. 2016-12-14 07:09:58.000

    @{credentials}=   Create List   HOST
    ${data}=   create dictionary   data=@{credentials}
    ${resp}=   openbmc post request
    ...        /org/openbmc/TimeManager/action/GetTime   data=${data}
    ${jsondata}=   To Json    ${resp.content}
    ${time_epoch}=   Get From List   ${jsondata["data"]}   0
    ${resp}=   Convert Date
    ...   ${time_epoch}   date_format=%a %b %d %H:%M:%S %Y %Z
    [return]   ${resp}

Set BMC Time
    [arguments]   ${owner}   ${mode}   ${expected_status}   ${bmc_time}   ${host_time}
    [Documentation]  Set BMC time on system with given configuration. It first
    ...              sets given owner and mode on the system and then tries
    ...              to set BMC time via REST. Later it verifies status
    ...              of REST URI, BMC and HOST time.
    ...              Description of arguments:
    ...              owner  Time owner before setting BMC time
    ...              mode   Time mode before setting BMC time
    ...              expected_status   Expected status of set BMC time URI
    ...              bmc_time:
    ...                     Status of BMC time after set operation
    ...                     Set - Given time is set
    ...                     Not Set - Given time is not set
    ...              host_time:
    ...                     Status of HOST time after set operation
    ...                     Change - HOST time is change
    ...                     No Change - HOST time is not change

    Set Time Owner   ${owner}
    Set Time Mode   ${mode}

    ${setdate}=    Convert Date    ${SYSTEM_TIME_VALID}
    ...            date_format=%m/%d/%Y %H:%M:%S    exclude_millis=yes

    ${old_bmc_time}=   Get BMC Time
    ${old_host_time}=   Get HOST Time

    @{credentials}=   Create List   BMC   ${setdate}
    ${data}=   create dictionary   data=@{credentials}
    ${resp}=   openbmc post request
    ...        /org/openbmc/TimeManager/action/SetTime   data=${data}
    ${jsondata}=   To Json    ${resp.content}
    should be equal as strings   ${jsondata['status']}   ${expected_status}

    ${new_bmc_time}=   Get BMC Time
    ${new_host_time}=   Get HOST Time

    ${bmc_diff}=   Subtract Date From Date    ${setdate}    ${new_bmc_time}
    ${bmc_diff}=   Evaluate    abs(${bmc_diff})
    Run Keyword If   '${bmc_time}' == 'Not Set'
    ...   Should Be True   ${bmc_diff} >= ${ALLOWED_TIME_DIFF}
    ...   ELSE IF    '${bmc_time}' == 'Set'
    ...      Should Be True   ${bmc_diff} <= ${ALLOWED_TIME_DIFF}

    ${host_diff}=   Subtract Date From Date   ${old_host_time}   ${new_host_time}
    ${host_diff}=   Evaluate    abs(${host_diff})
    Run Keyword If   '${host_time}' == 'No Change'
    ...   Should Be True   ${host_diff} <= ${ALLOWED_TIME_DIFF}
    ...   ELSE IF    '${host_time}' == 'Change'
    ...      Should Be True   ${host_diff} >= ${ALLOWED_TIME_DIFF}

Set HOST Time
    [arguments]    ${owner}   ${mode}   ${expected_status}   ${bmc_time}   ${host_time}
    [Documentation]  Set HOST time on system with given configuration. It first
    ...              sets given owner and mode on the system and then tries
    ...              to set HOST time via REST. Later it verifies status
    ...              of REST URI, BMC and HOST time.
    ...              Description of arguments:
    ...              owner:  Time owner before setting HOST time
    ...              mode:   Time mode before setting HOST time
    ...              expected_status:   Expected status of set HOST time URI
    ...              bmc_time:
    ...                     Status of BMC time after set operation
    ...                     Change - BMC time is change
    ...                     No Change - BMC time is not change
    ...              host_time:
    ...                     Status of HOST time after set operation
    ...                     Set - Given time is set
    ...                     Not Set - Given time is not set

    Set Time Owner   ${owner}
    Set Time Mode   ${mode}

    ${setdate}=   Convert Date    ${SYSTEM_TIME_VALID}
    ...           date_format=%m/%d/%Y %H:%M:%S    exclude_millis=yes
    ${setdate_new}=   Convert Date    ${setdate}    epoch
    ${setdate_new}=   Set Variable   1456737000

    ${old_bmc_time}=   Get BMC Time
    ${old_host_time}=   Get HOST Time

    @{credentials}=   Create List   HOST   ${setdate_new}
    ${data}=   create dictionary   data=@{credentials}
    ${resp}=   openbmc post request
    ...        /org/openbmc/TimeManager/action/SetTime   data=${data}
    ${jsondata}=   To Json    ${resp.content}
    should be equal as strings   ${jsondata['status']}   ${expected_status}

    ${new_bmc_time}=   Get BMC Time
    ${new_host_time}=   Get HOST Time

    ${host_diff}=   Subtract Date From Date   ${setdate}   ${new_host_time}
    ${host_diff}=   Evaluate   abs(${host_diff})
    Run Keyword If   '${host_time}' == 'Not Set'
    ...   Should Be True   ${host_diff} >= ${ALLOWED_TIME_DIFF}
    ...   ELSE IF    '${host_time}' == 'Set'
    ...   Should Be True   ${host_diff} <= ${ALLOWED_TIME_DIFF}

    ${bmc_diff}=   Subtract Date From Date
    ...            ${old_bmc_time}    ${new_bmc_time}
    ${bmc_diff}=   Evaluate    abs(${bmc_diff})
    Run Keyword If   '${bmc_time}' == 'No Change'
    ...   Should Be True   ${bmc_diff} <= ${ALLOWED_TIME_DIFF}
    ...   ELSE IF    '${bmc_time}' == 'Change'
    ...      Should Be True   ${bmc_diff} >= ${ALLOWED_TIME_DIFF}

Post Test Execution
    [Documentation]  Perform operations after test execution. It first try to
    ...              capture FFDC in case of test case failure. Later it sets
    ...              default values for time mode and owner.

    Run Keyword If Test Failed    FFDC On Test Case Fail

    Set Time Mode   NTP

    Set Time Owner   BMC
