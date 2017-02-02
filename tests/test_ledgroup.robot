*** Settings ***

Documentation  This testsuite is for testing led function.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot
Test Teardown  FFDC On Test Case Fail

*** Variables ***


*** Test Cases ***

Test All CPU Fault LED
    Validate LED Group  cpu0Fault
    Validate LED Group  cpu1Fault

Test All Fan Fault LED
    Validate LED Group  Fan0Fault
    Validate LED Group  Fan1Fault
    Validate LED Group  Fan2Fault
    Validate LED Group  Fan3Fault

Test All DIMM Fault LED
    Validate LED Group  dimm0Fault
    Validate LED Group  dimm1Fault
    Validate LED Group  dimm2Fault
    Validate LED Group  dimm3Fault
    Validate LED Group  dimm4Fault
    Validate LED Group  dimm5Fault
    Validate LED Group  dimm6Fault
    Validate LED Group  dimm7Fault
    Validate LED Group  dimm8Fault
    Validate LED Group  dimm9Fault
    Validate LED Group  dimm10Fault
    Validate LED Group  dimm11Fault
    Validate LED Group  dimm12Fault
    Validate LED Group  dimm13Fault
    Validate LED Group  dimm14Fault
    Validate LED Group  dimm15Fault

Test All GPU Fault LED
    Validate LED Group  gpu0Fault
    Validate LED Group  gpu1Fault
    Validate LED Group  gpu2Fault
    Validate LED Group  gpu3Fault
    Validate LED Group  gpu4Fault
    Validate LED Group  gpu5Fault

Test All PCI Card Fault LED
    Validate LED Group  pciecard0Fault
    Validate LED Group  pciecard1Fault
    Validate LED Group  pciecard2Fault
    Validate LED Group  pciecard3Fault

Test All Power Supply Fault LED
    Validate LED Group  powersupply0Fault
    Validate LED Group  powersupply1Fault

Test All Other Fault LED
    Validate LED Group  teakFault
    Validate LED Group  systemFault
    Validate LED Group  boxelderFault
    Validate LED Group  bmcFault
    Validate LED Group  motherboardFault
    Validate LED Group  chassisFault

Test Power State LED
    Validate LED Group  PowerOff
    Validate LED Group  PowerOn

Test Enclosure Identify LED
    Validate LED Group  EnclosureIdentify

Test Enclosure Fault LED
    Validate LED Group  EnclosureFault

Test All Fan Identify LED
    Validate LED Group  Fan0Identify
    Validate LED Group  Fan1Identify
    Validate LED Group  Fan2Identify
    Validate LED Group  Fan3Identify

*** Keywords ***

Get LED Asserted State
    [Arguments]    ${led_name}
    ${state}=  Read Attribute  ${LED_GROUP_URI}/${led_name}  Asserted
    [Return]    ${state}

Set On LED Asserted State
    [Arguments]    ${led_name}
    ${state}=  Set Variable  true
    ${state}=  Convert To Boolean  ${state}
    ${valueDict}=  Create Dictionary  data=${state}

    ${resp}=  OpenBMC Put Request
    ...  ${LED_GROUP_URI}/${led_name}/attr/Asserted  data=${valueDict}

    ${jsondata}=  to JSON  ${resp.content}
    [Return]  ${jsondata['status']}

Set Off LED Asserted State
    [Arguments]    ${led_name}
    ${state}=  Set Variable  false
    ${state}=  Convert To Boolean  ${state}
    ${valueDict}=  Create Dictionary  data=${state}

    ${resp}=  OpenBMC Put Request
    ...  ${LED_GROUP_URI}/${led_name}/attr/Asserted  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}
    [Return]  ${jsondata['status']}

Validate LED Group
    [Documentation]  Test on and off of given LED group
    [Arguments]    ${led_name}

    Set On LED Asserted State  ${led_name}

    ${resp}=  Get LED Asserted State  ${led_name}
    Should Be Equal  ${resp}  ${1}

    Set Off LED Asserted State  ${led_name}

    ${resp}=  Get LED Asserted State  ${led_name}
    Should Be Equal  ${resp}  ${0}
