*** Settings ***
Documentation  Test power supply telemetry.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/open_power_utils.robot
Library             ../lib/utils.py

#Test Teardown       FFDC On Test Case Fail


*** Variables ***

# -----------------------------------
# Output Current and Wattage Limits
# -----------------------------------
# * 200 VAC (200 - 208 VAC) ... 2104W
# * 230 VAC (207 - 253 VAC) ... 2226W
# * 277 VAC (249 - 305 VAC) ... 2226W
# -----------------------------------

# With loaded HTX work load the wattage is within half of the upper limit.
# If the system goes beyond 1K Watts, we will need to look into it.
${upper_power_limit}  ${1052}
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

Power Supply Test
    [Documentation]  Check for Power watts is within limits allowed.
    [Tags]  Power_Supply_Test

    ${power_urls}=  Get Sensors Aggregation URL List  /org/open_power/sensors/

    Repeat Keyword  ${LOOP_COUNT} times  Check Power Telemetry  ${power_urls}

*** Keywords ***

Check Power Telemetry
    [Documentation]  Verify if the power drawn is within the allowed wattage.
    [Arguments]  ${urls}

    # Description of argument(s):
    # urls  URL for list operation (e.g.
    #     /org/open_power/sensors/aggregation/per_30s/ps0_input_power/average).

    # Check for "average" aggregation.
    :FOR  ${index}  IN  @{urls[0]}
    \  ${average}=  Get Sensors Aggregation Data  ${index}
    \  ${average_max_min}=  Min Max List  ${average}
    \  Log  (max, min): ${average_max_min}
    \  Should Be True  ${average_max_min[0]} < ${upper_power_limit}
    ...  msg=Wattage ${average_max_min[0]} crossed ${upper_power_limit}.
    \  Should Be True  ${average_max_min[1]} >= ${lower_power_limit}
    ...  msg=Wattage ${average_max_min[1]} bellow ${lower_power_limit}.


    # Check for "maximum" aggregation.
    :FOR  ${index}  IN  @{urls[1]}
    \  ${maximum}=  Get Sensors Aggregation Data  ${index}
    \  ${maximum_max_min}=  Min Max List  ${maximum}
    \  Log  (max, min): ${maximum_max_min}
    \  Should Be True  ${maximum_max_min[0]} < ${upper_power_limit}
    ...  msg=Wattage ${maximum_max_min[0]} crossed ${upper_power_limit}.
    \  Should Be True  ${maximum_max_min[1]} >= ${lower_power_limit}
    ...  msg=Wattage ${maximum_max_min[1]} bellow ${lower_power_limit}.

    # Every 30 seconds the power wattage data is updated.
    Sleep  30s

