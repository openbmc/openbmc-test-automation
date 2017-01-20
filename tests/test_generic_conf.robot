*** Settings ***
Documentation  This suite will verifiy the Generic Configuration Rest Interfaces
...            Details of valid interfaces can be found here...
...            https://github.com/openbmc/docs/blob/master/rest-api.md

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Test Teardown     FFDC On Test Case Fail


*** Variables ***
${MIN_POWER_VALUE}    ${0}
${MAX_POWER_VALUE}    ${1000}

${SETTING_HOST}       ${SETTINGS_URI}host0

${VALUE_ERROR}      ValueError: Invalid input. Data not in allowed range

*** Test Cases ***


Get The Boot_Flags

    [Documentation]   ***GOOD PATH***
    ...               This test case tries to get the boot flags
    [Tags]  Get_The_Boot_Flags

    ${resp}=   Read Attribute   ${SETTING_HOST}   boot_flags
    should not be empty   ${resp}

Get the power

    [Documentation]   ***GOOD PATH***
    ...               This test case tries to get the power value and it should be
    ...               between ${MIN_POWER_VALUE} and ${MAX_POWER_VALUE}

    ${powerValue}=   Read Attribute   ${SETTING_HOST}   power_cap
    should be true   ${powerValue} >= ${MIN_POWER_VALUE} and ${powerValue} <= ${MAX_POWER_VALUE}


Set Powercap Value With String
    [Documentation]  Set the power values with string and expect error.
    [Tags]  Set_Powercap_Value_With_String

    ${valueToBeSet}=  Set Variable   abcdefg
    ${error_msg}=  Run Keyword And Expect Error
    ...  *   Write To Powercap Attribute   ${valueToBeSet}
    Should Contain  ${error_msg}  ${VALUE_ERROR}

    ${value}=   Read Attribute    ${SETTING_HOST}   power_cap
    Should Not Be True    '${value}'=='${valueToBeSet}'


Set Powercap Value Greater Than Allowed Range
    [Documentation]  Set the power value greater then MAX_ALLOWED_VALUE
    ...              and expect error.
    [Tags]  Set_Powercap_Value_Greater_Than_Allowed_Range

    ${valueToBeSet}=  Set Variable   ${1010}
    ${error_msg}=  Run Keyword And Expect Error
    ...  *   Write To Powercap Attribute  ${valueToBeSet}
    Should Contain  ${error_msg}  ${VALUE_ERROR}

    ${value}=  Read Attribute    ${SETTING_HOST}   power_cap
    Should Not Be Equal  ${value}  ${valueToBeSet}


Set The Power With MIN_POWER_VALUE

    [Documentation]   ***BAD PATH***
    ...               This test case sets the power value less then
    ...               MIN_ALLOWED_VALUE,Expectation is it should get error.
    [Tags]  Set_The_Power_With_MIN_POWER_VALUE

    ${valueToBeSet}=   Set Variable     ${MIN_POWER_VALUE}
    ${valueDict}=   create dictionary   data=${valueToBeSet}
    Write Attribute   ${SETTING_HOST}   power_cap      data=${valueDict}
    ${value}=      Read Attribute   ${SETTING_HOST}    power_cap
    Should Be Equal     ${value}      ${valueToBeSet}

Set The Power With MAX_POWER_VALUE

    [Documentation]   ***GOOD PATH***
    ...               This test case sets the power value with MAX_POWER_VALUE
    ...               and it should be set.
    [Tags  Set_The_Power_With_MAX_POWER_VALUE

    ${valueToBeSet}=   Set Variable     ${MAX_POWER_VALUE}
    ${valueDict}=   create dictionary   data=${valueToBeSet}
    Write Attribute   ${SETTING_HOST}    power_cap   data=${valueDict}
    ${value}=      Read Attribute   ${SETTING_HOST}    power_cap
    Should Be Equal     ${value}      ${valueToBeSet}

Set the boot flags with string

    [Documentation]   ***BAD PATH***
    ...               This test case sets the boot flag with some invalid string
    ...               Expectation is it should not be set.
    ...               Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  known_issue

    ${valueToBeSet}=   Set Variable     3ab56f
    ${valueDict}=   create dictionary   data=${valueToBeSet}
    Write Attribute  ${SETTING_HOST}    boot_flags      data=${valueDict}
    ${value}=      Read Attribute   ${SETTING_HOST}   boot_flags
    Should not Be Equal     ${value}      ${valueToBeSet}


*** Keywords ***

Write To Powercap Attribute
    [Documentation]  Write to Powercap value.
    [Arguments]   ${args}
    ${value}=  Create Dictionary   data=${args}
    ${resp}=  OpenBMC Put Request
    ...  ${SETTING_HOST}/attr/power_cap    data=${value}
    ${jsondata}=  To JSON   ${resp.content}
    Should Be Equal   ${jsondata['status']}   ${HTTP_OK}
    ...  msg=${jsondata}

