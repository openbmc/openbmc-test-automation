*** Settings ***

Documentation   This testsuite is for testing the Boot Device Functions

Resource        ../lib/rest_client.robot
Resource        ../lib/ipmi_client.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/utils.robot
Resource        ../lib/boot_utils.robot

Suite Setup     Test Suite Setup
Test Setup      Pre Test Case Execution
Test Teardown   Post Test Case Execution
Suite Teardown  Close All Connections

*** Variables ***

${stack_mode}     skip
${HOST_SETTINGS}  ${SETTINGS_URI}host0

*** Test Cases ***

Set The Boot Source As Default Using REST API
    [Documentation]  This testcase is to set the boot device as default using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Source_As_Default_Using_REST_API

    Set Boot Source  xyz.openbmc_project.Control.Boot.Source.Sources.Default

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.Default

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  No override


Set The Boot Source As Default Using Ipmitool
    [Documentation]  This testcase is to set the boot device as default using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Source_As_Default_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.Default

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  No override


Set The Boot Source As Network Using REST API
    [Documentation]  This testcase is to set the boot device as Network using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Source_As_Network_Using_REST_API

    Set Boot Source  xyz.openbmc_project.Control.Boot.Source.Sources.Network

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.Network

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force PXE


Set The Boot Source As Network Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Network using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Source_As_Network_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x04 0x00 0x00 0x00

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.Network

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force PXE


Set The Boot Source As Disk Using REST API
    [Documentation]  This testcase is to set the boot device as Disk using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Source_As_Disk_Using_REST_API

    Set Boot Source  xyz.openbmc_project.Control.Boot.Source.Sources.Disk

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.Disk

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from default Hard-Drive


Set The Boot Source As Disk Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Disk using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Source_As_Disk_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x08 0x00 0x00 0x00

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.Disk

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from default Hard-Drive


Set The Boot Mode As Safe Using REST API
    [Documentation]  This testcase is to set the boot device as Safe using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Mode_As_Safe_Using_REST_API

    Set Boot Mode  xyz.openbmc_project.Control.Boot.Mode.Modes.Safe

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}/boot_mode  BootMode
    Should Be Equal As Strings
    ...  ${boot_mode}  xyz.openbmc_project.Control.Boot.Mode.Modes.Safe

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Safe-Mode


Set The Boot Mode As Safe Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Safe using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Mode_As_Safe_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x0C 0x00 0x00 0x00

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}/boot_mode  BootMode
    Should Be Equal As Strings
    ...  ${boot_mode}  xyz.openbmc_project.Control.Boot.Mode.Modes.Safe

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Safe-Mode


Set The Boot Source As CDROM Using REST API
    [Documentation]  This testcase is to set the boot device as CDROM using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Source_As_CDROM_Using_REST_API

    Set Boot Source  xyz.openbmc_project.Control.Boot.Source.Sources.ExternalMedia

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.ExternalMedia

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from CD/DVD


Set The Boot Source As CDROM Using Ipmitool
    [Documentation]  This testcase is to set the boot device as CDROM using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
   [Tags]  Set_The_Boot_Source_As_CDROM_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x14 0x00 0x00 0x00

    ${boot_source}=  Read Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource
    Should Be Equal As Strings
    ...  ${boot_source}  xyz.openbmc_project.Control.Boot.Source.Sources.ExternalMedia

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from CD/DVD


Set The Boot Mode As Setup Using REST API
    [Documentation]  This testcase is to set the boot device as Setup using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Mode_As_Setup_Using_REST_API

    Set Boot Mode  xyz.openbmc_project.Control.Boot.Mode.Modes.Setup

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}/boot_mode  BootMode
    Should Be Equal As Strings
    ...  ${boot_mode}  xyz.openbmc_project.Control.Boot.Mode.Modes.Setup

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot into BIOS Setup


Set The Boot Mode As Setup Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Setup using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Mode_As_Setup_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x18 0x00 0x00 0x00

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}/boot_mode  BootMode
    Should Be Equal As Strings
    ...  ${boot_mode}  xyz.openbmc_project.Control.Boot.Mode.Modes.Setup

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot into BIOS Setup


*** Keywords ***

Set Boot Source
    [Arguments]  ${args}
    ${bootsource}=  Set Variable  ${args}
    ${valueDict}=  Create Dictionary  data=${bootsource}
    Write Attribute  ${CONTROL_HOST_URI}/boot_source  BootSource  data=${valueDict}


Set Boot Mode
    [Arguments]    ${args}
    ${bootmode}=  Set Variable   ${args}
    ${valueDict}=  Create Dictionary  data=${bootmode}
    Write Attribute  ${CONTROL_HOST_URI}/boot_mode  BootMode  data=${valueDict}


Response Should Be Equal
    [Arguments]  ${args}
    Should Be Equal  ${OUTPUT}  ${args}

Read the Attribute
    [Arguments]  ${uri}  ${parm}
    ${output}=  Read Attribute  ${uri}  ${parm}
    Set Test Variable  ${OUTPUT}  ${output}

Pre Test Case Execution
   [Documentation]  Do the pre test setup.

   Open Connection And Log In
   Initialize DBUS cmd  "boot_flags"

Post Test Case Execution
   [Documentation]  Do the post test teardown.

   FFDC On Test Case Fail
   Set Boot Source  xyz.openbmc_project.Control.Boot.Source.Sources.Default
   Set Boot Mode  xyz.openbmc_project.Control.Boot.Mode.Modes.Regular
   Close All Connections

Test Suite Setup
    [Documentation]  Do the initial suite setup.

    # Boot Host.
    REST Power On
