*** Settings ***
Documentation       This suite tests checkstop operations through OS.
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ras/host_utils.robot
Resource            ../lib/resource.txt
Resource            ../lib/state_manager.robot
Test Setup          RAS Test Setup
Test Teardown       FFDC On Test Case Fail

*** Variables ***
${HOST_SETTINGS}    ${SETTINGS_URI}host0

*** Test Cases ***

Verify Channel Checkstop Through OS With Auto Reboot

    [Documentation]  Verify Channel Checkstop (MBS FIR REG INT PROTOCOL ERROR)
    ...              through OS With Auto Reboot settings enabled.
    [Tags]           Channel_Checkstop_Through_OS

    Inject Checkstop Through OS With Auto Reboot
    ...  Centaur  2011400  4000000000000000

*** Keywords ***

Inject Checkstop Through OS With Auto Reboot
    [Documentation]  Inject checkstop on processor/centaur through OS
    ...              Test sequence:
    ...              Enable Auto Reboot Setting
    ...              Boot To OS
    ...              Clear any existing gard records
    ...              Inject Checkstop on processor/centaur
    ...              Check If HOST rebooted and OS is up
    ...              Verify gard records
    ...              clear gard records
    [Arguments]      ${chip_type}  ${fru}  ${address}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).
    # fru            FRU value (e.g. 2011400).
    # address        chip address (e.g 4000000000000000).

    Set Auto Reboot  yes

    Get To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    # Get core values are present through OS.
    Get Cores Values From OS

    Gard Operations On OS  clear all

    # Fetch Processor/Centaur chip value based on the input chip_type.
    ${output}=  Get ChipID From OS  ${chip_type}
    ${chip_values}=  Split String  ${output}
    ${chip_value}=  Get From List  ${chip_values}  0

    Putscom Through OS  ${chip_value}  ${fru}  ${address}

    Wait Until Keyword Succeeds  120 sec  20 sec  Is Host Rebooted
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  'No GARD entries to display'
    Gard Operations On OS  clear all

RAS Test SetUp
    [Documentation]  Validates input parameters.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.
