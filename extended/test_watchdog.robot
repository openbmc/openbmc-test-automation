*** Settings ***
Documentation          This suite tests HOST watchdog timer in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/utils.robot
Resource               ../lib/resource.txt
Resource               ../lib/boot_utils.robot

Suite Setup            Watchdog Timer Test Setup
Suite Teardown         Close All Connections
Test Teardown          FFDC On Test Case Fail

*** Variables ***
${HOST_WATCHDOG_ATTR_URI}  ${HOST_WATCHDOG_URI}/attr/
${TIME_INTERVAL}   15000   #milliseconds
${TIME_REMAINING}  10000   #milliseconds

*** Test Cases ***
Verify Watchdog Timer When Host Is On
    [Documentation]  Verify if watchdog timer is up when host is running.
    [Tags]  Verify_Watchdog_Timer_When_Host_Is_On

    ${resp}=  OpenBMC Get Request  ${HOST_WATCHDOG_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Disable Watchdog Timer And Verify Attributes 
    [Documentation]  Disable Watchdog Timer and verify Enabled, Interval,
    ...              Interval, TimeRemaining attributes.
    [Tags]  Disable_Watchdog_Timer_And_Verify_Attributes

    ${intial_interval}=  Read Attribute  ${HOST_WATCH_DOG_URI}  Interval
    Set Watchdog Timer Attribute  ${False}  Enabled

    ${timer}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal As Strings  ${timer}  0
    ${interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${intial_interval}  ${interval}
    ${timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be Equal As Strings  ${timeremain}  0

Enable Watchdog Timer And Verify Attributes
    [Documentation]  Enable Watchdog Timer and check if HOST OS is booted
    ...              and verify Enabled, Interval, TimeRemaining attributes.
    [Tags]  Enable_Watchdog_Timer_And_Verify_Attributes

    ${intial_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval

    Trigger Host Watchdog Error
    Wait Until Keyword Succeeds  120 sec  20 sec  Is Host Rebooted
    Wait For Host To Ping  ${OS_HOST}  5min  10
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    ${timer}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal As Strings  ${timer}  0
    ${interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${intial_interval}  ${interval}
    ${timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Not Be Equal As Strings  ${TIME_REMAINING}  ${timeremain}

Modify And Verify Watchdog Timer Interval
    [Documentation]  Modify And Verify Watchdog Timer Interval.
    [Tags]  Modify_And_Verify_Watchdog_Timer_Interval
    [Teardown]  Set Watchdog Timer Attribute  ${initial_interval}  Interval

    ${result}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Set Test Variable  ${initial_interval}  ${result}
    Set Watchdog Timer Attribute  ${TIME_INTERVAL}  Interval
    ${modified_time_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${modified_time_interval}  ${TIME_INTERVAL}

Modify And Verify Watchdog TimeRemaining
    [Documentation]  Modify And Verify Watchdog TimeRemaining.
    [Tags]  Modify_And_Verify_Watchdog_TimeRemaining

    Set Watchdog Timer Attribute  ${TIME_REMAINING}  TimeRemaining
    ${modified_timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Not Be Equal As Strings  ${TIME_REMAINING}  ${modified_timeremain}

Verify Watchdog Timer When Host Is Off
    [Documentation]  Verify if watchdog timer is not running
    ...              when host is off.
    [Tags]           Verify_Watchdog_Timer_When_Host_Is_Off

    Initiate Host PowerOff
    ${resp}=  OpenBMC Get Request  ${HOST_WATCHDOG_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

*** keywords ***

Watchdog Timer Test Setup
    [Documentation]  Test initialization setup
    # Validates input parameters & check if HOST OS is up.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Open Connection And Log In

Set Watchdog Timer Attribute
    [Documentation]  Set Watchdog Timer Attribute with given input attribute
    ...              values.
    [Arguments]  ${value}  ${attr}
    # Description of argument(s):
    # value     boolean/number
    # attr      Enabled/Interval

    ${valueDict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_ATTR_URI}${attr}
    ...       data=${valueDict}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
