*** Settings ***
Documentation     Test module for testing fan interface.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Min Fan Speed Allowed Range
    [Documentation]  Set "Target" value 0 and expect Target to revert
    ...              to initial MAX target speed 10500.
    [Tags]  Min_Fan_Speed_Allowed_Range
    # Example:
    # /xyz/openbmc_project/sensors/fan_tach/fan0
    # {
    #     "Scale": 0,
    #     "Target": 0,
    #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.RPMS",
    #     "Value": 10302
    # }

    ${init_speed}=  Read Attribute
    ...  /xyz/openbmc_project/sensors/fan_tach/fan0  Target  quiet=${1}

    # Set to minimum allow value "0" to target.
    ${args}=  Create Dictionary   data=${0}
    Write Attribute
    ...  /xyz/openbmc_project/sensors/fan_tach/fan0  Target  data=${args}

    # default wait for fan to throttle to original target value.
    Sleep  15s

    ${curr_speed}=  Read Attribute
    ...  /xyz/openbmc_project/sensors/fan_tach/fan0  Target  quiet=${1}

    Should Be True  ${init_speed} == ${curr_speed}


Write Fan Speed Allowed Range
    [Documentation]  Set "Target" value and expect feedback speed
    ...              "Value" to update.
    [Tags]  Write_Fan_Speed_Allowed_Range
    # Example:
    # /xyz/openbmc_project/sensors/fan_tach/fan0
    # {
    #    "Scale": 0,
    #    "Target": 10000,
    #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.RPMS",
    #    "Value": 10245
    # }

    ${args}=  Create Dictionary   data=${10000}
    Write Attribute
    ...  /xyz/openbmc_project/sensors/fan_tach/fan0  Target  data=${args}

    # default wait for fan to throttle to original target value.
    Sleep  15s

    # Allow value range , the "Value" is to be within 15% of
    # the "Target" set.
    # 15% × 10000 = 1500 , allowed is from 8500 to 10000
    Wait Until Keyword Succeeds  2 min  15 sec
    ...  Verify Feedback Speed  ${8500}  ${10000}


Max Fan Speed Allowed Range
    [Documentation]  Set "Target" value and expect feedback speed
    ...              "Value" to update.
    [Tags]  Max_Fan_Speed_Allowed_Range

    # This will revert back to original MAX speed.
    # Example:
    # /xyz/openbmc_project/sensors/fan_tach/fan0
    # {
    #    "Scale": 0,
    #    "Target": 10500,
    #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.RPMS",
    #    "Value": 10245
    # }

    ${args}=  Create Dictionary   data=${10500}
    Write Attribute
    ...  /xyz/openbmc_project/sensors/fan_tach/fan0  Target  data=${args}

    # default wait for fan to throttle to original target value.
    Sleep  15s

    # Allow value range , the "Value" is to be within 15% of
    # the "Target" set.
    # 15% × 10500 = 1575, allowed is from 8925 to 10500
    Wait Until Keyword Succeeds  2 min  15 sec
    ...  Verify Feedback Speed  ${8925}  ${10500}


Verify Fan Sensors Attributes
   [Documentation]  Check fan attributes.
   [Tags]  Verify_Fan_Sensor_Attributes

   # Example:
   # /xyz/openbmc_project/sensors/fan_tach/fan0
   # /xyz/openbmc_project/sensors/fan_tach/fan1
   # /xyz/openbmc_project/sensors/fan_tach/fan2
   # /xyz/openbmc_project/sensors/fan_tach/fan3
   ${fans}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  fan*

   # Access the properties of the fan and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/fan_tach/fan0
   # {
   #     "Scale": 0,
   #     "Target": 0,
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.RPMS",
   #     "Value": 0
   # }

   :FOR  ${entry}  IN  @{fans}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} >= 0
   \  Run Keyword And Ignore Error
   ...  Should Be True  ${json["data"]["Target"]} >= 0
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.RPMS
   \  Should Be True  ${json["data"]["Value"]} >= 0


Verify PCIE Sensors Attributes
   [Documentation]  Probe PCIE attributes.
   [Tags]  Verify_PCIE_Sensor_Attributes

   # Example:
   # /xyz/openbmc_project/sensors/temperature/pcie
   ${temp_pcie}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  pcie

   # Access the properties of the PCIE and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/pcie
   # {
   #    "Scale": -3,
   #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #    "Value": 29625
   # }


   :FOR  ${entry}  IN  @{temp_pcie}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
   \  ${temp_in_DegreeC}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${temp_in_DegreeC} > 0


Verify Rail Voltage Sensors Attributes
   [Documentation]  Check rail voltage attributes.
   [Tags]  Verify_Rail_Voltage_Sensor_Attributes

   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/voltage/rail_1_voltage
   # /xyz/openbmc_project/sensors/voltage/rail_2_voltage
   ${temp_rail}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  rail*

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # "/xyz/openbmc_project/sensors/voltage/rail_1_voltage":
   # {
   #    "Scale": -3,
   #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.Volts",
   #    "Value": 5097
   # },

   :FOR  ${entry}  IN  @{temp_rail}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.Volts
   \  ${volts}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${volts} > 0


*** Keywords ***

Verify Feedback Speed
    [Documentation]  Verify if the current feedback speed "Value" is in
    ...              user specified range.
    [Arguments]  ${Min_speed}  ${max_speed}
    # Description of argument(s):
    # Min_speed    Lower limit of the fan speed.
    # Max_speed    Upper limit of the fan speed.

    ${curr_speed}=  Read Attribute
    ...  /xyz/openbmc_project/sensors/fan_tach/fan0  Value  quiet=${1}
    Should Be True  ${curr_speed} > ${min_speed}
    Should Be True  ${curr_speed} < ${max_speed}
