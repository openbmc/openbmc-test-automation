*** Settings ***

Documentation     This testsuite is for testing the functions of Heartbeat,
...               Identify and Power LED's

Resource          ../lib/rest_client.robot
Resource          ../lib/resource.txt
Resource          ../lib/openbmc_ffdc.robot
Test Teardown     FFDC On Test Case Fail

*** Variables ***

${MIN_TOGGLE_VALUE}    0
${SAMPLING_FREQUENCY}  6

*** Test Cases ***

Validate Heartbeat LEDs Test Cases
    [Documentation]   If heartbeat LED exist then execute the test set.
    [Tags]  Validate_Heartbeat_LEDs_Test_Cases
    ${resp}=   OpenBMC Get Request   /org/openbmc/control/led/heartbeat
    Run keyword If  ${resp.status_code} == ${HTTP_OK}   Execute Heartbeat LEDs Test Cases

Validate Identify LEDs Test Cases
    [Documentation]   If identify LED exist then execute the test set.
    [Tags]  Validate_Identify_LEDs_Test_Cases
    ${resp}=   OpenBMC Get Request   /org/openbmc/control/led/identify
    Run keyword If  ${resp.status_code} == ${HTTP_OK}   Execute Identify LEDs Test Cases

Validate Beep LEDs Test Cases
    [Documentation]   If beep LED exist then execute the test set.
    [Tags]  Validate_Beep_LEDs_Test_Cases
    ${resp}=   OpenBMC Get Request   /org/openbmc/control/led/beep
    Run keyword If  ${resp.status_code} == ${HTTP_OK}  Execute Beep LEDs Test Cases

*** Keywords ***

Execute Heartbeat LEDs Test Cases
    [Documentation]   Executing ON/OFF/Fast/Slow Heartbeat LED test cases.
    Turn ON the Heartbeat LED
    Turn OFF the Heartbeat LED
    Blink Fast the Heartbeat LED
    Blink Slow the Heartbeat LED

Execute Identify LEDs Test Cases
    [Documentation]   Executing ON/OFF/Fast/Slow Identify LED test cases.
    Turn ON the Identify LED
    Turn OFF the Identify LED
    Blink Fast the Identify LED
    Blink Slow the Identify LED

Execute Beep LEDs Test Cases
    [Documentation]   Executing ON/OFF/Fast/Slow Beep LED test cases.
    Turn ON the Beep LED
    Turn OFF the Beep LED
    Blink Fast the Beep LED
    Blink Slow the Beep LED

Turn ON the Heartbeat LED
   [Documentation]   This testcase is to test the setOn functionality of the
   ...               Heartbeat LED. The LED state is read again to check if
   ...               the LED is in ON state.
   Set On   heartbeat
   ${ledstate}=   Get LED State   heartbeat
   should be equal as strings   ${ledstate}   On

Turn OFF the Heartbeat LED
   [Documentation]   This testcase is to test the setOff functionality of the
   ...               Heartbeat LED. The LED state is read again to check if
   ...               the LED is in OFF state.
   Set Off   heartbeat
   ${ledstate}=   Get LED State   heartbeat
   should be equal as strings   ${ledstate}   Off

Blink Fast the Heartbeat LED
   [Documentation]   This testcase is to test the setBlinkFast functionality of the
   ...               Heartbeat LED. The LED state is sampled to figure out
   ...               whether the LED is blinking. There is no distinguishing
   ...               between whether the LED is blinking fast or slow for
   ...               this testcase to pass.
   ${OFF_VALUE}=   Set Variable   ${0}
   ${ON_VALUE}=   Set Variable   ${0}
   Set Blink Fast   heartbeat
   : FOR   ${INDEX}   IN RANGE   1   ${SAMPLING_FREQUENCY}
   \   ${ledstate}=   Get LED State   heartbeat
   \   ${ON_VALUE}=   Set Variable If   '${ledstate}'=='On'   ${ON_VALUE + 1}   ${ON_VALUE}
   \   ${OFF_VALUE}=   Set Variable If   '${ledstate}'=='Off'   ${OFF_VALUE + 1}   ${OFF_VALUE}
   should be true   ${ON_VALUE} > ${MIN_TOGGLE_VALUE} and ${OFF_VALUE} > ${MIN_TOGGLE_VALUE}

Blink Slow the Heartbeat LED
   [Documentation]   This testcase is to test the setBlinkSlow functionality of the
   ...               Heartbeat LED. The LED state is sampled to figure out
   ...               whether the LED is blinking. There is no distinguishing
   ...               between whether the LED is blinking fast or slow for
   ...               this testcase to pass.
   ${OFF_VALUE}=   Set Variable   ${0}
   ${ON_VALUE}=   Set Variable   ${0}
   Set Blink Slow   heartbeat
   : FOR   ${INDEX}   IN RANGE   1   ${SAMPLING_FREQUENCY}
   \   ${ledstate}=   Get LED State   heartbeat
   \   ${ON_VALUE}=   Set Variable If   '${ledstate}'=='On'   ${ON_VALUE + 1}   ${ON_VALUE}
   \   ${OFF_VALUE}=   Set Variable If   '${ledstate}'=='Off'   ${OFF_VALUE + 1}   ${OFF_VALUE}
   should be true   ${ON_VALUE} > ${MIN_TOGGLE_VALUE} and ${OFF_VALUE} > ${MIN_TOGGLE_VALUE}

Turn ON the Identify LED
   [Documentation]   This testcase is to test the setOn functionality of the
   ...               Identify LED. The LED state is read again to check if
   ...               the LED is in ON state.
   Set On   identify
   ${ledstate}=   Get LED State   identify
   should be equal as strings   ${ledstate}   On

Turn OFF the Identify LED
   [Documentation]   This testcase is to test the setOff functionality of the
   ...               Identify LED. The LED state is read again to check if
   ...               the LED is in OFF state.
   Set Off   identify
   ${ledstate}=   Get LED State   identify
   should be equal as strings   ${ledstate}   Off

Blink Fast the Identify LED
   [Documentation]   This testcase is to test the setBlinkFast functionality of the
   ...               Identify LED. The LED state is sampled to figure out
   ...               whether the LED is blinking. There is no distinguishing
   ...               between whether the LED is blinking fast or slow for
   ...               this testcase to pass.
   ${OFF_VALUE}=   Set Variable   ${0}
   ${ON_VALUE}=   Set Variable   ${0}
   Set Blink Fast   identify
   : FOR   ${INDEX}   IN RANGE   1   ${SAMPLING_FREQUENCY}
   \   ${ledstate}=   Get LED State   identify
   \   ${ON_VALUE}=   Set Variable If   '${ledstate}'=='On'   ${ON_VALUE + 1}   ${ON_VALUE}
   \   ${OFF_VALUE}=   Set Variable If   '${ledstate}'=='Off'   ${OFF_VALUE + 1}   ${OFF_VALUE}
   should be true   ${ON_VALUE} > ${MIN_TOGGLE_VALUE} and ${OFF_VALUE} > ${MIN_TOGGLE_VALUE}

Blink Slow the Identify LED
   [Documentation]   This testcase is to test the setBlinkSlow functionality of the
   ...               Identify LED. The LED state is sampled to figure out
   ...               whether the LED is blinking. There is no distinguishing
   ...               between whether the LED is blinking fast or slow for
   ...               this testcase to pass.
   ${OFF_VALUE}=   Set Variable   ${0}
   ${ON_VALUE}=   Set Variable   ${0}
   Set Blink Slow   identify
   : FOR   ${INDEX}   IN RANGE   1   ${SAMPLING_FREQUENCY}
   \   ${ledstate}=   Get LED State   identify
   \   ${ON_VALUE}=   Set Variable If   '${ledstate}'=='On'   ${ON_VALUE + 1}   ${ON_VALUE}
   \   ${OFF_VALUE}=   Set Variable If   '${ledstate}'=='Off'   ${OFF_VALUE + 1}   ${OFF_VALUE}
   should be true   ${ON_VALUE} > ${MIN_TOGGLE_VALUE} and ${OFF_VALUE} > ${MIN_TOGGLE_VALUE}

Turn ON the Beep LED
   [Documentation]   This testcase is to test the setOn functionality of the
   ...               Beep LED. The LED state is read again to check if
   ...               the LED is in ON state.
   Set On   beep
   ${ledstate}=   Get LED State   beep
   should be equal as strings   ${ledstate}   On

Turn OFF the Beep LED
   [Documentation]   This testcase is to test the setOff functionality of the
   ...               Beep LED. The LED state is read again to check if
   ...               the LED is in OFF state.
   Set Off   beep
   ${ledstate}=   Get LED State   beep
   should be equal as strings   ${ledstate}   Off

Blink Fast the Beep LED
   [Documentation]   This testcase is to test the setBlinkFast functionality of the
   ...               Beep LED. The LED state is sampled to figure out
   ...               whether the LED is blinking. There is no distinguishing
   ...               between whether the LED is blinking fast or slow for
   ...               this testcase to pass.
   ${OFF_VALUE}=   Set Variable   ${0}
   ${ON_VALUE}=   Set Variable   ${0}
   ${data}=   create dictionary   data=@{EMPTY}
   Set Blink Fast   beep
   : FOR   ${INDEX}   IN RANGE   1   ${SAMPLING_FREQUENCY}
   \   ${ledstate}=   Get LED State   beep
   \   ${ON_VALUE}=   Set Variable If   '${ledstate}'=='On'   ${ON_VALUE + 1}   ${ON_VALUE}
   \   ${OFF_VALUE}=   Set Variable If   '${ledstate}'=='Off'   ${OFF_VALUE + 1}   ${OFF_VALUE}
   should be true   ${ON_VALUE} > ${MIN_TOGGLE_VALUE} and ${OFF_VALUE} > ${MIN_TOGGLE_VALUE}

Blink Slow the Beep LED
   [Documentation]   This testcase is to test the setBlinkSlow functionality of the
   ...               Beep LED. The LED state is sampled to figure out
   ...               whether the LED is blinking. There is no distinguishing
   ...               between whether the LED is blinking fast or slow for
   ...               this testcase to pass.
   ${OFF_VALUE}=   Set Variable   ${0}
   ${ON_VALUE}=   Set Variable   ${0}
   Set Blink Slow   beep
   : FOR   ${INDEX}   IN RANGE   1   ${SAMPLING_FREQUENCY}
   \   ${ledstate}=   Get LED State   beep
   \   ${ON_VALUE}=   Set Variable If   '${ledstate}'=='On'   ${ON_VALUE + 1}   ${ON_VALUE}
   \   ${OFF_VALUE}=   Set Variable If   '${ledstate}'=='Off'   ${OFF_VALUE + 1}   ${OFF_VALUE}
   should be true   ${ON_VALUE} > ${MIN_TOGGLE_VALUE} and ${OFF_VALUE} > ${MIN_TOGGLE_VALUE}

Get LED State
   [arguments]    ${args}
   ${data}=   create dictionary   data=@{EMPTY}
   ${resp}=   OpenBMC Post Request   /org/openbmc/control/led/${args}/action/GetLedState   data=${data}
   should be equal as strings   ${resp.status_code}   ${HTTP_OK}
   ${json}=   to json   ${resp.content}
   [return]    ${json['data'][1]}

Set On
   [arguments]    ${args}
   ${data}=   create dictionary   data=@{EMPTY}
   ${resp}=   OpenBMC Post Request   /org/openbmc/control/led/${args}/action/setOn   data=${data}
   should be equal as strings   ${resp.status_code}   ${HTTP_OK}
   ${json}=   to json   ${resp.content}
   should be equal as integers   ${json['data']}   0

Set Off
   [arguments]    ${args}
   ${data}=   create dictionary   data=@{EMPTY}
   ${resp}=   OpenBMC Post Request   /org/openbmc/control/led/${args}/action/setOff   data=${data}
   should be equal as strings   ${resp.status_code}   ${HTTP_OK}
   ${json}=   to json   ${resp.content}
   should be equal as integers   ${json['data']}   0

Set Blink Fast
   [arguments]    ${args}
   ${data}=   create dictionary   data=@{EMPTY}
   ${resp}=   OpenBMC Post Request   /org/openbmc/control/led/${args}/action/setBlinkFast   data=${data}
   should be equal as strings   ${resp.status_code}   ${HTTP_OK}
   ${json}=   to json   ${resp.content}
   should be equal as integers   ${json['data']}   0

Set Blink Slow
   [arguments]    ${args}
   ${data}=   create dictionary   data=@{EMPTY}
   ${resp}=   OpenBMC Post Request   /org/openbmc/control/led/${args}/action/setBlinkSlow   data=${data}
   should be equal as strings   ${resp.status_code}   ${HTTP_OK}
   ${json}=   to json   ${resp.content}
   should be equal as integers   ${json['data']}   0
