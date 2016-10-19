*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource        ../lib/rest_client.robot
Resource        ../lib/ipmi_client.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/utils.robot
Library         ../data/model.py

Suite setup            Setup The Suite
Suite Teardown         Close All Connections
Test Teardown          Log FFDC


*** Variables ***
${model} =    ${OPENBMC_MODEL}

*** Test Cases ***
Verify connection
    Execute new Command    echo "hello"
    Response Should Be Equal    "hello"

Execute ipmi BT capabilities command
    [Tags]  Execute_ipmi_BT_capabilities_command
    Run IPMI command            0x06 0x36
    response Should Be Equal    " 01 40 40 0a 01"

Execute Set Sensor boot count
    ${uri} =    Get System component    BootCount
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command   0x04 0x30 ${x} 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00 0x00
    Read the Attribute      ${uri}   value
    ${val} =     convert to integer    53
    Response Should Be Equal   ${val}

Set Sensor Boot progress
    ${uri} =    Get System component    BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x14 0x00
    Read the Attribute  ${uri}    value
    Response Should Be Equal    FW Progress, Baseboard Init

Set Sensor Boot progress Longest string
    ${uri} =    Get System component    BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x0e 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    FW Progress, Docking station attachment

BootProgress sensor FW Hang unspecified Error
    ${uri} =    Get System component    BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    FW Hang, Unspecified

BootProgress fw hang state
    ${uri} =    Get System component    BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    POST Error, unknown

OperatingSystemStatus Sensor boot completed progress
    ${uri} =    Get System component    OperatingSystemStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Boot completed (00)

OperatingSystemStatus Sensor progress
    ${uri} =    Get System component    OperatingSystemStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x04 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    PXE boot completed

OCC Active sensor on enabled
    ${uri} =    Get System component    OccStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Enabled

OCC Active sensor on disabled
    ${uri} =    Get System component    OccStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Disabled

CPU Present

    ${uri} =    Get System component    cpu
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    present
    Response Should Be Equal    True

CPU not Present
    ${uri} =    Get System component    cpu
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    present
    Response Should Be Equal    False

CPU fault
    ${uri} =    Get System component    cpu
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    True

CPU no fault
    ${uri} =    Get System component    cpu
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    False

core Present
    ${uri} =    Get System component    core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}   present
    Response Should Be Equal    True

core not Present
    ${uri} =    Get System component    core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}   present
    Response Should Be Equal    False

core fault
    ${uri} =    Get System component    core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    True

core no fault
    ${uri} =    Get System component    core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    False

DIMM3 Present
    ${uri} =    Get System component    dimm3
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     present
    Response Should Be Equal    True

DIMM3 not Present
    ${uri} =    Get System component    dimm3
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     present
    Response Should Be Equal    False

DIMM0 fault
    ${uri} =    Get System component    dimm0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     fault
    Response Should Be Equal    True

DIMM0 no fault
    ${uri} =    Get System component    dimm0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     fault
    Response Should Be Equal    False

Centaur0 Present
    [Tags]    Centaur0_Present

    ${uri} =    Get System component    membuf
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

Centaur0 not Present
    [Tags]    Centaur0_not_Present

    ${uri} =    Get System component    membuf
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    False

Centaur0 fault
    ${uri} =    Get System component    membuf
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    True

Centaur0 no fault
    ${uri} =    Get System component    membuf
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

System Present
    [Tags]    System_Present

    ${uri} =    Get System component    system
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

System Fault
    ${uri} =    Get System component    system
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

Chassis Present
    [Tags]    Chassis_Present

    ${uri} =    Get System component    chassis
    Read The Attribute   /org/openbmc/inventory/system/chassis    present
    Response Should Be Equal    True

Chassis Fault
    ${uri} =    Get System component    chassis
    Read The Attribute   /org/openbmc/inventory/system/chassis    fault
    Response Should Be Equal    False

io_board Present
    [Tags]  io_board_Present
    ${uri} =    Get System component    io_board
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

io_board Fault
    [Tags]  io_board_Fault
    ${uri} =    Get System component    io_board
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

Verify Zombie Process
    [Tags]  Verify_Zombie_Process
    Check Zombie Process

*** Keywords ***

Setup The Suite

    Open Connection And Log In
    ${resp} =       Read Properties         /org/openbmc/enumerate   timeout=30
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}

Get System component
    [Arguments]    ${type}
    ${list} =    Get Dictionary Keys    ${SYSTEM_INFO}
    ${resp} =    Get Matches    ${list}    regexp=^.*[0-9a-z_].${type}[0-9]*$
    ${url} =    Get From List    ${resp}    0
    [return]    ${url}

Execute new Command
    [arguments]    ${args}
    ${output}=  Execute Command    ${args}
    set test variable    ${OUTPUT}     "${output}"

response Should Be Equal
    [arguments]    ${args}
    Should Be Equal    ${OUTPUT}    ${args}

Response Should Be Empty
    Should Be Empty    ${OUTPUT}

Read the Attribute     
    [arguments]    ${uri}    ${parm}
    ${output} =     Read Attribute      ${uri}    ${parm}
    set test variable    ${OUTPUT}     ${output}

Get Sensor Number
    [arguments]  ${name}
    ${x} =       get sensor   ${OPENBMC_MODEL}   ${name}
    [return]     ${x}

Get Inventory Sensor Number
    [arguments]  ${name}
    ${x} =       get inventory sensor   ${OPENBMC_MODEL}   ${name}
    [return]     ${x}
