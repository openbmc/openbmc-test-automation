*** Settings ***
Documentation          This suite tests HOST watchdog timer in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/utils.robot
Resource               ../lib/resource.txt

Suite Setup            Watchdog Timer Test SetUp
Suite Teardown        Close All Connections

*** Variables ***
${HOST_WATCHDOG_ATTR_URI}  ${HOST_WATCHDOG_URI}/attr/
${NEW_INTERVAL}  15000

*** Test Cases ***

Check Watchdog Timer On Host PowerOn
    [Documentation]  This test checks if watchdog timer is up
    ...              when host is running.
    [Tags]  Check_Watchdog_Timer_On_Host_PowerOn

    ${resp}=  Read Watchdog Timer
    Should Be Equal As Strings  ${resp}  ${HTTP_OK}

Modify And Verify Watchdog Timer Interval
    [Documentation]  Modify And Verify Watchdog Timer Interval.
    [Tags]           Modify_And_Verify_Watchdog_Timer_Interval

    ${initial_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Set Watchdog Timer Attribute  ${NEW_INTERVAL}  Interval
    ${resp}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${resp}  ${NEW_INTERVAL}
    Set Watchdog Timer Attribute  ${initial_interval}  Interval

Enable Watchdog Timer And Verify TimeRemaining
    [Documentation]  Enable Watchdog Timer And Verify TimeRemaining.
    [Tags]           Enable_Watchdog_Timer_And_Verify_TimeRemaining

    ${initial_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    ${watchdog_enable}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled

    Set Watchdog Timer Attribute  True  Enabled

    ${resp}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal As Strings  ${resp}  1
    ${timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Not Be Equal As Strings  ${initial_interval}  ${timeremain}
    Wait Until Keyword Succeeds  2min  10
    ...    Check If Watchdog TimeRemaining Is Reset

Check Watchdog Timer On Host PowerOff
    [Documentation]  This test checks if watchdog timer is not running
    ...              when host is off.
    [Tags]           Check_Watchdog_Timer_On_Host_PowerOff

    Initiate Host PowerOff
    ${resp}=  Read Watchdog Timer
    Should Be Equal As Strings  ${resp}  ${HTTP_NOT_FOUND}

*** keywords ***

Watchdog Timer Test SetUp
    [Documentation]  Validates input parameters & check if HOST OS is pinging.
    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.

    Open Connection And Log In
    Initiate Host Boot
    Wait For Host To Ping  ${OS_HOST}  5min  10

Set Watchdog Timer Attribute 
    [Documentation]  Set Watchdog Timer Attribute with given input attribute
    ...              values. 
    [Arguments]  ${value}  ${attr}
    # Description of arguments:
    #${value}     boolean/number
    #${attr}      Enabled/Interval

    ${valueDict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_ATTR_URI}${attr}
    ...       data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}

Read Watchdog Timer
    [Documentation]  Read Watchdog Timer and return response.

    ${resp}=  OpenBMC Get Request  ${HOST_WATCHDOG_URI}
    [Return]  ${resp.status_code}

Check If Watchdog TimeRemaining Is Reset
    [Documentation]  Check If Watchdog TimeRemaining Is Reset.

    ${timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be Equal As Strings  ${timeremain}  0
