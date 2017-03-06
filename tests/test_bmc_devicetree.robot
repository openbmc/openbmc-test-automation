*** Settings ***
Documentation       This suite is for Verifying BMC device tree.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ipmi_client.robot
Library             String

Test Setup          Open Connection And Log In
Test Teardown       Post Test Case Execution

*** Variables ***
${devicetree_base}  /sys/firmware/devicetree/base/

*** Test Cases ***
Check BMC Model Property Is Set
   #Property
   model
   [Documentation]  Verify if the BMC Model is populated in the device tree.
   [Tags]  Check_BMC_Model_Property_Is_Set
   [Template]  Template Check Property

Check BMC Name Property Is Set
   #Property
   name
   [Documentation]  Verify if the BMC name property is populated.
   [Tags]  Check_BMC_Name_Property_Is_Set
   [Template]  Template Check Property

Check BMC Compatible Property Is Set
   #Property
   compatible
   [Documentation]  Verify if the BMC compatible property is populated.
   [Tags]  Check_BMC_Compatible_Property_Is_Set
   [Template]  Template Check Property

Check BMC CPU Name Property Is Set
   #Property
   cpus/name
   [Documentation]  Verify if the BMC CPU name property is populated.
   [Tags]  Check_BMC_CPU_Name_Property_Is_Set
   [Template]  Template Check Property

Check BMC CPU Compatible Property Is Set
   #Property
   cpus/cpu@0/compatible
   [Documentation]  Verify if the BMC CPU compatible property is populated.
   [Tags]  Check_BMC_CPU_Compatible_Property_Is_Set
   [Template]  Template Check Property

Check BMC Memory Name Property Is Set
   #Property
   memory/name
   [Documentation]  Verify if the BMC Memory name property is populated.
   [Tags]  Check_BMC_Memory_Name_Property_Is_Set
   [Template]  Template Check Property

Check BMC Memory Device Type Property Is Set
   #Property
   memory/device_type
   [Documentation]  Verify if the BMC Memory Device Type property is
   ...  populated.
   [Tags]  Check_BMC_Memory_Device_Type_Property_Is_Set
   [Template]  Template Check Property

Check BMC FSI Name Property Is Set
   #Property
   fsi-master/name
   [Documentation]  Verify if the BMC FSI name property is populated.
   [Tags]  Check_BMC_FSI_Name_Property_Is_Set
   [Template]  Template Check Property

Check BMC FSI Compatible Property Is Set
   #Property
   fsi-master/compatible
   [Documentation]  Verify if the BMC FSI compatible property is populated.
   [Tags]  Check_BMC_FSI_Compatible_Property_Is_Set
   [Template]  Template Check Property

Check BMC LED Name Property Is Set
   #Property
   leds/name
   [Documentation]  Verify if the BMC LED name property is populated.
   [Tags]  Check_BMC_LED_Name_Property_Is_Set
   [Template]  Template Check Property

Check BMC LED Compatible Property Is Set
   #Property
   leds/compatible
   [Documentation]  Verify if the BMC LED compatible property is populated.
   [Tags]  Check_BMC_LED_Compatible_Property_Is_Set
   [Template]  Template Check Property

Check BMC Clocks Name Property Is Set
   #Property
   clocks/name
   [Documentation]  Verify if the BMC clocks name property is populated.
   [Tags]  Check_BMC_Clocks_Name_Property_Is_Set
   [Template]  Template Check Property

Check BMC Clocks Compatible Property Is Set
   #Property
   clocks/clk_clkin/compatible
   [Documentation]  Verify if the BMC clocks compatible property is populated.
   [Tags]  Check_BMC_Clocks_Compatible_Property_Is_Set
   [Template]  Template Check Property

*** Keywords ***

Template Check Property
    [Documentation]  Check for the existence of a property in the device tree.
    [Arguments]  ${property}
    #property: Value of Property

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  ${property}
    ${output}  ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${length}=  Get Length  ${output}
    Should Be True  ${length} > 1

Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
