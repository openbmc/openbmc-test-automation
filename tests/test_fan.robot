*** Settings ***
Documentation     Test module for testing fan interface.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resourec          ../lib/boot_utils.robot

Suite Setup       REST Power On
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Verify Fan Sensors Atrributes
   [Documentation]  Check fan attributes.
   [Tags]  verify_Fan_Sensor_Attributes

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
   \  Read Attribute  ${entry}  Scale
   \  Read Attribute  ${entry}  Target
   \  ${unit}=  Read Attribute  ${entry}  Unit
   \  Should Be Equal As Strings  ${unit.rsplit('.', 1)[1]}  RPMS
   \  Read Attribute  ${entry}  Value


*** Keywords ***

Get Fan Sensor List
   [Documentation]  Get URL fan sensor list.

    ${resp}=  Openbmc Get Request
    ...  /xyz/openbmc_project/sensors/fan_tach/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}
    [Return]  ${jsondata["data"]}
