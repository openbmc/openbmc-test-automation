*** Settings ***
Documentation       This suite is for Verifying BMC device tree.

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ipmi_client.robot
Library             String

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       FFDC On Test Case Fail
Test Template       Template Check Property

*** Variables ***
${devicetree_base}  /sys/firmware/devicetree/base/

*** Test Cases ***
[TC-001]-Check BMC Model Property Is Set  model
   [Documentation]  Verify if the BMC Model is populated in the device tree.
   [Tags]  [TC-001]-Check_BMC_Model_Property_Is_Set

[TC-002]-Check BMC Name Property Is Set  name
   [Documentation]  Verify if the BMC name property is populated.
   [Tags]  [TC-002]-Check_BMC_Name_Property_Is_Set

[TC-003]-Check BMC Compatible Property Is Set  compatible
   [Documentation]  Verify if the BMC compatible property is populated.
   [Tags]  [TC-003]-Check_BMC_Compatible_Property_Is_Set

[TC-004]-Check BMC CPU Name Property Is Set  cpus/name
   [Documentation]  Verify if the BMC CPU name property is populated.
   [Tags]  [TC-004]-Check_BMC_CPU_Name_Property_Is_Set

[TC-005]-Check BMC CPU Compatible Property Is Set  cpus/cpu@0/compatible
   [Documentation]  Verify if the BMC CPU compatible property is populated.
   [Tags]  [TC-005]-Check_BMC_CPU_Compatible_Property_Is_Set

[TC-006]-Check BMC Memory Name Property Is Set  memory/name
   [Documentation]  Verify if the BMC Memory name property is populated.
   [Tags]  [TC-006]-Check_BMC_Memory_Name_Property_Is_Set

[TC-007]-Check BMC Memory Device Type Property Is Set  memory/device_type
   [Documentation]  Verify if the BMC Memory Device Type property is
   ...  populated.
   [Tags]  [TC-007]-Check_BMC_Memory_Device_Type_Property_Is_Set

[TC-008]-Check BMC FSI Name Property Is Set  fsi-master/name
   [Documentation]  Verify if the BMC FSI name property is populated.
   [Tags]  [TC-008]-Check_BMC_FSI_Name_Property_Is_Set

[TC-009]-Check BMC FSI Compatible Property Is Set  fsi-master/compatible
   [Documentation]  Verify if the BMC FSI compatible property is populated.
   [Tags]  [TC-009]-Check_BMC_FSI_Compatible_Property_Is_Set

[TC-010]-Check BMC LED Name Property Is Set  leds/name
   [Documentation]  Verify if the BMC LED name property is populated.
   [Tags]  [TC-010]-Check_BMC_LED_Name_Property_Is_Set

[TC-011]-Check BMC LED Compatible Property Is Set  leds/compatible
   [Documentation]  Verify if the BMC LED compatible property is populated.
   [Tags]  [TC-011]-Check_BMC_LED_Compatible_Property_Is_Set

[TC-012]-Check BMC Clocks Name Property Is Set  clocks/name
   [Documentation]  Verify if the BMC clocks name property is populated.
   [Tags]  [TC-012]-Check_BMC_Clocks_Name_Property_Is_Set

[TC-013]-Check BMC Clocks Compatible Property Is Set  clocks/clk_clkin/compatible
   [Documentation]  Verify if the BMC clocks compatible property is populated.
   [Tags]  [TC-013]-Check_BMC_Clocks_Compatible_Property_Is_Set

*** Keywords ***

Template Check Property
    [Documentation]  Check for the existence of a property in the device tree.
    [Arguments]   ${property}

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  ${property}
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length  ${output}

Verify Property Length
    [Documentation]  Check for Property Length and should be > 1.
    [Arguments]   ${output}

    Should Not Be Empty  ${output}
    ${length}=  Get Length  ${output}
    Should Be True  ${length} > 1
