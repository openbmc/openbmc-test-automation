*** Settings ***
Documentation     Test module for testing fan interface.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify Fan Sensors Atrributes
   [Documentation]  Check fan attributes.
   [Tags]  Verify_Fan_Sensor_Attributes

   ${fans}=  Get Fan Sensor List

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
   \  Should Be True  ${json["data"]["Target"]} >= 0
   \  Should Be Equal As Strings
   ...  ${json["data"]["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.RPMS
   \  Should Be True  ${json["data"]["Value"]} >= 0


*** Keywords ***

Get Fan Sensor List
    [Documentation]  Get a list of fan sensor URLs.
    # Example:
    # /xyz/openbmc_project/sensors/fan_tach/fan0
    # /xyz/openbmc_project/sensors/fan_tach/fan1
    # /xyz/openbmc_project/sensors/fan_tach/fan2
    # /xyz/openbmc_project/sensors/fan_tach/fan3

    ${resp}=  Openbmc Get Request
    ...  /xyz/openbmc_project/sensors/fan_tach/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}
    [Return]  ${jsondata["data"]}
