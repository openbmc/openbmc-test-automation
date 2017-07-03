*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/state_manager.robot
Library                ../data/model.py

Suite Setup            Setup The Suite
Test Setup             Open Connection And Log In
Test Teardown          Post Test Case Execution

*** Variables ***
${model}=    ${OPENBMC_MODEL}

*** Test Cases ***
Verify connection
    Execute new Command    echo "hello"
    Response Should Be Equal    "hello"

Execute ipmi BT capabilities command
    [Tags]  Execute_ipmi_BT_capabilities_command
    Run IPMI command            0x06 0x36
    response Should Be Equal    " 01 40 40 0a 01"

Execute Set Sensor Boot Count
    [Tags]  Execute_Set_Sensor_Boot_Count

    ${uri}=    Get System component    BootCount
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command   0x04 0x30 ${x} 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00 0x00
    Read the Attribute      ${uri}   value
    ${val}=     convert to integer    53
    Response Should Be Equal   ${val}

Set Sensor Boot Progress
    [Tags]  Set_Sensor_Boot_Progress

    ${uri}=    Get System component    BootProgress
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x14 0x00
    Read the Attribute  ${uri}    value
    Response Should Be Equal    FW Progress, Baseboard Init

Set Sensor Boot Progress Longest String
    [Tags]  Set_Sensor_Boot_Progress_Longest_String
    ${uri}=    Get System component    BootProgress
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x04 0x00 0x00 0x00 0x00 0x0e 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    FW Progress, Docking station attachment

Boot Progress Sensor FW Hang Unspecified Error
    [Tags]  Boot_Progress_Sensor_FW_Hang_Unspecified_Error

    ${uri}=    Get System component    BootProgress
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    FW Hang, Unspecified

Boot Progress FW Hang State
    [Tags]  Boot_Progress_FW_Hang_State

    ${uri}=    Get System component    BootProgress
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    value
    Response Should Be Equal    POST Error, unknown

OS Status Sensor Boot Completed Progress
    [Tags]  OS_Status_Sensor_Boot_Completed_Progress

    ${uri}=    Get System component    OperatingSystemStatus
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Boot completed (00)

OS Status Sensor Progress
    [Tags]  OS_Status_Sensor_Progress

    ${uri}=    Get System component    OperatingSystemStatus
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x04 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    PXE boot completed

OCC Active Sensor On Enabled
    [Tags]  OCC_Active_Sensor_On_Enabled

    ${uri}=    Get System component    OccStatus
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Enabled

OCC Active Sensor On Disabled
    [Tags]  OCC_Active_Sensor_On_Disabled

    ${uri}=    Get System component    OccStatus
    ${x}=      Get Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}     value
    Response Should Be Equal    Disabled

Verify OCC Power Supply Redundancy
    [Documentation]  Check if OCC's power supply is set to not redundant.
    [Tags]  Verify_OCC_Power_Supply_Redundancy
    ${uri}=  Get System Component  PowerSupplyRedundancy

    Read The Attribute  ${uri}  value
    Response Should Be Equal  Disabled

Verify OCC Power Supply Derating Value
    [Documentation]  Check if OCC's power supply derating value
    ...  is set correctly to a constant value 10.
    [Tags]  Verify_OCC_Power_Supply_Derating_Value

    ${uri}=  Get System Component  PowerSupplyDerating

    Read The Attribute  ${uri}  value
    Response Should Be Equal  ${10}


Verify Enabling OCC Turbo Setting Via IPMI
    [Documentation]  Set and verify OCC's turbo allowed on enable.
    # The allowed value for turbo allowed:
    # True  - To enable turbo allowed.
    # False - To disable turbo allowed.
    [Setup]  Turbo Setting Test Case Setup
    [Tags]  Verify_Enabling_OCC_Turbo_Setting_Via_IPMI
    [Teardown]  Restore System Configuration

    ${uri}=  Get System Component  TurboAllowed
    ${sensor_num}=  Get Sensor Number  ${uri}

    ${ipmi_cmd}=  Catenate  SEPARATOR=  0x04 0x30 ${sensor_num} 0x00${SPACE}
    ...  0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Run IPMI Command  ${ipmi_cmd}

    Read The Attribute  ${uri}  value
    Response Should Be Equal  True


Verify Disabling OCC Turbo Setting Via IPMI
    [Documentation]  Set and verify OCC's turbo allowed on disable.
    # The allowed value for turbo allowed:
    # True  - To enable turbo allowed.
    # False - To disable turbo allowed.
    [Setup]  Turbo Setting Test Case Setup
    [Tags]  Verify_Disabling_OCC_Turbo_Setting_Via_IPMI
    [Teardown]  Restore System Configuration

    ${uri}=  Get System Component  TurboAllowed
    ${sensor_num}=  Get Sensor Number  ${uri}

    ${ipmi_cmd}=  Catenate  SEPARATOR=  0x04 0x30 ${sensor_num} 0x00${SPACE}
    ...  0x00 0x00 0x00 0x01 0x00 0x00 0x20 0x00
    Run IPMI Command  ${ipmi_cmd}

    Read The Attribute  ${uri}  value
    Response Should Be Equal  False


Verify Setting OCC Turbo Via REST
    [Documentation]  Verify enabling and disabling OCC's turbo allowed
    ...  via REST.
    # The allowed value for turbo allowed:
    # True  - To enable turbo allowed.
    # False - To disable turbo allowed.

    [Setup]  Turbo Setting Test Case Setup
    [Tags]  Verify_Setting_OCC_Turbo_Via_REST
    [Teardown]  Restore System Configuration

    Set Turbo Setting Via REST  False
    ${setting}=  Read Turbo Setting Via REST
    Should Be Equal  ${setting}  False

    Set Turbo Setting Via REST  True
    ${setting}=  Read Turbo Setting Via REST
    Should Be Equal  ${setting}  True

CPU Present
    [Tags]  CPU_Present

    ${uri}=    Get System component    cpu
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    present
    Response Should Be Equal    True

CPU Not Present
    [Tags]  CPU_Not_Present

    ${uri}=    Get System component    cpu
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    present
    Response Should Be Equal    False

CPU No Fault
    [Tags]  CPU_No_Fault

    ${uri}=    Get System component    cpu
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    False

Core Present
    [Tags]  Core_Present

    ${uri}=    Get System component    core11
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}   present
    Response Should Be Equal    True

Core Not Present
    [Tags]  Core_Not_Present

    ${uri}=    Get System component    core11
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}   present
    Response Should Be Equal    False

Core Fault
    [Tags]  Core_Fault

    ${uri}=    Get System component    core11
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    True

Core No Fault
    [Tags]  Core_No_Fault

    ${uri}=    Get System component    core11
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${uri}    fault
    Response Should Be Equal    False

DIMM3 Present
    [Tags]    DIMM3_Present

    ${uri}=    Get System component    dimm3
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     present
    Response Should Be Equal    True

DIMM3 not Present
    [Tags]    DIMM3_not_Present

    ${uri}=    Get System component    dimm3
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0xff 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     present
    Response Should Be Equal    False

DIMM0 no fault
    [Tags]    DIMM0_no_fault
    ${uri}=    Get System component    dimm0
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}     fault
    Response Should Be Equal    False

Centaur0 Present
    [Tags]  Centaur0_Present

    ${uri}=    Get System component    membuf
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

Centaur0 not Present
    [Tags]  Centaur0_not_Present

    ${uri}=    Get System component    membuf
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    present
    Response Should Be Equal    False

Centaur0 Fault
    [Tags]  Centaur0_Fault

    ${uri}=    Get System component    membuf
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    True

Centaur0 No Fault
    [Tags]  Centaur0_No_Fault

    ${uri}=    Get System component    membuf
    ${x}=      Get Inventory Sensor Number   ${uri}

    Run IPMI command  0x04 0x30 ${x} 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

System Present
    [Tags]  System_Present

    ${uri}=    Get System component    system
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

System Fault
    [Tags]  System_Fault
    ${uri}=    Get System component    system
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

Chassis Present
    [Tags]  Chassis_Present

    ${uri}=    Get System component    chassis
    Read The Attribute
    ...   ${INVENTORY_URI}system/chassis    present
    Response Should Be Equal    True

Chassis Fault
    [Tags]  Chassis_Fault
    ${uri}=    Get System component    chassis
    Read The Attribute
    ...   ${INVENTORY_URI}system/chassis    fault
    Response Should Be Equal    False

io_board Present
    [Tags]  io_board_Present
    ${uri}=    Get System component    io_board
    Read The Attribute   ${uri}    present
    Response Should Be Equal    True

io_board Fault
    [Tags]  io_board_Fault
    ${uri}=    Get System component    io_board
    Read The Attribute   ${uri}    fault
    Response Should Be Equal    False

*** Keywords ***

Setup The Suite
    [Documentation]  Do the initial suite setup.
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is OS Starting

    Open Connection And Log In
    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=30
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}

Turbo Setting Test Case Setup
    [Documentation]  Open Connection and turbo settings

    Open Connection And Log In
    ${setting}=  Read Turbo Setting Via REST
    Set Global Variable  ${TURBO_SETTING}  ${setting}

Get System component
    [Arguments]    ${type}
    ${list}=    Get Dictionary Keys    ${SYSTEM_INFO}
    ${resp}=    Get Matches    ${list}    regexp=^.*[0-9a-z_].${type}[0-9]*$
    ${url}=    Get From List    ${resp}    0
    [Return]    ${url}

Execute new Command
    [Arguments]    ${args}
    ${output}=  Execute Command    ${args}
    set test variable    ${OUTPUT}     "${output}"

response Should Be Equal
    [Arguments]    ${args}
    Should Be Equal    ${OUTPUT}    ${args}

Response Should Be Empty
    Should Be Empty    ${OUTPUT}

Read the Attribute
    [Arguments]    ${uri}    ${parm}
    ${output}=     Read Attribute      ${uri}    ${parm}
    set test variable    ${OUTPUT}     ${output}

Get Sensor Number
    [Arguments]  ${name}
    ${x}=       get sensor   ${OPENBMC_MODEL}   ${name}
    [Return]     ${x}

Get Inventory Sensor Number
    [Arguments]  ${name}
    ${x}=       get inventory sensor   ${OPENBMC_MODEL}   ${name}
    [Return]     ${x}

Read Turbo Setting Via REST
    [Documentation]  Return turbo allowed setting.

    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}host/TurboAllowed
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    [Return]  ${jsondata["data"]["value"]}

Set Turbo Setting Via REST
    [Documentation]  Set turbo setting via REST.
    [Arguments]  ${setting}
    # Description of argument(s):
    # setting  Value which needs to be set.(i.e. False or True)

    ${valueDict}=  Create Dictionary  data=${setting}
    Write Attribute  ${SENSORS_URI}host/TurboAllowed  value  data=${valueDict}

Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections

Restore System Configuration
    [Documentation]  Restore System Configuration.

    Open Connection And Log In
    Set Turbo Setting Via REST  ${TURBO_SETTING}
    Close All Connections
