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
    [Documentation]  Verify the IPMI sensor for present and not present.
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
    [Documentation]  Verify that the DIMM is Functional.
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

CPU Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  CPU_Present_And_Not_Present

    # Set the cpu0 Present to 1
    Run IPMI Command
    ...  0x04 0x30 0x5a 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0  Present  ${1}

    # Set the cpu0 Present to 0
    Run IPMI Command
    ...  0x04 0x30 0x5a 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0  Present  ${0}

CPU Functional And Not Functional
    [Documentation]  Verify that the CPU is Functional.
    [Tags]  CPU_Functional_And_Not_Functional

    # Set the cpu0 Functional to 0
    Run IPMI Command
    ...  0x04 0x30 0x5a 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0
    ...  Functional  ${0}

    # Set the cpu0 Functional to 1
    Run IPMI Command
    ...  0x04 0x30 0x5a 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0
    ...  Functional  ${1}

Core Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  Core_Present_And_Not_Present

    # Set the Core Present to 1
    Run IPMI Command
    ...  0x04 0x30 0x1e 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4
    ...  Present  ${1}

    # Set the core4 of cpu0 Present to 0
    Run IPMI Command
    ...  0x04 0x30 0x1e 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4
    ...  Present  ${0}

Core Functional And Not Functional
    [Documentation]  Verify that the Core is Functional.
    [Tags]  Core_Functional_And_Not_Functional

    # Set the core4 of cpu0 Functional to 0
    Run IPMI Command
    ...  0x04 0x30 0x1e 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4
    ...  Functional  ${0}

    # Set the core4 of cpu0 Functional to 1
    Run IPMI Command
    ...  0x04 0x30 0x1e 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/cpu0/core4
    ...  Functional  ${1}

GPU Present And Not Present
    [Documentation]  Verify the IPMI sensor for present and not present.
    [Tags]  GPU_Present_And_Not_Present

    # Set GPU card0 Present to 1
    Run IPMI Command
    ...  0x04 0x30 0xC5 0xa9 0x00 0x80 0x00 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0
    ...  Present  ${1}

    # Set the GPU card0 Present to 0
    Run IPMI Command
    ...  0x04 0x30 0xC5 0xa9 0x00 0x00 0x00 0x80 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0
    ...  Present  ${0}

GPU Functional And Not Functional
    [Documentation]  Verify that the GPU is Functional.
    [Tags]  GPU_Functional_And_Not_Functional

    # Set the GPU card0 Functional to 0
    Run IPMI Command
    ...  0x04 0x30 0xC5 0xa9 0xff 0x00 0x01 0x00 0x00 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0
    ...  Functional  ${0}

    # Set the GPU card0 Functional to 1
    Run IPMI Command
    ...  0x04 0x30 0xC5 0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x20 0x00
    Verify The Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/gv100card0
    ...  Functional  ${1}

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

# Boot Progress Sensor Test Cases

Set Boot Progress Sensor Unspecified
    [Documentation]  Boot Progress sensor to "Unspecified" state.
    [Tags]  Set_Boot_Progress_Sensor_Unspecified

    # Set the Boot Progress to Unspecified
    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 0x00 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${OS_BOOT_OFF}  ${resp}

Set Boot Progress Sensor OSStart
    [Documentation]  Set Boot Progress sensor to "OSStart" state.
    [Tags]  Set_Boot_Progress_Sensor_OSStart

    # Set the Boot Progress to OSStart
    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 0x13 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${OS_BOOT_START}  ${resp}

Set Boot Progress Sensor PCIinit
    [Documentation]  Set Boot Progress sensor to "PCIinit" state.
    [Tags]  Set_Boot_Progress_Sensor_PCIInit

    # Set the Boot Progress to PCIinit
    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 0x07 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${OS_BOOT_PCI}  ${resp}

Set Boot Progress Sensor SecondaryProcInit
    [Documentation]  Set Boot Progress sensor to "SecondaryProcInit" state.
    [Tags]  Set_Boot_Progress_Sensor_SecondaryProcInit

    # Set the Boot Progress to SecondaryProcInit
    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 0x03 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${OS_BOOT_SECPCI}  ${resp}

Set Boot Progress Sensor MemoryInit
    [Documentation]  Set Boot Progress sensor to "MemoryInit" state.
    [Tags]  Set_Boot_Progress_Sensor_MemoryInit

    # Set the Boot Progress to MemoryInit
    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 0x01 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${OS_BOOT_MEM}  ${resp}

Set Boot Progress Sensor MotherboardInit
    [Documentation]  Set Boot Progress sensor to "MotherboardInit" state.
    [Tags]  Set_Boot_Progress_Sensor_MotherboardInit

    # Set the Boot Progress to MotherboardInit
    Run IPMI Command
    ...  0x04 0x30 0x03 0xa8 0x00 0x04 0x00 0x00 0x00 0x00 0x14 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  BootProgress
    Should Be Equal  ${OS_BOOT_MOTHERBOARD}  ${resp}

# OperatingSystemState Test Cases

Set OperatingSystemState CDROMBoot
    [Documentation]  Set OperatingSystemState to "CDROMBoot".
    [Tags]  Set_OperatingSystemState_CDROMBoot

    # Set OperatingSystemState to CDROMBoot
    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 0x10 0x00 0x00 0x00 0x00 0x00 0x000
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OS_BOOT_CDROM}  ${resp}

Set OperatingSystemState ROMBoot
    [Documentation]  Set OperatingSystemState "ROMBoot".
    [Tags]  Set_OperatingSystemState_ROMBoot

    # Set OperatingSystemState to ROMBoot
    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 0x20 0x00 0x00 0x00 0x00 0x00 0x000
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OS_BOOT_ROM}  ${resp}

Set OperatingSystemState BootComplete
    [Documentation]  Set OperatingSystemState "BootComplete".
    [Tags]  Set_OperatingSystemState_BootComplete

    # Set OperatingSystemState to BootComplete
    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 0x40 0x00 0x00 0x00 0x00 0x00 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OS_BOOT_COMPLETE}  ${resp}

Set OperatingSystemState PXEBoot
    [Documentation]  Set OperatingSystemState "PXEBoot".
    [Tags]  Set_OperatingSystemState_PXEBoot

    # Set OperatingSystemState to PXEBoot
    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 0x05 0x00 0x00 0x00 0x00 0x00 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OS_BOOT_PXE}  ${resp}

Set OperatingSystemState CBoot
    [Documentation]  Set OperatingSystemState "CBoot".
    [Tags]  Set_OperatingSystemState_CBoot

    # Set OperatingSystemState to CBoot
    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OS_BOOT_CBoot}  ${resp}

Set OperatingSystemState Diagboot
    [Documentation]  Set OperatingSystemState "Diagboot".
    [Tags]  Set_OperatingSystemState_Diagboot

    # Set OperatingSystemState to Diagboot
    Run IPMI Command
    ...  0x04 0x30 0x05 0xa9 0x00 0x08 0x00 0x00 0x00 0x00 0x00 0x00
    ${resp}=  Read Attribute  ${SYSTEM_STATE_URI}/host0  OperatingSystemState
    Should Be Equal  ${OS_BOOT_DiagBoot}  ${resp}

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
    ...  msg=Incorrect Output

*** Keywords ***

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

