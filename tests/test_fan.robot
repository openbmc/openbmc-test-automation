*** Settings ***
Documentation     Test module for testing fan interface.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

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


Verify VDN Temperature Sensors Attributes
   [Documentation]  Check vdn temperature attributes.
   [Tags]  Verify_VDN_Temperature_Sensors_Attributes

   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vdn_temp
   ${temp_vdn}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vdn_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vdn_temp
   # {
   #    "Scale": -3,
   #    "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #    "Value": 3000
   # }

   :FOR  ${entry}  IN  @{temp_vdn}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
   \  ${volts}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${volts} > 0


Verify VCS Temperature Sensors Attributes
   [Documentation]  Check vcs temperature attributes.
   [Tags]  Verify_VCS_Temperature_Sensors_Attributes

   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vcs_temp
   ${temp_vcs}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vcs_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vcs_temp
   # {
   #     "Scale": -3,
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #     "Value": 31000
   # },


   :FOR  ${entry}  IN  @{temp_vcs}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
   \  ${volts}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${volts} > 0


Verify VDD Temperature Sensors Attributes
   [Documentation]  Check vdd temperature attributes.
   [Tags]  Verify_VDD_Temperature_Sensors_Attributes

   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vdd_temp
   ${temp_vdd}=  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vdd_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vdd_temp
   # {
   #     "Scale": -3,
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #     "Value": 4000
   # }

   :FOR  ${entry}  IN  @{temp_vdd}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
   \  ${volts}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${volts} > 0


Verify VDDR Temperature Sensors Attributes
   [Documentation]  Check vddr temperature attributes.
   [Tags]  Verify_VDDR_Temperature_Sensors_Attributes

   # Example of one of the entries returned by 'Get Endpoint Paths':
   # /xyz/openbmc_project/sensors/temperature/p0_vddr_temp
   ${temp_vddr}=
   ...  Get Endpoint Paths  /xyz/openbmc_project/sensors/  *_vddr_temp

   # Example:
   # Access the properties of the rail voltage and it should contain
   # the following entries:
   # /xyz/openbmc_project/sensors/temperature/p0_vddr_temp
   # {
   #     "Scale": -3,
   #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
   #     "Value": 4000
   # }

   :FOR  ${entry}  IN  @{temp_vddr}
   \  ${resp}=  OpenBMC Get Request  ${entry}
   \  ${json}=  To JSON  ${resp.content}
   \  Should Be True  ${json["data"]["Scale"]} == -3
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
   \  ${volts}=  Evaluate  ${json["data"]["Value"]} / 1000
   \  Should Be True  ${volts} > 0


*** Keywords ***

