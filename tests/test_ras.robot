*** Settings ***
Resource            ../lib/rest_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ras/host_utils.robot
Resource            ../lib/resource.txt
Resource            ../lib/state_manager.robot

Test Teardown        FFDC On Test Case Fail

*** Variables ***
${HOST_SETTINGS}    ${SETTINGS_URI}host0

*** Test Cases ***

Channel Checkstop Through OS

    [Documentation]  Inject Channel Checkstop (MBS FIR REG INT PROTOCOL ERROR)
    ...              through OS.

    Inject Checkstop Through OS  Centaur  2011400  4000000000000000

*** Keywords ***
Inject Checkstop Through OS

    [Documentation]  Injects checkstop on processor/centaur through OS and check
    ...              if gard records are created after error injection.

    [Arguments]      ${chiptype}  ${fru}  ${address}
    #chiptype        Processor/Centaur
    #fru             FRU value
    #address         chip address

    Set Auto Reboot  yes

    Put BMC State  Ready

    ${host_state}=  Get Host State
    Run Keyword If  '${host_state}' == 'Off'  Initiate Host Boot
    Is Host Running

    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    Get Cores Values From OS
    Gard Operations On OS  clear all
    ${output}=  Get ChipID From OS  ${chiptype}
    ${chip_values}=  Split String  ${output}
    ${chip_value}=  Get From List  ${chip_values}  0

    Putscom Through OS  ${chip_value}  ${fru}  ${address}
    sleep  180s

    Is Host Running
    Wait for OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}

    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  'No GARD entries to display'
    Gard Operations On OS  clear all
    Set Auto Reboot  no 
