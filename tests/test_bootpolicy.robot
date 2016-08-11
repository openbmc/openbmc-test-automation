*** Settings ***

Documentation   This testsuite is for testing boot policy function.

Resource           ../lib/rest_client.robot
Resource           ../lib/ipmi_client.robot
Resource           ../lib/utils.robot

Suite Setup        Open Connection And Log In
Suite Teardown     Close All Connections

*** Variables ***

*** Test Cases ***

Set Onetime boot policy using REST
    [Documentation]   This testcase is to set onetime boot policy using REST
    ...               URI and then verify using REST API and ipmitool.\n
 
    Set Boot Policy   ONETIME

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    ONETIME
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Options apply to only next boot

Set Permanent boot policy using REST
    [Documentation]   This testcase is to set permanent boot policy using REST
    ...               URI and then verify using REST API and ipmitool.\n

    Set Boot Policy   PERMANENT

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    PERMANENT
    ${output} =    Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Options apply to all future boots

Set Onetime boot policy using IPMITOOL
    [Documentation]   This testcase is to set boot policy to onetime boot using ipmitool
    ...               and then verify using REST URI and ipmitool.\n

    Run IPMI command   0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00
    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    ONETIME
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Options apply to only next boot
 
Set Permanent boot policy using IPMITOOL
    [Documentation]   This testcase is to set boot policy to permanent using ipmitool
    ...               and then verify using REST URI and ipmitool.

    Run IPMI command   0x0 0x8 0x05 0xC0 0x00 0x00 0x00 0x00
    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    PERMANENT
    ${output} =   Run IPMI Standard command   chassis bootparam get 5
    Should Contain   ${output}   Options apply to all future boots

Boot order with permanent boot policy
    [Documentation]   This testcase is to verify that boot order does not change
    ...               after first boot when boot policy set to permanent

    [Tags]  chassisboot

    Power Off Host

    Set Boot Policy   PERMANENT

    Set Boot Device   CDROM

    Power On Host

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    PERMANENT

    ${flag} =   Read Attribute  /org/openbmc/settings/host0    boot_flags
    Should Be Equal    ${flag}    CDROM

Onetime boot order after warm reset
    [Documentation]   This testcase is to verify that boot policy and order does not change
    ...               after warm reset on a system with onetime boot policy.

    [Tags]  chassisboot

    Power On Host

    Set Boot Policy   ONETIME

    Set Boot Device   Network

    Trigger Warm Reset

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    ONETIME

    ${flag} =   Read Attribute  /org/openbmc/settings/host0    boot_flags
    Should Be Equal    ${flag}    Network

Permanent boot order after warm reset
    [Documentation]   This testcase is to verify that boot policy and order does not change  
    ...               after warm reset on a system with permanent boot policy.

    [Tags]  chassisboot

    Power On Host

    Set Boot Policy   PERMANENT

    Set Boot Device   CDROM

    Trigger Warm Reset

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    PERMANENT

    ${flag} =   Read Attribute  /org/openbmc/settings/host0    boot_flags
    Should Be Equal    ${flag}    CDROM
 
Set boot policy to invalid value
    [Documentation]   This testcase is to verify that proper error message is prompted  
    ...               when invalid value to provided to boot policy.
   
    Set Boot Policy   abc

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Not Equal    ${boot}    abc
    
*** Keywords ***

Set Boot Policy
    [Arguments]    ${args}
    ${bootpolicy} =   Set Variable   ${args}
    ${valueDict} =   create dictionary   data=${bootpolicy}
    Write Attribute    /org/openbmc/settings/host0   boot_policy   data=${valueDict}

Set Boot Device
    [Arguments]    ${args}
    ${bootDevice} =   Set Variable   ${args}
    ${valueDict} =   create dictionary   data=${bootDevice}
    Write Attribute    /org/openbmc/settings/host0   boot_flags   data=${valueDict}
