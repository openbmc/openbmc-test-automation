*** Settings ***
Documentation     Test module for testing fan interface.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify Fan Sensors Atrributes
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
   \  ${json}=  To Json  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} >= 0
   \  Run Keyword And Ignore Error
   ...  Should Be True  ${json["data"]["Target"]} >= 0
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.RPMS
   \  Should Be True  ${json["data"]["Value"]} >= 0


Verify PCIE Sensors Atrributes
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
   \  ${json}=  To Json  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
   \  ${temp_in_DegreeC}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${temp_in_DegreeC} > 0


Verify Rail Voltage Sensors Atrributes
   [Documentation]  Check rail voltage attributes.
   [Tags]  Verify_Rail_Voltage_Sensor_Attributes

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
   \  ${json}=  To Json  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.Volts
   \  ${volts}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${volts} > 0


*** Keywords ***

