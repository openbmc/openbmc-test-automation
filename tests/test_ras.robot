*** Settings ***
Documentation       This suite tests checkstop operations through OS.
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ras/host_utils.robot
Resource            ../lib/resource.txt
Resource            ../lib/state_manager.robot
Test Setup          RAS Test Setup

*** Variables ***
${HOST_SETTINGS}    ${SETTINGS_URI}host0

*** Test Cases ***

Channel Checkstop Through OS

    [Documentation]  Inject Channel Checkstop (MBS FIR REG INT PROTOCOL ERROR)
    ...              through OS.
    [Tags]           Channel_Checkstop_Through_OS

    Inject Checkstop Through OS  Centaur  2011400  4000000000000000

*** Keywords ***

Inject Checkstop Through OS
    [Documentation]  Inject checkstop on processor/centaur through OS & check
    ...              if gard records are created after error injection.
    [Arguments]      ${chip_type}  ${fru}  ${address}
    # Description of arguments:
    # chip_type      The chip type (Processor/Centaur).
    # fru            FRU value (e.g. 2011400).
    # address        chip address (e.g 4000000000000000).

    Set Auto Reboot  yes
    Put BMC State  Ready
    ${host_state}=  Get Host State
    Run Keyword If  '${host_state}' == 'Off'  Initiate Host Boot
    Is Host Running

    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    Get Cores Values From OS
    Gard Operations On OS  clear all
    ${output}=  Get ChipID From OS  ${chip_type}
    ${chip_values}=  Split String  ${output}
    ${chip_value}=  Get From List  ${chip_values}  0

    Putscom Through OS  ${chip_value}  ${fru}  ${address}
    #Adding delay for OS to boot back.
    sleep  120s
    Is Host Rebooted
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  'No GARD entries to display'
    Gard Operations On OS  clear all
    Set Auto Reboot  no

RAS Test SetUp
    [Documentation]  Validates input parameters.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.
