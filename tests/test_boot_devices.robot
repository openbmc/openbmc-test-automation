*** Settings ***

Documentation   This testsuite is for testing the Boot Device Functions

Resource        ../lib/rest_client.robot
Resource        ../lib/ipmi_client.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/utils.robot
Resource        ../lib/boot_utils.robot

Suite Setup     Test Suite Setup
Test Teardown   Post Test Case Execution

*** Variables ***

${stack_mode}           skip


*** Test Cases ***

Set The Boot Source As Default Using REST API
    [Documentation]  Set default boot source via REST and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_Default_Using_REST_API

    Set Boot Source  ${BOOT_SOURCE_DEFAULT}

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_DEFAULT}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  No override


Set The Boot Source As Default Using Ipmitool
    [Documentation]  Set default boot source via IPMI and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_Default_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_DEFAULT}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  No override


Set The Boot Source As Network Using REST API
    [Documentation]  Set boot source as Network via REST and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_Network_Using_REST_API

    Set Boot Source  ${BOOT_SOURCE_NETWORK}

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_NETWORK}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force PXE


Set The Boot Source As Network Using Ipmitool
    [Documentation]  Set boot source as Network via IPMI and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_Network_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x04 0x00 0x00 0x00

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_NETWORK}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force PXE


Set The Boot Source As Disk Using REST API
    [Documentation]  Set boot source as Disk via REST and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_Disk_Using_REST_API

    Set Boot Source  ${BOOT_SOURCE_DISK}

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_DISK}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from default Hard-Drive


Set The Boot Source As Disk Using Ipmitool
    [Documentation]  Set boot source as Disk via IPMI and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_Disk_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x08 0x00 0x00 0x00

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_DISK}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from default Hard-Drive


Set The Boot Mode As Safe Using REST API
    [Documentation]  Set boot mode as Safe via REST and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Mode_As_Safe_Using_REST_API

    Set Boot Mode  ${BOOT_MODE_SAFE}

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootMode
    Should Be Equal As Strings  ${boot_mode}  ${BOOT_MODE_SAFE}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Safe-Mode


Set The Boot Mode As Safe Using Ipmitool
    [Documentation]  Set boot mode as Safe via IPMI and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Mode_As_Safe_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x0C 0x00 0x00 0x00

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootMode
    Should Be Equal As Strings  ${boot_mode}  ${BOOT_MODE_SAFE}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Safe-Mode


Set The Boot Source As CDROM Using REST API
    [Documentation]  Set boot source as CDROM via REST and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_CDROM_Using_REST_API

    Set Boot Source  ${BOOT_SOURCE_CDROM}

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_CDROM}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from CD/DVD


Set The Boot Source As CDROM Using Ipmitool
    [Documentation]  Set boot source as CDROM via IPMI and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Source_As_CDROM_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x14 0x00 0x00 0x00

    ${boot_source}=
    ...  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    Should Be Equal As Strings  ${boot_source}  ${BOOT_SOURCE_CDROM}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot from CD/DVD


Set The Boot Mode As Setup Using REST API
    [Documentation]  Set boot mode as Setup via REST and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Mode_As_Setup_Using_REST_API

    Set Boot Mode  ${BOOT_MODE_SETUP}

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootMode
    Should Be Equal As Strings  ${boot_mode}  ${BOOT_MODE_SETUP}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot into BIOS Setup


Set The Boot Mode As Setup Using Ipmitool
    [Documentation]  Set boot mode as Setup via IPMI and verify with both
    ...              REST and IPMI.
    [Tags]  Set_The_Boot_Mode_As_Setup_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x18 0x00 0x00 0x00

    ${boot_mode}=  Read Attribute  ${CONTROL_HOST_URI}boot/one_time  BootMode
    Should Be Equal As Strings  ${boot_mode}  ${BOOT_MODE_SETUP}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Force Boot into BIOS Setup


*** Keywords ***

Set Boot Source
    [Documentation]  Set given boot source.
    [Arguments]  ${boot_source}
    # Description of argument(s):
    # boot_source  Boot source which need to be set.

    ${valueDict}=  Create Dictionary  data=${boot_source}
    Write Attribute  ${CONTROL_HOST_URI}boot/one_time  BootSource
    ...  data=${valueDict}


Set Boot Mode
    [Documentation]  Set given boot mode.
    [Arguments]  ${boot_mode}
    # Description of argument(s):
    # boot_mode  Boot mode which need to be set.

    ${valueDict}=  Create Dictionary  data=${boot_mode}
    Write Attribute  ${CONTROL_HOST_URI}boot/one_time  BootMode
    ...  data=${valueDict}


Response Should Be Equal
    [Documentation]  Verify that the output is equal to the given args.
    [Arguments]  ${args}
    Should Be Equal  ${OUTPUT}  ${args}

Read the Attribute
    [Documentation]  Read the given attribute.
    [Arguments]  ${uri}  ${parm}
    ${output}=  Read Attribute  ${uri}  ${parm}
    Set Test Variable  ${OUTPUT}  ${output}

Post Test Case Execution
   [Documentation]  Do the post test teardown.

   FFDC On Test Case Fail
   Set Boot Source  ${BOOT_SOURCE_DEFAULT}
   Set Boot Mode  ${BOOT_MODE_REGULAR}

Test Suite Setup
    [Documentation]  Do the initial suite setup.

    Smart Power Off

    # Set boot policy to default i.e. one time enabled.
    ${valueDict}=  Create Dictionary  data=${1}
    Write Attribute  ${CONTROL_HOST_URI}boot/one_time  Enabled
    ...  data=${valueDict}
