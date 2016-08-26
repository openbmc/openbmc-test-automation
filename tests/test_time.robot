*** Settings ***
Documentation          This suite is for testing System time in Open BMC.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot

Library                OperatingSystem
Library                DateTime

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          Log FFDC

*** Variables ***
${SYSTEM_TIME_INVALID}     01/01/1969 00:00:00
${SYSTEM_TIME_VALID}       02/29/2016 09:10:00
${ALLOWED_TIME_DIFF}       2

*** Test Cases ***

Get System Time
    [Documentation]   ***GOOD PATH***
    ...               This test case tries to get system time using IPMI and
    ...               then tries to cross check with BMC date time.
    ...               Expectation is that BMC time and ipmi sel time should match.

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

    ${resp}=    Run IPMI Standard Command    sel time set "${SYSTEM_TIME_VALID}"
    ${setdate}=    Convert Date    ${SYSTEM_TIME_VALID}    date_format=%m/%d/%Y %H:%M:%S    exclude_millis=yes
    ${bmcdate}=    Get BMC Time And Date
    ${diff}=    Subtract Date From Date    ${bmcdate}    ${setdate}
    Should Be True      ${diff} < ${ALLOWED_TIME_DIFF}     Open BMC time does not match with set time

Set Invalid System Time
    [Documentation]   ***BAD PATH***
    ...               This test case tries to set system time with invalid time using IPMI.
    ...               Expectation is that it should return error.

    ${msg}=    Run Keyword And Expect Error    *    Run IPMI Standard Command    sel time set "${SYSTEM_TIME_INVALID}"
    Should Start With    ${msg}    Specified time could not be parsed

Set System Time with no time
    [Documentation]   ***BAD PATH*** 
    ...               This test case tries to set system time with no time using IPMI.
    ...               Expectation is that it should return error.

    ${msg}=    Run Keyword And Expect Error    *    Run IPMI Standard Command    sel time set ""
    Should Start With    ${msg}    Specified time could not be parsed

*** Keywords ***

Get BMC Time And Date
    ${stdout}    ${stderr}    ${output}=  Execute Command    date "+%m/%d/%Y %H:%M:%S"    return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    ${resp}=    Convert Date    ${stdout}     date_format=%m/%d/%Y %H:%M:%S      exclude_millis=yes
    Should Not Be Empty    ${resp}
    [return]    ${resp}
