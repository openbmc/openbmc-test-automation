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

*** Test Cases ***
Verify Watchdog Setting With Watchdog Disabled
    [Documentation]  Disable Watchdog Timer and verify Enabled, Interval,
    ...              Interval, TimeRemaining settings.
    [Tags]  Verify_Watchdog_Setting_With_Watchdog_Disabled

    ${intial_interval}=  Read Attribute  ${HOST_WATCH_DOG_URI}  Interval
    Set Watchdog Setting Using REST  ${False}  Enabled

    # check if watchdog settings are reset
    ${watchdog_status}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal As Strings  ${watchdog_status}  0
    ${interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${intial_interval}  ${interval}
    ${timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be Equal As Strings  ${timeremain}  0

Verify Watchdog Setting With Watchdog Enabled
    [Documentation]  Enable Watchdog Timer and check if HOST OS is rebooted
    ...              and verify Enabled, Interval, TimeRemaining settings
    ...              are reset when HOST OS is up.
    [Tags]  Verify_Watchdog_Setting_With_Watchdog_Enabled

    ${intial_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval

    Trigger Host Watchdog Error
    Wait Until Keyword Succeeds  120 sec  20 sec  Is Host Rebooted
    Wait For Host To Ping  ${OS_HOST}  5min  10
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    # check if watchdog settings are reset when HOST OS is up

    ${watchdog_status}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal As Strings  ${watchdog_status}  0
    ${interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${intial_interval}  ${interval}
    ${timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be Equal As Strings  ${timeremain}  0

Modify And Verify Watchdog Timer Interval
    [Documentation]  Modify And Verify Watchdog Timer Interval.
    [Tags]  Modify_And_Verify_Watchdog_Timer_Interval
    [Teardown]  Set Watchdog Setting Using REST  ${initial_interval}  Interval

    ${result}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Set Test Variable  ${initial_interval}  ${result}
    ${random_int}=  Evaluate  random.randint(10000, 20000)  modules=random
    Set Watchdog Setting Using REST  ${random_int}  Interval
    ${modified_time_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${modified_time_interval}  ${random_int}

Modify And Verify Watchdog TimeRemaining
    [Documentation]  Modify And Verify Watchdog TimeRemaining.
    [Tags]  Modify_And_Verify_Watchdog_TimeRemaining

    ${random_int}=  Evaluate  random.randint(10000, 20000)  modules=random
    Set Watchdog Setting Using REST  ${random_int}  TimeRemaining
    ${modified_timeremain}=  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Not Be Equal As Strings  ${random_int}  ${modified_timeremain}

Verify Watchdog URL When Host Is On And Off
    [Documentation]  Verify if watchdog URL when Host is running
    ...              and when host is off.
    [Tags]           Verify_Watchdog_URL_When_Host_Is_On_And_Off

    Open Connection And Log In
    ${resp}=  OpenBMC Get Request  ${HOST_WATCHDOG_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

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

Set Watchdog Setting Using REST
    [Documentation]  Set Watchdog Setting Using REST with a given input
    ...              attribute values.
    [Arguments]  ${value}  ${setting_name}
    # Description of argument(s):
    # value         boolean/number
    # setting_name  Enabled/Interval

    ${valueDict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}/attr/${setting_name}
    ...       data=${valueDict}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
