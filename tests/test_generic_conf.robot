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

${SETTING_HOST}       ${OPENBMC_BASE_URI}settings/host0

*** Test Cases ***


Get the boot_flags

    [Documentation]   ***GOOD PATH***
    ...               This test case tries to get the boot flags
    ...

    ${resp}=   Read Attribute   ${SETTING_HOST}   boot_flags
    should not be empty   ${resp}

Get the power

    [Documentation]   ***GOOD PATH***
    ...               This test case tries to get the power value and it should be
    ...               between ${MIN_POWER_VALUE} and ${MAX_POWER_VALUE}

    ${powerValue}=   Read Attribute   ${SETTING_HOST}   power_cap
    should be true   ${powerValue} >= ${MIN_POWER_VALUE} and ${powerValue} <= ${MAX_POWER_VALUE}

Set the power with string of characters

    [Documentation]   ***BAD PATH***
    ...               This test case set the power values with string of characters
    ...               Expectation is to return error.
    ...               Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  known_issue

    ${valueToBeSet}=   Set Variable   abcdefg
    ${valueDict}=   create dictionary   data=${valueToBeSet}
    Write Attribute   ${SETTING_HOST}   power_cap   data=${valueDict}
    ${value}=   Read Attribute    ${SETTING_HOST}   power_cap
    should not be true    '${value}'=='${valueToBeSet}'

Set the power with greater then MAX_POWER_VALUE

    [Documentation]   ***BAD PATH***
    ...               This test case sets the power value which is greater
    ...               then MAX_ALLOWED_VALUE,Expectation is to return error
    ...               Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  known_issue

    ${valueToBeSet}=   Set Variable     ${1010}
    ${valueDict}=   create dictionary   data=${valueToBeSet}
    Write Attribute   ${SETTING_HOST}   power_cap   data=${valueDict}
    ${value}=      Read Attribute    ${SETTING_HOST}   power_cap
    should not be equal   ${value}   ${valueToBeSet}

Set the power with MIN_POWER_VALUE

    [Documentation]   ***BAD PATH***
    ...               This test case sets the power value less then
    ...               MIN_ALLOWED_VALUE,Expectation is it should get error.

    ${valueToBeSet}=   Set Variable     ${MIN_POWER_VALUE}
    ${valueDict}=   create dictionary   data=${valueToBeSet}
    Write Attribute   ${SETTING_HOST}   power_cap      data=${valueDict}
    ${value}=      Read Attribute   ${SETTING_HOST}    power_cap
    Should Be Equal     ${value}      ${valueToBeSet}

Set the power with MAX_POWER_VALUE

    [Documentation]   ***GOOD PATH***
    ...               This test case sets the power value with MAX_POWER_VALUE
    ...               and it should be set.

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
    ${valueDict} =   create dictionary   data=${valueToBeSet}
    Write Attribute  ${SETTING_HOST}    boot_flags      data=${valueDict}
    ${value}=      Read Attribute   ${SETTING_HOST}   boot_flags
    Should not Be Equal     ${value}      ${valueToBeSet}

