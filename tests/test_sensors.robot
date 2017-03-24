*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Library                ../data/model.py

Suite setup            Setup The Suite
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

*** Keywords ***

Setup The Suite

    Open Connection And Log In
    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=30
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}

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

Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
