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
    [Documentation]  Verify CPU's fault LEDs.
    [Tags]  Verify_CPU_Fault_LEDs_Group

    Verify LED Group  cpu  fault

Verify Fan Fault LEDs Group
    [Documentation]  Verify fan's fault LEDs.
    [Tags]  Verify_Fan_Fault_LEDs_Group

    Verify LED Group  fan  fault

Verify DIMM Fault LEDs Group
    [Documentation]  Verify DIMM's fault LEDs.
    [Tags]  Verify_DIMM_Fault_LEDs_Group

    Verify LED Group  dimm  fault

Verify GPU Fault LEDs Group
    [Documentation]  Verify GPU's fault LEDs.
    [Tags]  Verify_GPU_Fault_LEDs_Group

    Verify LED Group  gv100card  fault

Verify Power Supply Fault LEDs Group
    [Documentation]  Verify power supply's fault LEDs.
    [Tags]  Verify_Power_Supply_Fault_LEDs_Group

    Verify LED Group  powersupply  fault

Verify Enclosure Fault LED Group
    [Documentation]  Validate enclosure's fault LED.
    [Tags]  Verify_Enclosure_Fault_LED_Group

    Verify LED Group  enclosure  fault

Verify Power State LEDs Group
    [Documentation]  Verify power state LEDs.
    [Tags]  Verify_Power_State_LEDs_Group

    Verify LED Group  power

Verify Enclosure Identify LED Group
    [Documentation]  Validate enclosure's identify LED.
    [Tags]  Verify_Enclosure_Identify_LED_Group

    Verify LED Group  enclosure  identify

Verify Fan Identify LEDs Group
    [Documentation]  Verify fan's identify LEDs.
    [Tags]  Verify_Fan_Identify_LEDs_Group

    Verify LED Group  fan  identify

Verify Other Fault LEDs Group
    [Documentation]  Verify other fault LEDs.
    [Tags]  Verify_Other_Fault_LEDs_Group

    Verify LED Group  system_fault
    Verify LED Group  boxelder_fault
    Verify LED Group  bmc_fault
    Verify LED Group  motherboard_fault

Verify Enclosure Fault LED On Assertion
    [Documentation]  Verify enclosure fault LED on assertion.
    [Tags]  Verify_Enclosure_Fault_LED_On_Assertion

    Set LED State  On  cpu0_fault
    ${resp}=  Get System LED State  rear_fault
    Should Be Equal  ${resp}  On


Verify Rear Power LED Association With Group LED
    [Documentation]  Verify rear power LED state association with
    ...  power on group LED.
    [Tags]  Verify_Rear_Power_LED_Association_With_Group_LED

    Set LED State  On  power_on
    ${resp}=  Get System LED State  rear_power
    Should Be Equal  ${resp}  On

    Set LED State  Off  power_on
    ${resp}=  Get System LED State  rear_power
    Should Be Equal  ${resp}  Blink


***Keywords***

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
    Should Be Equal As Strings  ${jsondata['status']}  ok

Verify LED Group
    [Documentation]  Set and validate state of all LEDs with given name.
    [Arguments]  ${led_prefix}  ${led_suffix}=${EMPTY}
    # Description of arguments:
    # led_prefix  LED name's prefix
    # led_suffix  LED name's suffix

    ${led_list}=  Get LED List  ${led_prefix}  ${led_suffix}

    ${list_length}=  Get Length  ${led_list}
    Should Be True  ${list_length} > 0
    ...  msg=No ${led_prefix} ${led_suffix} LED found

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
