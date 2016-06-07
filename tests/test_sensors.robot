*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource        ../lib/rest_client.robot
Resource        ../lib/ipmi_client.robot
Library         ../data/model.py

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections


*** Variables ***
${model} =    ${OPENBMC_MODEL}

*** Test Cases ***
Verify connection
    Execute new Command    echo "hello"
    Response Should Be Equal    "hello"

Execute ipmi BT capabilities command
    Run IPMI command            0x06 0x36
    response Should Be Equal    " 01 40 40 0a 01"

Execute Set Sensor boot count
    ${uri} =    Set Variable    /org/openbmc/sensors/host/BootCount
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command   0x04 0x30 ${x} 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00 0x00
    Read the Attribute      ${uri}   value
    ${val} =     convert to integer    53
    Response Should Be Equal   ${val}

Set Sensor Boot progress
    ${uri} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x14 0x00
    Read the Attribute  ${uri}    value
    Response Should Be Equal    FW Progress, Baseboard Init

Set Sensor Boot progress Longest string
    ${uri} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x0e 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    FW Progress, Docking station attachment

BootProgress sensor FW Hang unspecified Error
    ${uri} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    FW Hang, Unspecified

BootProgress fw hang state
    ${uri} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    POST Error, unknown

OperatingSystemStatus Sensor boot completed progress
    ${uri} =    Set Variable    /org/openbmc/sensors/host/OperatingSystemStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Boot completed (00)

OperatingSystemStatus Sensor progress
    ${uri} =    Set Variable    /org/openbmc/sensors/host/OperatingSystemStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x04 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    PXE boot completed

OCC Active sensor on enabled
    ${uri} =    Set Variable    /org/openbmc/sensors/host/cpu0/OccStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Enabled

OCC Active sensor on disabled
    ${uri} =    Set Variable    /org/openbmc/sensors/host/cpu0/OccStatus
    ${x} =      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Disabled

CPU Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

CPU not Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    False

CPU fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    True

CPU no fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

core Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}   present
    Response Should Be Equal    True

core not Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}   present
    Response Should Be Equal    False

core fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    True

core no fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

DIMM3 Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/dimm3
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     present
    Response Should Be Equal    True

DIMM3 not Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/dimm3
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     present
    Response Should Be Equal    False

DIMM0 fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/dimm0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     fault
    Response Should Be Equal    True

DIMM0 no fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/dimm0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     fault
    Response Should Be Equal    False

Centaur0 Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/membuf0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

Centaur0 not Present
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/membuf0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    False

Centaur0 fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/membuf0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    True

Centaur0 no fault
    ${uri} =    Set Variable    /org/openbmc/inventory/system/chassis/motherboard/membuf0
    ${x} =      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

System Present
    Read The Attribute   /org/openbmc/inventory/system    present
    Response Should Be Equal    True
    
System Fault
    Read The Attribute   /org/openbmc/inventory/system    fault
    Response Should Be Equal    False
    
Chassis Present
    Read The Attribute   /org/openbmc/inventory/system/chassis    present
    Response Should Be Equal    True
    
Chassis Fault
    Read The Attribute   /org/openbmc/inventory/system/chassis    fault
    Response Should Be Equal    False
    
io_board Present
    Read The Attribute   /org/openbmc/inventory/system/chassis/io_board    present
    Response Should Be Equal    True
    
io_board Fault
    Read The Attribute   /org/openbmc/inventory/system/chassis/io_board    fault
    Response Should Be Equal    False
    


*** Keywords ***
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
