*** Settings ***

Documentation  This testsuite is for testing LED groups in OpenBMC.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot

Suite Setup    Setup The Suite
Test Teardown  FFDC On Test Case Fail

Force Tags  led_group_test

*** Variables ***


*** Test Cases ***

Test All CPU Fault LEDs
    [Documentation]  Validate all CPU's fault LEDs.
    [Tags]  Test_All_CPU_Fault_LEDs

    Validate LED Group  cpu

Test All Fan Fault LEDs
    [Documentation]  Validate all fan's fault LEDs.
    [Tags]  Test_All_FAN_Fault_LEDs

    Validate LED Group  Fan  Fault

Test All DIMM Fault LEDs
    [Documentation]  Validate all DIMM's fault LEDs.
    [Tags]  Test_All_DIMM_Fault_LEDs

    Validate LED Group  dimm  Fault

Test All GPU Fault LEDs
    [Documentation]  Validate all GPU's fault LEDs.
    [Tags]  Test_All_GPU_Fault_LEDs

    Validate LED Group  gpu  Fault

Test All PCI Card Fault LEDs
    [Documentation]  Validate all PCI cards's fault LEDs.
    [Tags]  Test_All_PCI_Card_Fault_LEDs

    Validate LED Group  pciecard  Fault

Test All Power Supply Fault LEDs
    [Documentation]  Validate all power supply's fault LEDs.
    [Tags]  Test_All_Power_Supply_Fault_LEDs

    Validate LED Group  powersupply  Fault

Test Enclosure Fault LED
    [Documentation]  Validate enclosure's fault LED.
    [Tags]  Test_Enclosure_Fault_LED

    Validate LED Group  Enclosure  Fault

Test Power State LEDs
    [Documentation]  Validate all power state LEDs.
    [Tags]  Test_Power_State_LED

    Validate LED Group  Power

Test Enclosure Identify LED
    [Documentation]  Validate enclosure's identify LED.
    [Tags]  Test_Enclosure_Identify_LED

    Validate LED Group  Enclosure  Identify

Test All Fan Identify LEDs
    [Documentation]  Validate all fan's identify LEDs.
    [Tags]  Test_All_Fan_Identify_LEDs

    Validate LED Group  Fan  Identify

Test All Other Fault LEDs
    [Documentation]  Validate all other fault LEDs.
    [Tags]  Test_All_Other_Fault_LEDs

    Validate LED Group  teakFault
    Validate LED Group  systemFault
    Validate LED Group  boxelderFault
    Validate LED Group  bmcFault
    Validate LED Group  motherboardFault
    Validate LED Group  chassisFault

*** Keywords ***

Get LED State XYZ
    [Documentation]  Returns state of given LED.
    [Arguments]  ${led_name}
    # led_name  Name of LED

    ${state}=  Read Attribute  ${LED_GROUPS_URI}${led_name}  Asserted
    [Return]  ${state}

Set LED State
    [Documentation]  Set state of given LED to on or off.
    [Arguments]  ${state}  ${led_name}
    # state     LED's state to set, i.e. On or Off
    # led_name  Name of LED

    ${data}=  Run Keyword If
    ...  '${state}' == 'On'  Create Dictionary  data=${True}
    ...  ELSE IF  '${state}' == 'Off'  Create Dictionary  data=${False}
    ...  ELSE  Fail  msg=Invalid LED state

    ${resp}=  OpenBMC Put Request
    ...  ${LED_GROUPS_URI}${led_name}/attr/Asserted  data=${data}
    ${jsondata}=  to JSON  ${resp.content}
    [Return]  ${jsondata['status']}

Validate LED Group
    [Documentation]  Set and validate state of all LEDs with given name.
    [Arguments]  ${led_prefix}  ${led_suffix}=${EMPTY}
    # led_prefix  LED name's prefix
    # led_suffix  LED name's suffix

    ${led_list}=  Get LED List  ${led_prefix}  ${led_suffix}

    :FOR  ${led}  IN  @{led_list}
    \  Set LED State  On  ${led}
    \  ${resp}=  Get LED State XYZ  ${led}
    \  Should Be Equal  ${resp}  ${1}
    \  Set LED State  Off  ${led}
    \  ${resp}=  Get LED State XYZ  ${led}
    \  Should Be Equal  ${resp}  ${0}

Setup The Suite
    [Documentation]  Test setup before running this suite.

    Open Connection And Log In
    ${resp}=  Read Properties  ${LED_GROUPS_URI}
    Set Suite Variable  ${LED_GROUPS}  ${resp}

Get LED List
    [Documentation]  Returns all LEDs with given name.
    [Arguments]  ${led_prefix}  ${led_suffix}=${EMPTY}
    # led_prefix  LED name's prefix
    # led_suffix  LED name's suffix

    ${list}=  Get Matches
    ...  ${LED_GROUPS}  regexp=^.*[0-9a-z_].${led_prefix}.*${led_suffix}
    ${led_list}=  Create List

    : FOR  ${element}  IN  @{list}
    \  ${element}=  Remove String  ${element}  ${LED_GROUPS_URI}
    \  Append To List  ${led_list}  ${element}
    Sort List  ${led_list}

    [Return]  ${led_list}
