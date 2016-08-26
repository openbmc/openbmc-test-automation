*** Settings ***

Documentation   This testsuite is for testing the Boot Device Functions

Resource          ../lib/rest_client.robot
Resource          ../lib/ipmi_client.robot
Resource          ../lib/openbmc_ffdc.robot

Suite Setup       Open Connection And Log In
Suite Teardown    Close All Connections
Test Teardown     Log FFDC

*** Test Cases ***

Set the Boot Device as Default using REST API
   [Documentation]   This testcase is to set the boot device as Default using REST
   ...               URI. The Boot device is read using REST API and ipmitool.
   
    ${bootDevice} =   Set Variable   Default
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
    Read the Attribute  /org/openbmc/settings/host0    boot_flags
    Response Should Be Equal   Default
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   No override
    
Set the Boot Device as Default using ipmitool
   [Documentation]   This testcase is to set the boot device as Default using
   ...               ipmitool. The Boot device is read using REST API and
   ...               ipmitool.
   
    Run IPMI command   0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00
    Read the Attribute   /org/openbmc/settings/host0   boot_flags
    Response Should Be Equal   Default
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   No override
    
Set the Boot Device as Network using REST API
   [Documentation]   This testcase is to set the boot device as Network using REST
   ...               URI. The Boot device is read using REST API and ipmitool.
   
    ${bootDevice} =   Set Variable   Network
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
    Read the Attribute  /org/openbmc/settings/host0    boot_flags
    Response Should Be Equal   Network
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force PXE
    
Set the Boot Device as Network using ipmitool
   [Documentation]   This testcase is to set the boot device as Network using
   ...               ipmitool. The Boot device is read using REST API and
   ...               ipmitool.
   
    Run IPMI command   0x0 0x8 0x05 0x80 0x04 0x00 0x00 0x00
    Read the Attribute   /org/openbmc/settings/host0   boot_flags
    Response Should Be Equal   Network
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force PXE
    
Set the Boot Device as Disk using REST API
   [Documentation]   This testcase is to set the boot device as Disk using REST
   ...               URI. The Boot device is read using REST API and ipmitool.
   
    ${bootDevice} =   Set Variable   Disk
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
    Read the Attribute  /org/openbmc/settings/host0    boot_flags
    Response Should Be Equal   Disk
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot from default Hard-Drive
    
Set the Boot Device as Disk using ipmitool
   [Documentation]   This testcase is to set the boot device as Disk using
   ...               ipmitool. The Boot device is read using REST API and
   ...               ipmitool.
   
    Run IPMI command   0x0 0x8 0x05 0x80 0x08 0x00 0x00 0x00
    Read the Attribute   /org/openbmc/settings/host0   boot_flags
    Response Should Be Equal   Disk
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot from default Hard-Drive
    
Set the Boot Device as Safe using REST API
   [Documentation]   This testcase is to set the boot device as Safe using REST
   ...               URI. The Boot device is read using REST API and ipmitool.
   
    ${bootDevice} =   Set Variable   Safe
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
    Read the Attribute  /org/openbmc/settings/host0    boot_flags
    Response Should Be Equal   Safe
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot from default Hard-Drive, request Safe-Mode
    
Set the Boot Device as Safe using ipmitool
   [Documentation]   This testcase is to set the boot device as Safe using
   ...               ipmitool. The Boot device is read using REST API and
   ...               ipmitool.
   
    Run IPMI command   0x0 0x8 0x05 0x80 0x0C 0x00 0x00 0x00
    Read the Attribute   /org/openbmc/settings/host0   boot_flags
    Response Should Be Equal   Safe
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot from default Hard-Drive, request Safe-Mode

Set the Boot Device as CDROM using REST API
   [Documentation]   This testcase is to set the boot device as CDROM using REST
   ...               URI. The Boot device is read using REST API and ipmitool.
   
    ${bootDevice} =   Set Variable   CDROM
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
    Read the Attribute  /org/openbmc/settings/host0    boot_flags
    Response Should Be Equal   CDROM
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot from CD/DVD
    
Set the Boot Device as CDROM using ipmitool
   [Documentation]   This testcase is to set the boot device as CDROM using
   ...               ipmitool. The Boot device is read using REST API and
   ...               ipmitool.
   
    Run IPMI command   0x0 0x8 0x05 0x80 0x14 0x00 0x00 0x00
    Read the Attribute   /org/openbmc/settings/host0   boot_flags
    Response Should Be Equal   CDROM
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot from CD/DVD
    
Set the Boot Device as Setup using REST API
   [Documentation]   This testcase is to set the boot device as Setup using REST
   ...               URI. The Boot device is read using REST API and ipmitool.
   
    ${bootDevice} =   Set Variable   Setup
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
    Read the Attribute  /org/openbmc/settings/host0    boot_flags
    Response Should Be Equal   Setup
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot into BIOS Setup
    
Set the Boot Device as Setup using ipmitool
   [Documentation]   This testcase is to set the boot device as Setup using
   ...               ipmitool. The Boot device is read using REST API and
   ...               ipmitool.
   
    Run IPMI command   0x0 0x8 0x05 0x80 0x18 0x00 0x00 0x00
    Read the Attribute   /org/openbmc/settings/host0   boot_flags
    Response Should Be Equal   Setup
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Force Boot into BIOS Setup

*** Keywords ***

Response Should Be Equal
    [arguments]    ${args}
    Should Be Equal    ${OUTPUT}    ${args}

Read the Attribute     
    [arguments]    ${uri}    ${parm}
    ${output} =     Read Attribute      ${uri}    ${parm}
    set test variable    ${OUTPUT}     ${output}

