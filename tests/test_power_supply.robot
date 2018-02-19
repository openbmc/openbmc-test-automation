*** Settings ***
Documentation  Test power supply telemetry.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/open_power_utils.robot
Resource            ../lib/boot_utils.robot

Test Teardown       FFDC On Test Case Fail

*** Variables ***

# -----------------------------------
# Output Current and Wattage Limits
# -----------------------------------
# * 200 VAC (200 - 208 VAC) ... 2104W
# * 230 VAC (207 - 253 VAC) ... 2226W
# * 277 VAC (249 - 305 VAC) ... 2226W
# -----------------------------------

# With loaded HTX work load the wattage is within half of the upper limit.
# If the system goes beyond 2K Watts, we will need to look into it.
${upper_power_limit}  ${2104}
${lower_power_limit}  ${0}

# Aggregation sample data o/p:
# ---------------------------------------------------------------------
# /org/open_power/sensors/aggregation/per_30s/ps0_input_power/average
# [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 225, 290, 255, 207, 124, 20]
# (max, min) (290, 20)

# /org/open_power/sensors/aggregation/per_30s/ps1_input_power/average
# [19, 19, 20, 20, 19, 20, 20, 20, 20, 20, 69, 321, 286, 265, 228, 104]
# (max, min) (321, 19)

# /org/open_power/sensors/aggregation/per_30s/ps0_input_power/maximum
# [20, 20, 20, 22, 22, 22, 22, 20, 22, 22, 338, 346, 308, 258, 172, 20]
# (max, min) (346, 20)

# /org/open_power/sensors/aggregation/per_30s/ps1_input_power/maximum
# [24, 26, 26, 26, 26, 26, 26, 26, 26, 26, 322, 364, 338, 308, 258, 240]
# (max, min) (364, 24)
# ---------------------------------------------------------------------

# To collect 3 iteration of sampling data.
${LOOP_COUNT}  ${3}


*** Test Cases ***

Power Supply Test When Host Off
    [Documentation]  Check for power watts is within limits allowed when host
    ...  is off.
    [Tags]  Power_Supply_Test_When_Host_Off

    REST Power Off  stack_mode=skip
    ${power_urls}=  Get Sensors Aggregation URL List  /org/open_power/sensors/

    Check Power Telemetry When Host Off  ${power_urls}


Power Supply Test When Host On
    [Documentation]  Check for power watts is within limits allowed when Host
    ...  is on.
    [Tags]  Power_Supply_Test_When_Host_On

    REST Power On
    ${power_urls}=  Get Sensors Aggregation URL List  /org/open_power/sensors/

    Repeat Keyword  ${LOOP_COUNT} times
    ...  Check Power Telemetry When Host On  ${power_urls}


*** Keywords ***

Check Power Telemetry When Host On
    [Documentation]  Verify if the power drawn is within the allowed wattage.
    [Arguments]  ${urls}

    # Description of argument(s):
    # urls  URL for list operation (e.g.
    #     /org/open_power/sensors/aggregation/per_30s/ps0_input_power/average).

    # Check for "average" aggregation.
    :FOR  ${index}  IN  @{urls[0]}
    \  ${average}=  Get Sensors Aggregation Data  ${index}
    \  ${max}  ${min}=  Evaluate  (max(@{average}), min(@{average}))
    \  Should Be True  ${max} < ${upper_power_limit}
    ...  msg=Wattage ${max} crossed ${upper_power_limit}.
    \  Should Be True  ${min} >= ${lower_power_limit}
    ...  msg=Wattage ${min} bellow ${lower_power_limit}.

    # Check for "maximum" aggregation.
    :FOR  ${index}  IN  @{urls[1]}
    \  ${maximum}=  Get Sensors Aggregation Data  ${index}
    \  ${max}  ${min}=  Evaluate  (max(@{maximum}), min(@{maximum}))
    \  Should Be True  ${max} < ${upper_power_limit}
    ...  msg=Wattage ${max} crossed ${upper_power_limit}.
    \  Should Be True  ${min} >= ${lower_power_limit}
    ...  msg=Wattage ${min} bellow ${lower_power_limit}.

    # Every 30 seconds the power wattage data is updated.
    Sleep  30s


Check Power Telemetry When Host Off
    [Documentation]  Verify if the power drawn is 0 wattage.
    [Arguments]  ${urls}

    # Description of argument(s):
    # urls  URL for list operation (e.g.
    #     /org/open_power/sensors/aggregation/per_30s/ps0_input_power/average).

    # Every 30 seconds the power wattage data is updated.
    Sleep  30s

    # Check for "average" aggregation.
    :FOR  ${index}  IN  @{urls[0]}
    \  ${average}=  Get Sensors Aggregation Data  ${index}
    \  Should Be True  ${average[0]} >= ${lower_power_limit}
    \  Should Be True  ${average[0]} < ${200}
    ...  msg=Wattage ${average[0]} crossed ${lower_power_limit}.

    # Check for "maximum" aggregation.
    :FOR  ${index}  IN  @{urls[1]}
    \  ${maximum}=  Get Sensors Aggregation Data  ${index}
    \  Should Be True  ${maximum[0]} >= ${lower_power_limit}
    \  Should Be True  ${maximum[0]} < ${200}
    ...  msg=Wattage ${maximum[0]} crossed 200.

