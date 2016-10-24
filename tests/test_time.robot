*** Settings ***
Documentation          This suite is for testing System time in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot

Library                OperatingSystem
Library                DateTime

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          Post Test Execution

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

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    time_mode
    Should Be Equal    ${boot}    NTP

Set Manual Time Mode
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time mode as manual using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_Manual_Time_Mode

    Set Time Mode   Manual

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    time_mode
    Should Be Equal    ${boot}    Manual

Set Time Owner as BMC
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time owner as BMC using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_Time_Owner_as_BMC

    Set Time Owner   BMC

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    time_owner
    Should Be Equal    ${boot}    BMC

Set Time Owner as Host
    [Documentation]   ***GOOD PATH***
    ...               This testcase is to set time owner as Host using REST
    ...               URI and then verify using REST API.\n
    [Tags]  Set_Time_Owner_as_Host

    Set Time Owner   Host

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    time_owner
    Should Be Equal    ${boot}    Host

Set Invalid Time Mode
    [Documentation]   ***BAD PATH***
    ...               This testcase is to verify that invalid value for time
    ...               mode can not be set and proper error is thrown by
    ...               REST API for the same.
    [Tags]  Set_Invalid_Time_Mode

    ${resp} =   Set Time Mode   abc
    Should Be Equal    ${resp}    error

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    time_mode
    Should Not Be Equal    ${boot}    abc

Set Invalid Time Owner
    [Documentation]   ***BAD PATH***
    ...               This testcase is to verify that invalid value for time
    ...               owner can not be set and proper error is thrown by
    ...               REST API for the same.
    [Tags]  Set_Invalid_Time_Owner

    ${resp} =   Set Time Owner   xyz
    Should Be Equal    ${resp}    error

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    time_owner
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
    ${timeowner} =   Set Variable   ${args}
    ${valueDict} =   create dictionary   data=${timeowner}

    ${resp} =   OpenBMC Put Request
    ...         /org/openbmc/settings/host0/attr/time_owner    data=${valueDict}
    ${jsondata} =    to json    ${resp.content}
    [return]    ${jsondata['status']}

Set Time Mode
    [Arguments]    ${args}
    ${timemode} =   Set Variable   ${args}
    ${valueDict} =   create dictionary   data=${timemode}

    ${resp} =   OpenBMC Put Request
    ...         /org/openbmc/settings/host0/attr/time_mode    data=${valueDict}
    ${jsondata} =    to json    ${resp.content}
    [return]    ${jsondata['status']}


Post Test Execution
    [Documentation]  Perform operations after test execution. It first try to
    ...              capture FFDC in case of test case failure. Later it sets
    ...              default values for time mode and owner.

    Run Keyword If Test Failed    FFDC On Test Case Fail

    Set Time Mode   NTP

    Set Time Owner   BMC
