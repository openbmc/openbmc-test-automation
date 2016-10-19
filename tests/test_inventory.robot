*** Settings ***
Documentation     This testsuite is for testing inventory
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot/boot_resource_master.robot
Library           ../lib/utilities.py
Library           String
Library           Collections
Test Teardown     Log FFDC

Variables         ../data/variables.py


Suite setup        setup the suite

Force Tags  chassisboot

*** Test Cases ***

minimal cpu inventory
    ${count} =     Get Total Present     cpu
    Should Be True     ${count}>${0}

minimal dimm inventory
    ${count} =     Get Total Present     dimm
    Should Be True     ${count}>=${2}

minimal core inventory
    ${count} =     Get Total Present     core
    Should Be True     ${count}>${0}

minimal memory buffer inventory
    [Tags]    minimal_memory_buffer_inventory

    ${count} =     Get Total Present     membuf
    Should Be True     ${count}>${0}

minimal fan inventory
    [Tags]  minimal_fan_inventory
    ${count} =     Get Total Present     fan
    Should Be True     ${count}>${2}

minimal main planar inventory
    [Tags]    minimal_main_planar_inventory

    ${count} =     Get Total Present     motherboard
    Should Be True     ${count}>${0}

minimal system inventory
    [Tags]    minimal_system_inventory

    ${count} =     Get Total Present     system
    Should Be True     ${count}>${0}

Verify CPU VPD Properties
    Verify Properties     CPU

Verify DIMM VPD Properties
    Verify Properties     DIMM

Verify Memory Buffer VPD Properties
    Verify Properties     MEMORY_BUFFER

Verify Fan VPD Properties
    Verify Properties     FAN

Verify System VPD Properties
    [Tags]  Verify_System_VPD_Properties
    Verify Properties     SYSTEM

Verify Zombie Process
    Open Connection And Log In
    Check Zombie Process

*** Keywords ***


Setup The Suite
    BMC Power On

    ${resp} =     Read Properties     /org/openbmc/inventory/enumerate
    Set Suite Variable     ${SYSTEM_INFO}      ${resp}
    log Dictionary      ${resp}

Get Total Present
    [arguments]     ${type}
    ${l} =          Create List     []
    ${resp} =    Get Dictionary Keys    ${SYSTEM_INFO}
    ${list} =    Get Matches    ${resp}    regexp=^.*[0-9a-z_].${type}[0-9]*$
    : FOR   ${element}      IN      @{list}
    \       Append To List   ${l}   ${SYSTEM_INFO['${element}']['present']}

    ${sum} =        Get Count       ${l}    True
    [return]        ${sum}

Verify Properties
    [arguments]     ${type}

    ${list} =     Get VPD Inventory List     ${OPENBMC_MODEL}     ${type}
    : FOR     ${element}     IN      @{list}
    \     ${d} =     Get From Dictionary     ${SYSTEM_INFO}     ${element}
    \     Run Keyword If     ${d['present']} == True        Verify Present Properties     ${d}     ${type}

Verify Present Properties
    [arguments]     ${d}     ${type}
    ${keys} =     Get Dictionary Keys     ${d}
    Log List     ${keys}
    Log List     ${INVENTORY_ITEMS['${type}']}
    Lists Should Be Equal  ${INVENTORY_ITEMS['${type}']}     ${keys}
