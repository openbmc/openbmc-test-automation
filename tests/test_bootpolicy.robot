*** Settings ***

Documentation   This testsuite is for testing boot policy function.

Resource           ../lib/rest_client.robot
Resource           ../lib/ipmi_client.robot
Resource           ../lib/utils.robot

Suite Setup        Open Connection And Log In
Suite Teardown     Close All Connections

*** Variables ***
${dbuscmdBase} =    dbus-send --system --print-reply --dest=org.openbmc.settings.Host
${dbuscmdGet} =   /org/openbmc/settings/host0  org.freedesktop.DBus.Properties.Get
${dbuscmdString} =   string:"org.openbmc.settings.Host" string:"boot_policy"

*** Test Cases ***

Set Onetime boot policy using REST
    [Documentation]   This testcase is to set onetime boot policy using REST
    ...               URI and then verify using REST API and ipmitool.\n

    Set Boot Policy   ONETIME

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    ONETIME
    ${dbuscmd} =     Catenate  ${dbuscmdBase} ${dbuscmdGet} ${dbuscmdString}
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Log to Console   \n ${output}
    Should Contain   ${output}   ONETIME


Set Permanent boot policy using REST
    [Documentation]   This testcase is to set permanent boot policy using REST
    ...               URI and then verify using REST API and ipmitool.\n

    Set Boot Policy   PERMANENT

    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    PERMANENT
    ${dbuscmd} =     Catenate  ${dbuscmdBase} ${dbuscmdGet} ${dbuscmdString}
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Log to Console   \n ${output}
    Should Contain   ${output}   PERMANENT

Set Onetime boot policy using IPMITOOL
    [Documentation]   This testcase is to set boot policy to onetime boot using ipmitool
    ...               and then verify using REST URI and ipmitool.\n

    Run IPMI command   0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00
    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    ONETIME
    ${dbuscmd} =     Catenate  ${dbuscmdBase} ${dbuscmdGet} ${dbuscmdString}
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Log to Console   \n ${output}
    Should Contain   ${output}   ONETIME

Set Permanent boot policy using IPMITOOL
    [Documentation]   This testcase is to set boot policy to permanent using ipmitool
    ...               and then verify using REST URI and ipmitool.

    Run IPMI command   0x0 0x8 0x05 0xC0 0x00 0x00 0x00 0x00
    ${boot} =   Read Attribute  /org/openbmc/settings/host0    boot_policy
    Should Be Equal    ${boot}    PERMANENT
    ${dbuscmd} =     Catenate  ${dbuscmdBase} ${dbuscmdGet} ${dbuscmdString}
    ${output}   ${stderr}=  Execute Command  ${dbuscmd}  return_stderr=True
    Should Be Empty     ${stderr}
    Log to Console   \n ${output}
    Should Contain   ${output}   PERMANENT

Boot order with permanent boot policy
    [Documentation]   This testcase is to verify that boot order does not change
    ...               after first boot when boot policy set to permanent

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
    Should Not Be Equal    ${boot}    abc

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
