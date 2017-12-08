*** Settings ***
Documentation  Test IPMI sensor IDs

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/state_manager.robot
Library                ../../data/model.py
Resource               ../../lib/boot_utils.robot
Resource               ../../lib/utils.robot

Test Setup              Open Connection And Log In
Test Teardown           Test Teardown Execution

*** Test Cases ***

DIMM Present And Not Present
    [Documentation]  Verify the IPMI sensor for DIMM3 present and not present.
    [Tags]  DIMM_Present_And_Not_Present

    # Set the dimm3 Present to 1
    Run IPMI Command
    ...  0x04 0x30 0xac 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3  Present  ${1}

    # Set the dimm3 Present to 0
    Run IPMI Command
    ...  0x04 0x30 0xac 0xa9 0xff 0x00 0x00 0x40 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3  Present  ${0}

DIMM Functional And Not Functional
    [Documentation]  Verify that the DIMM3 is functional.
    [Tags]  DIMM_Functional_And_Not_Functional

    # Set the dimm3 Functional to 0
    Run IPMI Command
    ...  0x04 0x30 0xac 0x00 0x00 0x10 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3
    ...  Functional  ${0}
    # Set the dimm3 Functional to 1
    Run IPMI Command
    ...  0x04 0x30 0xac 0x00 0x00 0x00 0x00 0x10 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/dimm3
    ...  Functional  ${1}

CPU Present
    [Documentation]  Verify the IPMI sensor for CPU present.

    # SensorID  Component
    0x5a        cpu0

    [Template]  Check Present Bit
    [Tags]  CPU_Present

CPU Not Present
    [Documentation]  Verify the IPMI sensor for CPU not present.

    # SensorID  Component
    0x5a        cpu0

    [Template]  Check Not Present Bit
    [Tags]  CPU_Not_Present

CPU Functional
    [Documentation]  Verify the IPMI sensor for CPU functional.

    # SensorID  Component
    0x5a        cpu0

    [Template]  Check Functional Bit
    [Tags]  CPU_Functional

CPU Not Functional
    [Documentation]  Verify the IPMI sensor for CPU not functional.

    # SensorID  Component
    0x5a        cpu0

    [Template]  Check Not Functional Bit
    [Tags]  CPU_Not_Functional

GPU Present
    [Documentation]  Verify the IPMI sensor for GPU present.

    # SensorID  Component
    0xC5        gv100card0

    [Template]  Check Present Bit
    [Tags]  GPU_Present

GPU Not Present
    [Documentation]  Verify the IPMI sensor for GPU not present.

    # SensorID  Component
    0xC5        gv100card0

    [Template]  Check Not Present Bit
    [Tags]  GPU_Not_Present

GPU Functional
    [Documentation]  Verify the IPMI sensor GPU for functional.

    # SensorID  Component
    0xC5        gv100card0

    [Template]  Check Functional Bit
    [Tags]  GPU_Functional

GPU Not Functional
    [Documentation]  Verify the IPMI sensor GPU for not functional.

    # SensorID  Component
    0xC5        gv100card0

    [Template]  Check Not Functional Bit
    [Tags]  GPU_Not_Functional

Core Present
    [Documentation]  Verify the IPMI sensor for core present.

    # SensorID  Component
    0x1e        cpu0/core4

    [Template]  Check Present Bit
    [Tags]  Core_Present

Core Not Present
    [Documentation]  Verify the IPMI sensor for core not present.

    # SensorID  Component
    0x1e        cpu0/core4

    [Template]  Check Not Present Bit
    [Tags]  Core_Not_Present

Core Functional
    [Documentation]  Verify the IPMI sensor for core functional.

    # SensorID  Component
    0x1e        cpu0/core4

    [Template]  Check Functional Bit
    [Tags]  Core_Functional

Core Not Functional
    [Documentation]  Verify the IPMI sensor for core not functional.

    # SensorID  Component
    0x1e        cpu0/core4

    [Template]  Check Not Functional Bit
    [Tags]  Core_Not_Functional

# Operating System State Test Cases.

Set OperatingSystemState To CBoot And Verify
    [Documentation]  Set Operating System State to "CBoot"
    ...  and verify using REST.

    # OperatingSystemStateID  OperatingSystemState
    0x02                      ${OS_BOOT_CBoot}

    [Template]  Check OperatingSystemState
    [Tags]  Set_OperatingSystemState_To_CBoot_And_Verify

Set OperatingSystemState To PXEBoot And Verify
    [Documentation]  Set Operating System State to "PXEBoot"
    ...  and verify using REST.

    # OperatingSystemStateID  OperatingSystemState
    0x05                      ${OS_BOOT_PXE}

    [Template]  Check OperatingSystemState
    [Tags]  Set_OperatingSystemState_To_PXEBoot_And_Verify

Set OperatingSystemState To BootComplete And Verify
    [Documentation]  Set Operating System State to "BootComplete"
    ...  and verify using REST.

    # OperatingSystemStateID  OperatingSystemState
    0x40                      ${OS_BOOT_COMPLETE}

    [Template]  Check OperatingSystemState
    [Tags]  Set_OperatingSystemState_To_BootComplete_And_Verify

Set OperatingSystemState To CDROMBoot And Verify
    [Documentation]  Set Operating System State to "CDROMBoot"
    ...  and verify using REST.

    # OperatingSystemStateID  OperatingSystemState
    0x10                      ${OS_BOOT_CDROM}

    [Template]  Check OperatingSystemState
    [Tags]  Set_OperatingSystemState_To_CDROMBoot_And_Verify

Set OperatingSystemState To ROMBoot And Verify
    [Documentation]  Set Operating System State to "ROMBoot"
    ...  and verify using REST.

    # OperatingSystemStateID  OperatingSystemState
    0x20                      ${OS_BOOT_ROM}

    [Template]  Check OperatingSystemState
    [Tags]  Set_OperatingSystemState_To_ROMBoot_And_Verify

Set OperatingSystemState To DiagBoot And Verify
    [Documentation]  Set Operating System State to "DiagBoot"
    ...  and verify using REST.

    # OperatingSystemStateID  OperatingSystemState
    0x08                      ${OS_BOOT_DiagBoot}

    [Template]  Check OperatingSystemState
    [Tags]  Set_OperatingSystemState_To_DiagBoot_And_Verify

# Boot Progress Test Cases.

Set BootProgress To MemoryInit And Verify
    [Documentation]  Set BootProgress To MemoryInit and verify.

    # BootProgressID  BootProgress
    0x01              ${OS_BOOT_MEM}

    [Template]  Check BootProgress
    [Tags]  Set_BootProgress_To_MemoryInit_And_Verify

Set BootProgress To MemoryInit And Verify
    [Documentation]  Set BootProgress To MemoryInit and verify.

    # BootProgressID  BootProgress
    0x14              ${OS_BOOT_MOTHERBOARD}

    [Template]  Check BootProgress
    [Tags]  Set_BootProgress_To_MotherboardInit_And_Verify

Set BootProgress To SecondaryProcInit And Verify
    [Documentation]  Set BootProgress To SecondaryProcInit and verify.

    # BootProgressID  BootProgress
    0x03              ${OS_BOOT_SECPCI}

    [Template]  Check BootProgress
    [Tags]  Set_BootProgress_To_SecondaryProcInit_And_Verify

Set BootProgress To PCIinit And Verify
    [Documentation]  Set BootProgress To PCIinit and verify.

    #BootProgressID  BootProgress
    0x07             ${OS_BOOT_PCI}

    [Template]  Check BootProgress
    [Tags]  Set_BootProgress_To_PCIinit_And_Verify

Set BootProgress To OSStart And Verify
    [Documentation]  Set BootProgress To OSStart and verify.

    # BootProgressID  BootProgress
    0x13              ${OS_BOOT_PCI}

    [Template]  Check BootProgress
    [Tags]  Set_BootProgress_To_OSStart_And_Verify

Set BootProgress To Unspecified And Verify
    [Documentation]  Set BootProgress To Unspecified and verify.

    # BootProgressID  BootProgress
    0x00              ${OS_BOOT_OFF}

    [Template]  Check BootProgress
    [Tags]  Set_BootProgress_To_Unspecified_And_Verify

TPM Enable and Disable
    [Documentation]  Enable and disable TPM.
    [Tags]  TPM_Enable_and_Disable

    # Set the TPMEnable to 0
    Run IPMI Command
    ...  0x04 0x30 0xD7 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute  ${CONTROL_URI}/host0/TPMEnable  TPMEnable  ${0}

    # Set the TPMEnable to 1
    Run IPMI Command
    ...  0x04 0x30 0xD7 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute  ${CONTROL_URI}/host0/TPMEnable  TPMEnable  ${1}

Autoreboot Enable and Disable
    [Documentation]  Enable and disable Autoreboot.
    [Tags]  Autoreboot_Enable_and_Disable

    # Set the TPMEnable to 0
    Run IPMI Command
    ...  0x04 0x30 0xDA 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute  ${CONTROL_URI}/host0/auto_reboot  AutoReboot  ${0}

    # Set the TPMEnable to 1
    Run IPMI Command
    ...  0x04 0x30 0xDA 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute  ${CONTROL_URI}/host0/auto_reboot  AutoReboot  ${1}

OccActive Enable And Disable
    [Documentation]  OCC Active Enable And Disable.
    [Tags]  OCC_Active_Enable_And_Disable

    # Set the OccActive to 1
    Run IPMI Command
    ...  0x04 0x30 0x08 0xa8 0x00 0x02 0x00 0x01 0x00 0x00 0x00 0x00
    Verify The Attribute  ${OPENPOWER_CONTROL}/occ0  OccActive  ${1}

    # Set the OccActive to 0
    Run IPMI Command
    ...  0x04 0x30 0x08 0xa8 0x00 0x01 0x00 0x02 0x00 0x00 0x00 0x00
    Verify The Attribute  ${OPENPOWER_CONTROL}/occ0  OccActive  ${0}

Verify IPMI BT Capabilities Command
    [Documentation]  Verify IPMI BT capability command response.
    [Tags]  Verify_IPMI BT_Capabilities_Command
    [Setup]  REST Power On

    ${output} =  Run IPMI command  0x06 0x36
    Should Be True  "${output}" == " 01 3f 3f 0a 01"
    ...  msg=Incorrect Output.

*** Keywords ***

Check Present Bit
    [Documentation]  Set the present field to 1 and verify.
    [Arguments]  ${Sensor_id}  ${Comp}

    Run IPMI Command
    ...  0x04 0x30 ${Sensor_id} 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${Comp}  Present  ${1}

Check Not Present Bit
    [Documentation]  Set the present field to 1 and verify.
    [Arguments]  ${Sensor_id}  ${Comp}

    Run IPMI Command
    ...  0x04 0x30 ${Sensor_id} 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${Comp}  Present  ${0}

Check Functional Bit
    [Documentation]  Set the functional to 1 and verify.
    [Arguments]  ${Sensor_id}  ${Comp}

    Run IPMI Command
    ...  0x04 0x30 ${Sensor_id} 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${Comp}  Functional  ${1}

Check Not Functional Bit
    [Documentation]  Set the functional to 0 and verify.
    [Arguments]  ${Sensor_id}  ${Comp}

    Run IPMI Command
    ...  0x04 0x30 ${Sensor_id} 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${Comp}  Functional  ${0}

Check OperatingSystemState
    [Documentation]  Set OperatingSystemState and verify.
    [Arguments]  ${Sensor_ID}  ${OperatingSystemState}
    # Description of argument(s):
    # ${Sensor_ID}  Corresponding to OperatingSystemState
    # ${OperatingSystemState}  OperatingSystemState to be set

    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 ${sensor_id} 0x00 0x00 0x00 0x00 0x00 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OperatingSystemState}  ${resp}

Check BootProgress
    [Documentation]  Set the Bootprogress and verify.
    [Arguments]  ${BootProgressID}  ${BootProgress}
    # Description of argument(s):
    # ${Sensor_ID}  Corresponding to BootProgress
    # ${BootProgress}  BootProgress to be set

    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 ${BootProgressID} 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${BootProgress}  ${resp}

Verify The Attribute
    [Arguments]  ${uri}  ${parm}  ${value}
    # Description of arguments:
    # ${uri}  URI path.
    # ${parm}  Attribute.
    # ${value}  Output to be compared.

    ${output}=  Read Attribute  ${uri}  ${parm}
    Should Be Equal  ${value}  ${output}

Test Teardown Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections

