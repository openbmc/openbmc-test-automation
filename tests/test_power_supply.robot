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

# With a loaded HTX work-load the wattage is typically within half of the upper
# limit. If the power drawn goes beyond the upper power limit, this test will
# fail.
${upper_power_limit}  ${2104}
${lower_power_limit}  ${0}
${power_data_collection_interval}  ${30}

# Every n seconds, the system collects the following for each power supply
# (e.g. ps0, ps1, etc):
# - The average power being drawn over the interval.
# - The maximum power drawn over the interval.
# At any given time, such readings can be obtained from the system.
# The lists shown below are examples of such data
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
    [Documentation]  Check that power consumption is within limits when host
    ...  is off.
    [Tags]  Power_Supply_Test_When_Host_Off

    REST Power Off  stack_mode=skip
    ${power_sensor_path}=  Get Sensors Aggregation URL List
    ...  /org/open_power/sensors/

    Check Power Telemetry When Host Off  ${power_sensor_path}


Power Supply Test When Host On
    [Documentation]  Check that power consumption is within limits when host
    ...  is on.
    [Tags]  Power_Supply_Test_When_Host_On

    REST Power On
    ${power_sensor_path}=  Get Sensors Aggregation URL List
    ...  /org/open_power/sensors/

    Repeat Keyword  ${LOOP_COUNT} times
    ...  Check Power Telemetry When Host On  ${power_sensor_path}


*** Keywords ***

Check Power Telemetry When Host On
    [Documentation]  Check that power consumption is within limits when host
    ...  is on.
    [Arguments]  ${power_paths}

    # Description of argument(s):
    # power_paths  A list of power paths (example list element
    # "/org/open_power/sensors/aggregation/per_30s/ps0_input_power/average").

    # Check for "average" aggregation.
    :FOR  ${power_path}  IN  @{power_paths[0]}
    \  ${averages}=  Get Sensors Aggregation Data  ${power_path}
    \  ${max}  ${min}=  Evaluate  (max(@{averages}), min(@{averages}))
    \  Should Be True  ${max} < ${upper_power_limit}
    ...  msg=Wattage ${max} crossed ${upper_power_limit}.
    \  Should Be True  ${min} >= ${lower_power_limit}
    ...  msg=Wattage ${min} below ${lower_power_limit}.

    # Check for "maximum" aggregation.
    :FOR  ${power_path}  IN  @{power_paths[1]}
    \  ${maximums}=  Get Sensors Aggregation Data  ${power_path}
    \  ${max}  ${min}=  Evaluate  (max(@{maximums}), min(@{maximums}))
    \  Should Be True  ${max} < ${upper_power_limit}
    ...  msg=Wattage ${max} crossed ${upper_power_limit}.
    \  Should Be True  ${min} >= ${lower_power_limit}
    ...  msg=Wattage ${min} below ${lower_power_limit}.

    # Every 30 seconds the power wattage data is updated.
    Sleep  ${power_data_collection_interval}s


Check Power Telemetry When Host Off
    [Documentation]  Check that power consumption is within limits when host
    ...  is off.
    [Arguments]  ${power_paths}

    # Description of argument(s):
    # power_paths  A list of power paths (example list element
    # "/org/open_power/sensors/aggregation/per_30s/ps0_input_power/average").

    # Every 30 seconds the power wattage data is updated.
    Sleep  ${power_data_collection_interval}s

    # Check for "average" aggregation.
    :FOR  ${power_path}  IN  @{power_paths[0]}
    \  ${averages}=  Get Sensors Aggregation Data  ${power_path}
    \  Should Be True  ${averages[0]} == ${lower_power_limit}
    ...  msg=Wattage ${averages[0]} more than ${lower_power_limit}.

    # Check for "maximum" aggregation.
    :FOR  ${power_path}  IN  @{power_paths[1]}
    \  ${maximums}=  Get Sensors Aggregation Data  ${power_path}
    \  Should Be True  ${maximums[0]} == ${lower_power_limit}
    ...  msg=Wattage ${maximums[0]} more than ${lower_power_limit}.

