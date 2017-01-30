*** Settings ***

Documentation   This testsuite is for testing the Boot Device Functions

Resource        ../lib/rest_client.robot
Resource        ../lib/ipmi_client.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/utils.robot

Suite Setup     Open Connection And Log In
Suite Teardown  Close All Connections
Test Setup      Initialize DBUS cmd   "boot_flags"
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${HOST_SETTINGS}  ${SETTINGS_URI}host0

*** Test Cases ***

Set The Boot Device As Default Using REST API
    [Documentation]  This testcase is to set the boot device as default using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Device_As_Default_Using_REST_API

    ${bootDevice}=  Set Variable  default
    ${valueDict}=  create dictionary  data=${bootDevice}
    Write Attribute  ${HOST_SETTINGS}  boot_flags  data=${valueDict}
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  default
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  default

Set The Boot Device As Default Using Ipmitool
    [Documentation]  This testcase is to set the boot device as default using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Device_As_Default_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  default
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  default

Set The Boot Device As Network Using REST API
    [Documentation]  This testcase is to set the boot device as Network using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Device_As_Network_Using_REST_API

    ${bootDevice}=  Set Variable   Network
    ${valueDict}=  create dictionary   data=${bootDevice}
    Write Attribute  ${HOST_SETTINGS}  boot_flags   data=${valueDict}
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Network
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Network

Set The Boot Device As Network Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Network using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Device_As_Network_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x04 0x00 0x00 0x00
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Network
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Network

Set The Boot Device As Disk Using REST API
    [Documentation]  This testcase is to set the boot device as Disk using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Device_As_Disk_Using_REST_API

    ${bootDevice}=  Set Variable   Disk
    ${valueDict}=  create dictionary  data=${bootDevice}
    Write Attribute  ${HOST_SETTINGS}  boot_flags   data=${valueDict}
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Disk
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Disk

Set The Boot Device As Disk Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Disk using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Device_As_Disk_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x08 0x00 0x00 0x00
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Disk
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Disk

Set The Boot Device As Safe Using REST API
    [Documentation]  This testcase is to set the boot device as Safe using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Device_As_Safe_Using_REST_API

    ${bootDevice}=  Set Variable  Safe
    ${valueDict}=  create dictionary  data=${bootDevice}
    Write Attribute  ${HOST_SETTINGS}  boot_flags  data=${valueDict}
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Safe
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Safe

Set The Boot Device As Safe Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Safe using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Device_As_Safe_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x0C 0x00 0x00 0x00
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Safe
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Safe

Set The Boot Device As CDROM Using REST API
    [Documentation]  This testcase is to set the boot device as CDROM using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Device_As_CDROM_Using_REST_API

    ${bootDevice}=  Set Variable  CDROM
    ${valueDict}=  create dictionary  data=${bootDevice}
    Write Attribute  ${HOST_SETTINGS}  boot_flags   data=${valueDict}
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  CDROM
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  CDROM

Set The Boot Device As CDROM Using Ipmitool
    [Documentation]  This testcase is to set the boot device as CDROM using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
   [Tags]  Set_The_Boot_Device_As_CDROM_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x14 0x00 0x00 0x00
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  CDROM
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  CDROM

Set The Boot Device As Setup Using REST API
    [Documentation]  This testcase is to set the boot device as Setup using REST
    ...              URI. The Boot device is read using REST API and ipmitool.
    [Tags]  Set_The_Boot_Device_As_Setup_Using_REST_API

    ${bootDevice}=  Set Variable  Setup
    ${valueDict}=  create dictionary  data=${bootDevice}
    Write Attribute  ${HOST_SETTINGS}  boot_flags  data=${valueDict}
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Setup
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Setup

Set The Boot Device As Setup Using Ipmitool
    [Documentation]  This testcase is to set the boot device as Setup using
    ...              ipmitool. The Boot device is read using REST API and
    ...              ipmitool.
    [Tags]  Set_The_Boot_Device_As_Setup_Using_Ipmitool

    Run IPMI command  0x0 0x8 0x05 0x80 0x18 0x00 0x00 0x00
    Read the Attribute  ${HOST_SETTINGS}  boot_flags
    Response Should Be Equal  Setup
    ${output}  ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${output}  Setup

*** Keywords ***

Response Should Be Equal
    [Arguments]  ${args}
    Should Be Equal  ${OUTPUT}  ${args}

Read the Attribute
    [Arguments]  ${uri}  ${parm}
    ${output}=  Read Attribute  ${uri}  ${parm}
    set test variable  ${OUTPUT}  ${output}
