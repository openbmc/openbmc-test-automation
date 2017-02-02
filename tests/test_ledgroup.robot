*** Settings ***

Documentation  Test LED groups in OpenBMC.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot

Suite Setup    Setup The Suite
Test Teardown  FFDC On Test Case Fail

Force Tags  LED_Group

*** Variables ***


*** Test Cases ***

Verify CPU Fault LEDs Group
    [Documentation]  Validate all CPU's fault LEDs.
    [Tags]  Verify_CPU_Fault_LEDs_Group

    Verify LED Group  cpu

Verify Fan Fault LEDs Group
    [Documentation]  Validate all fan's fault LEDs.
    [Tags]  Verify_Fan_Fault_LEDs_Group

    Verify LED Group  Fan  Fault

Verify DIMM Fault LEDs Group
    [Documentation]  Validate all DIMM's fault LEDs.
    [Tags]  Verify_DIMM_Fault_LEDs_Group

    Verify LED Group  dimm  Fault

Verify GPU Fault LEDs Group
    [Documentation]  Validate all GPU's fault LEDs.
    [Tags]  Verify_GPU_Fault_LEDs_Group

    Verify LED Group  gpu  Fault

Verify PCI Card Fault LEDs Group
    [Documentation]  Validate all PCI cards's fault LEDs.
    [Tags]  Verify_PCI_Card_Fault_LEDs_Group

    Verify LED Group  pciecard  Fault

Verify Power Supply Fault LEDs Group
    [Documentation]  Validate all power supply's fault LEDs.
    [Tags]  Verify_Power_Supply_Fault_LEDs_Group

    Verify LED Group  powersupply  Fault

Verify Enclosure Fault LED Group
    [Documentation]  Validate enclosure's fault LED.
    [Tags]  Verify_Enclosure_Fault_LED_Group

    Verify LED Group  Enclosure  Fault

Verify Power State LEDs Group
    [Documentation]  Validate all power state LEDs.
    [Tags]  Verify_Power_State_LEDs_Group

    Verify LED Group  Power

Verify Enclosure Identify LED Group
    [Documentation]  Validate enclosure's identify LED.
    [Tags]  Verify_Enclosure_Identify_LED_Group

    Verify LED Group  Enclosure  Identify

Verify Fan Identify LEDs Group
    [Documentation]  Validate all fan's identify LEDs.
    [Tags]  Verify_Fan_Identify_LEDs_Group

    Verify LED Group  Fan  Identify

Verify Other Fault LEDs Group
    [Documentation]  Validate all other fault LEDs.
    [Tags]  Verify_Other_Fault_LEDs_Group

    Verify LED Group  teakFault
    Verify LED Group  systemFault
    Verify LED Group  boxelderFault
    Verify LED Group  bmcFault
    Verify LED Group  motherboardFault
    Verify LED Group  chassisFault

*** Keywords ***

Get LED State XYZ
    [Documentation]  Returns state of given LED.
    [Arguments]  ${led_name}
    # Description of arguments:
    # led_name  Name of LED

    ${state}=  Read Attribute  ${LED_GROUPS_URI}${led_name}  Asserted
    [Return]  ${state}

Set LED State
    [Documentation]  Set state of given LED to on or off.
    [Arguments]  ${state}  ${led_name}
    # Description of arguments:
    # state     LED's state to set, i.e. On or Off
    # led_name  Name of LED

    ${data}=  Run Keyword If
    ...  '${state}' == 'On'  Create Dictionary  data=${True}
    ...  ELSE IF  '${state}' == 'Off'  Create Dictionary  data=${False}
    ...  ELSE  Fail  msg=Invalid LED state

    ${resp}=  OpenBMC Put Request
    ...  ${LED_GROUPS_URI}${led_name}/attr/Asserted  data=${data}
    ${jsondata}=  to JSON  ${resp.content}
    Should Be Equal As Strings  ${jsondata['status']}  ${HTTP_OK}


Verify LED Group
    [Documentation]  Set and validate state of all LEDs with given name.
    [Arguments]  ${led_prefix}  ${led_suffix}=${EMPTY}
    # Description of arguments:
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

    ${resp}=  Read Properties  ${LED_GROUPS_URI}
    Set Suite Variable  ${LED_GROUPS}  ${resp}

Get LED List
    [Documentation]  Returns all LEDs with given name.
    [Arguments]  ${led_prefix}  ${led_suffix}=${EMPTY}
    # Description of arguments:
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
