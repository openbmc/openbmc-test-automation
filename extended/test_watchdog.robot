*** Settings ***
Documentation          This suite tests HOST watchdog timer in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/utils.robot
Resource               ../lib/resource.txt
Resource               ../lib/boot_utils.robot
Resource               ../lib/state_manager.robot

Suite Setup            Watchdog Timer Test Setup
Suite Teardown         Restore Watchdog Default Setting
Test Teardown          FFDC On Test Case Fail

*** Variables ***
# "skip" boots that aren't needed to get to desired state.
${stack_mode}  skip

*** Test Cases ***
Verify Watchdog Setting With Watchdog Disabled
    [Documentation]  Disable watchdog timer and verify watchdog settings
    ...              i.e Enabled, Interval, TimeRemaining.
    [Tags]  Verify_Watchdog_Setting_With_Watchdog_Disabled

    ${initial_interval}=  Read Attribute  ${HOST_WATCH_DOG_URI}  Interval
    Set Watchdog Setting Using REST  Enabled  ${False}

    # Check if watchdog has default settings.
    ${properties}=  Read Properties  /xyz/openbmc_project/watchdog/host0
    Should Be Equal As Strings  ${properties["Enabled"]}  0
    Should Be Equal As Strings  ${properties["Interval"]}  ${initial_interval}
    Should Be Equal As Strings  ${properties["TimeRemaining"]}  0

Verify Watchdog Setting With Watchdog Enabled
    [Documentation]  Enable watchdog timer and check if host OS is rebooted
    ...              and verify hostdog settings are reset to default when
    ...              host OS is up.
    [Tags]  Verify_Watchdog_Setting_With_Watchdog_Enabled

    ${initial_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval

    Trigger Host Watchdog Error  2000  60

    Wait Until Keyword Succeeds  3 min  10 sec  Watchdog Object Should Exist

    # Verify if watchdog settings are enabled and timeremaining is reduced.
    ${properties}=  Read Properties  /xyz/openbmc_project/watchdog/host0
    Should Be Equal As Strings  ${properties["Enabled"]}  1
    Should Not Be Equal As Strings  ${properties["TimeRemaining"]}  0

    Wait Until Keyword Succeeds  120 sec  20 sec  Is Host Rebooted
    Wait For Host To Ping  ${OS_HOST}  5min  10
    Wait for OS

    # Check if watchdog settings are reset when host OS is up.
    ${properties}=  Read Properties  /xyz/openbmc_project/watchdog/host0
    Should Be Equal As Strings  ${properties["Enabled"]}  0
    Should Be Equal As Strings  ${properties["Interval"]}  ${initial_interval}
    Should Be Equal As Strings  ${properties["TimeRemaining"]}  0

Modify And Verify Watchdog Timer Interval
    [Documentation]  Modify and verify watchdog timer interval.
    [Tags]  Modify_And_Verify_Watchdog_Timer_Interval
    [Teardown]  Set Watchdog Setting Using REST  Interval  ${initial_interval}

    ${initial_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    ${random_int}=  Evaluate  random.randint(10000, 20000)  modules=random
    Set Watchdog Setting Using REST  Interval  ${random_int}
    ${modified_time_interval}=  Read Attribute  ${HOST_WATCHDOG_URI}  Interval
    Should Be Equal As Strings  ${modified_time_interval}  ${random_int}

Modify and verify Watchdog TimeRemaining
    [Documentation]  Modify and verify watchdog 'TimeRemaining'.
    [Tags]  Modify_And_Verify_Watchdog_TimeRemaining

    ${random_int}=  Evaluate  random.randint(10000, 20000)  modules=random
    Set Watchdog Setting Using REST  TimeRemaining  ${random_int}
    ${modified_timeremain}=
    ...  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Not Be Equal As Strings  ${random_int}  ${modified_timeremain}

Verify Watchdog URL When Host Is On And Off
    [Documentation]  Verify watchdog URL when host is running
    ...              and when host is off.
    [Tags]           Verify_Watchdog_URL_When_Host_Is_On_And_Off

    ${resp}=  OpenBMC Get Request  ${HOST_WATCHDOG_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    REST Power Off
    ${resp}=  OpenBMC Get Request  ${HOST_WATCHDOG_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

*** Keywords ***

Watchdog Timer Test Setup
    [Documentation]   Do test initialization setup.
    # Check input parameters & check if host OS is up.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide the host name/host IP address.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On

Restore Watchdog Default Setting
    [Documentation]  Restore watchdog Default setting.

    # Boot to OS.
    REST Power On
    Set Watchdog Setting Using REST  Enabled  ${False}

    Close All Connections

Set Watchdog Setting Using REST
    [Documentation]  Set watchdog setting using REST with a given input
    ...              attribute values.
    [Arguments]  ${setting_name}  ${value}

    # Description of argument(s):
    # setting_name  The name of the watchdog setting
    #               (e.g. "Enabled", "Interval", etc.).
    # value         Watchdog setting value(e.g. "Enabled":boolean,
    #               "Interval":Integer, "TimeRemaining":Integer)

    ${valueDict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}/attr/${setting_name}
    ...       data=${valueDict}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Watchdog Object Should Exist
    [Documentation]  Check if watchdog object exist.

    ${resp}=  OpenBMC Get Request  ${WATCHDOG_URI}host0
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

