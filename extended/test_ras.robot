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
    [Tags]           Verify_Channel_Checkstop_Through_OS_With_Auto_Reboot

    Verify Checkstop Insertion With Auto Reboot
    ...  Centaur  2011400  4000000000000000


Verify Host Reboot On Host Booted System With Auto Reboot Enabled
    [Documentation]  Verify host reboot after host watchdog error on host
    ...  booted system with auto reboot enabled.
    [Tags]  Verify_Host_Reboot_On_Host_Booted_System_With_Auto_Reboot_Enabled

    Initiate Host Boot
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    Set Auto Reboot  ${1}

    Trigger Host Watchdog Error

    Wait Until Keyword Succeeds  3 min  5 sec  Is Host Rebooted
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}


Verify Host Quiesced On Host Booted System With Auto Reboot Disabled
    [Documentation]  Verify host quiesced state after host watchdog error on
    ...  host booted system with auto reboot disabled.
    [Tags]  Verify_Host_Quiesced_On_Host_Booted_System_With_Auto_Reboot_Disabled

    Initiate Host Boot
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    Set Auto Reboot  ${0}

    Trigger Host Watchdog Error

    Wait Until Keyword Succeeds  3 min  5 sec  Is Host Quiesced
    Recover Quiesced Host


*** Keywords ***
Inject Checkstop Through OS
    [Documentation]  Inject checkstop on processor/centaur through OS.
    ...              Test sequence:
    ...              1. Boot To OS
    ...              2. Clear any existing gard records
    ...              3. Inject Checkstop on processor/centaur
    [Arguments]      ${chip_type}  ${fru}  ${address}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).
    # fru            FRU value (e.g. 2011400).
    # address        chip address (e.g 4000000000000000).


    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    # Get core values are present through OS.
    Get Cores Values From OS

    Gard Operations On OS  clear all

    # Fetch Processor/Centaur chip value based on the input chip_type.
    ${output}=  Get ChipID From OS  ${chip_type}
    ${chip_values}=  Split String  ${output}
    ${chip_value}=  Get From List  ${chip_values}  0

    Putscom Through OS  ${chip_value}  ${fru}  ${address}

Verify And Clear Gard Records On OS
    [Documentation]  Verify And Clear gard records on OS.

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  'No GARD entries to display'
    Gard Operations On OS  clear all

Verify Checkstop Insertion With Auto Reboot
    [Documentation]  Inject and verify checkstop on processor/centaur through
    ...              OS with auto reboot.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting
    ...              2. Inject Checkstop on processor/centaur
    ...              3. Check If HOST rebooted and OS is up
    ...              4. Verify & clear gard records
    [Arguments]      ${chip_type}  ${fru}  ${address}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).
    # fru            FRU value (e.g. 2011400).
    # address        chip address (e.g 4000000000000000).

    Set Auto Reboot  yes
    Inject Checkstop Through OS  ${chip_type}  ${fru}  ${address}
    Wait Until Keyword Succeeds  120 sec  20 sec  Is Host Rebooted
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Verify And Clear Gard Records On OS

RAS Test SetUp
    [Documentation]  Validates input parameters.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.
