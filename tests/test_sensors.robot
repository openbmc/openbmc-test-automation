*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource        ../lib/rest_client.robot


Library                SSHLibrary
Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections


*** Variables ***


*** Test Cases ***
Verify connection
    Execute new Command    echo "hello"
    Response Should Be Equal    "hello"


Execute ipmi BT capabilities command
    Run IPMI command            0x06 0x36
    response Should Be Equal    " 01 3f 3f 0a 01"


Execute Set Sensor boot count
    Run IPMI command    0x04 0x30 0x09 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00 0x00
    Read the Attribute      /org/openbmc/sensor/virtual/BootCount   value
    Response Should Be Equal    "53"


Set Sensor Boot progress
    Run IPMI command  0x04 0x30 0x05 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x14 0x00
    Read the Attribute  /org/openbmc/sensor/virtual/BootProgress    value
    Response Should Be Equal    "FW Progress, Baseboard Init"



Set Sensor Boot progress Longest string
    Run IPMI command  0x04 0x30 0x05 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x0e 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/BootProgress    value
    Response Should Be Equal    "FW Progress, Docking station attachment"


BootProgress sensor FW Hang unspecified Error
    Run IPMI command  0x04 0x30 0x05 0xa9 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/BootProgress    value
    Response Should Be Equal    "FW Hang, Unspecified"


BootProgress fw hang state
    Run IPMI command  0x04 0x30 0x05 0xa9 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/BootProgress    value
    Response Should Be Equal    "POST Error, unknown"


OperatingSystemStatus Sensor boot completed progress
    Run IPMI command  0x04 0x30 0x32 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/OperatingSystemStatus     value
    Response Should Be Equal    "Boot completed (00)"


OperatingSystemStatus Sensor progress
    Run IPMI command  0x04 0x30 0x32 0x00 0x00 0x04 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/OperatingSystemStatus     value
    Response Should Be Equal    "PXE boot completed"


OCC Active sensor on enabled
    Run IPMI command  0x04 0x30 0x08 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/OccStatus     value
    Response Should Be Equal    "Enabled"


OCC Active sensor on disabled
    Run IPMI command  0x04 0x30 0x08 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  /org/openbmc/sensor/virtual/OccStatus     value
    Response Should Be Equal    "Disabled"


CPU Present
    Run IPMI command  0x04 0x30 0x2f 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0    present
    Response Should Be Equal    "True"

CPU not Present
    Run IPMI command  0x04 0x30 0x2f 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0    present
    Response Should Be Equal    "False"


CPU fault
    Run IPMI command  0x04 0x30 0x2f 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0    fault
    Response Should Be Equal    "True"


CPU no fault
    Run IPMI command  0x04 0x30 0x2f 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0    fault
    Response Should Be Equal    ""


core Present
    Run IPMI command  0x04 0x30 0x2d 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11   present
    Response Should Be Equal    "True"

core not Present
    Run IPMI command  0x04 0x30 0x2d 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11   present
    Response Should Be Equal    "False"


core fault
    Run IPMI command  0x04 0x30 0x2d 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11    fault
    Response Should Be Equal    "True"


core no fault
    Run IPMI command  0x04 0x30 0x2d 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/cpu0/core11    fault
    Response Should Be Equal    ""


DIMM3 Present
    Run IPMI command  0x04 0x30 0x21 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/dimm3     present
    Response Should Be Equal    "True"

DIMM3 not Present
    Run IPMI command  0x04 0x30 0x21 0xa9 0xff 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/dimm3     present
    Response Should Be Equal    "False"


DIMM0 fault
    Run IPMI command  0x04 0x30 0x1e 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/dimm0     fault
    Response Should Be Equal    "True"


DIMM0 no fault
    Run IPMI command  0x04 0x30 0x1e 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/dimm0     fault
    Response Should Be Equal    ""



Centaur0 Present
    Run IPMI command  0x04 0x30 0x2e 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/centaur0    present
    Response Should Be Equal    "True"

Centaur0 not Present
    Run IPMI command  0x04 0x30 0x2e 0x00 0x00 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/centaur0    present
    Response Should Be Equal    "False"


Centaur0 fault
    Run IPMI command  0x04 0x30 0x2e 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/centaur0    fault
    Response Should Be Equal    "True"

Centaur0 no fault
    Run IPMI command  0x04 0x30 0x2e 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   /org/openbmc/inventory/system/chassis/motherboard/centaur0    fault
    Response Should Be Equal    ""



*** Keywords ***
Execute new Command
    [arguments]    ${args}
    ${output}=  Execute Command    ${args}
    set test variable    ${OUTPUT}     "${output}"

response Should Be Equal
    [arguments]    ${args}
    Should Be Equal    ${OUTPUT}    ${args}


Read the Attribute     
    [arguments]    ${uri}    ${parm}
    ${output} =     Read Attribute      ${uri}    ${parm}
    ${json} =       to json             ${output}
    ${data} =       get from dictionary      ${json}     data
    set test variable    ${OUTPUT}     "${data}"
    


Open Connection And Log In
    Open connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}

Run IPMI Command
    [arguments]    ${args}
    ${output}=  Execute Command    /usr/sbin/ipmitool -I dbus raw ${args}
    set test variable    ${OUTPUT}     "${output}"


