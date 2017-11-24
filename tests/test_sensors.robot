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
Resource               ../lib/boot_utils.robot
Resource               ../lib/utils.robot

Suite Setup            Setup The Suite
Test Setup             Open Connection And Log In
Test Teardown          Post Test Case Execution

*** Variables ***

${stack_mode}     skip
${model}=         ${OPENBMC_MODEL}

***Test Cases***

Verify IPMI BT Capabilities Command
    [Documentation]  Verify IPMI BT capability command response.
    [Tags]  Verify_IPMI BT_Capabilities_Command
    [Setup]  REST Power On

    ${output} =  Run IPMI command  0x06 0x36
    Should Be Equal As Strings  "${output}"  " 01 3f 3f 0a 01"

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

DIMM Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  DIMM_Present_And_Not_Present

    Run IPMI Command
    ...  0x04 0x30 0xac 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3  Present
    Response Should Be Equal  ${1}
    Run IPMI Command
    ...  0x04 0x30 0xac 0xa9 0xff 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3  Present
    Response Should Be Equal  ${0}

DIMM Functional And Not Functional
    [Documentation]  Verify that the DIMM is Functional.
    [Tags]  DIMM_Functional_And_Not_Functional

    Run IPMI Command
    ...  0x04 0x30 0xac 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3  Functional
    Response Should Be Equal  ${0}
    Run IPMI Command
    ...  0x04 0x30 0xac 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3  Functional
    Response Should Be Equal  ${1}

CPU Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  CPU Present_And_Not_Present

    Run IPMI Command
    ...  0x04 0x30 0x5a 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0  Present
    Response Should Be Equal  ${1}
    Run IPMI Command
    ...  0x04 0x30 0x5a 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0  Present
    Response Should Be Equal  ${0}

CPU Functional And Not Functional
    [Documentation]  Verify that the CPU is Functional.
    [Tags]  CPU_Functional_And_Not_Functional

    Run IPMI Command
    ...  0x04 0x30 0x5a 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0  Functional
    Response Should Be Equal  ${0}
    Run IPMI Command
    ...  0x04 0x30 0x5a 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0  Functional
    Response Should Be Equal  ${1}

Core Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  Core_Present_And_Not_Present

    Run IPMI Command
    ...  0x04 0x30 0x1e 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4  Present
    Response Should Be Equal  ${1}
    Run IPMI Command
    ...  0x04 0x30 0x1e 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4  Present
    Response Should Be Equal  ${0}

Core Functional And Not Functional
    [Documentation]  Verify that the Core is Functional.
    [Tags]  Core_Functional_And_Not_Functional

    Run IPMI Command
    ...  0x04 0x30 0x1e 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4  Functional
    Response Should Be Equal  ${0}
    Run IPMI Command
    ...  0x04 0x30 0x1e 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4  Functional
    Response Should Be Equal  ${1}

GPU Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  GPU_Present_And_Not_Present

    Run IPMI Command
    ...  0x04 0x30 0xC5 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0  Present
    Response Should Be Equal  ${1}
    Run IPMI Command
    ...  0x04 0x30 0xC5 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0  Present
    Response Should Be Equal  ${0}

GPU Functional And Not Functional
    [Documentation]  Verify that the GPU is Functional.
    [Tags]  GPU_Functional_And_Not_Functional

    Run IPMI Command
    ...  0x04 0x30 0xC5 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0  Functional
    Response Should Be Equal  ${0}
    Run IPMI Command
    ...  0x04 0x30 0xC5 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Read The Attribute  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0  Functional
    Response Should Be Equal  ${1}

TPM Enable and Disable
    [Documentation]  Enable and disable TPM.
    [Tags]  TPM_Enable_and_Disable

    Run IPMI Command
    ...  0x04 0x30 0xD7 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${CONTROL_URI}/host0/TPMEnable  TPMEnable
    Response Should Be Equal  ${0}
    Run IPMI Command
    ...  0x04 0x30 0xD7 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${CONTROL_URI}/host0/TPMEnable  TPMEnable
    Response Should Be Equal  ${1}

Autoreboot Enable and Disable
    [Documentation]  Enable and disable Autoreboot.
    [Tags]  Autoreboot_Enable_and_Disable

    Run IPMI Command
    ...  0x04 0x30 0xDA 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${CONTROL_URI}/host0/auto_reboot  AutoReboot
    Response Should Be Equal  ${0}
    Run IPMI Command
    ...  0x04 0x30 0xDA 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${CONTROL_URI}/host0/TPMEnable  TPMEnable
    Response Should Be Equal  ${1}

OCC Active Enable And Disable
    [Documentation]  OCC Active Enable And Disable.
    [Tags]  OCC_Active_Enable_And_Disable

    Run IPMI Command
    ...  0x04 0x30 0x08 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${OPENPOWER_CONTROL}/occ0  OccActive
    Response Should Be Equal  ${1}
    Run IPMI Command
    ...  0x04 0x30 0x09 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${OPENPOWER_CONTROL}/occ0  OccActive
    Response Should Be Equal  ${0}

OS Status Sensor Progress
    [Documentation]  OS Status Sensor Progress.
    [Tags]  OS_Status_Sensor_Progress

    Run IPMI Command
    ...  0x04 0x30 0x05 0x00 0x00 0x04 0x00 0x00 0x00 0x00 0x20 0x00
    Read The Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Response Should Be Equal  xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.PXEBoot

Boot Progress Sensor Unspecified Error
    [Documentation]  Boot Progress Sensor Unspecified Error.
    [Tags]  Boot_Progress_Sensor_Unspecified_Error

    Run IPMI Command
    ...  0x04 0x30 0x03 0xa9 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00
    Read The Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Response Should Be Equal  xyz.openbmc_project.State.Boot.Progress.ProgressStages.Unspecified

*** Keywords ***

Setup The Suite
    [Documentation]  Initial suite setup.

    # Boot Host.
    REST Power On

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


response Should Be Equal
    [Arguments]    ${args}
    Should Be Equal    ${OUTPUT}    ${args}

Read the Attribute
    [Arguments]    ${uri}    ${parm}
    ${output}=     Read Attribute      ${uri}    ${parm}
    set test variable    ${OUTPUT}     ${output}

Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
