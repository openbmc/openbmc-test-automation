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
   [Documentation]  Verify if the BMC Model is populated in the device tree.
   [Tags]  Check_BMC_Model_Property_Is_Set
   [Template]  Template Check Property

   #Property
   model


Check BMC Name Property Is Set
   [Documentation]  Verify if the BMC name property is populated.
   [Tags]  Check_BMC_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   name


Check BMC Compatible Property Is Set
   [Documentation]  Verify if the BMC compatible property is populated.
   [Tags]  Check_BMC_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   compatible


Check BMC CPU Name Property Is Set
   [Documentation]  Verify if the BMC CPU name property is populated.
   [Tags]  Check_BMC_CPU_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   cpus/name


Check BMC CPU Compatible Property Is Set
   [Documentation]  Verify if the BMC CPU compatible property is populated.
   [Tags]  Check_BMC_CPU_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   cpus/cpu@0/compatible


Check BMC Memory Name Property Is Set
   [Documentation]  Verify if the BMC Memory name property is populated.
   [Tags]  Check_BMC_Memory_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   memory@80000000/name


Check BMC Memory Device Type Property Is Set
   [Documentation]  Verify if the BMC Memory Device Type property is
   ...  populated.
   [Tags]  Check_BMC_Memory_Device_Type_Property_Is_Set
   [Template]  Template Check Property

   #Property
   memory@80000000/device_type


Check BMC FSI Name Property Is Set
   [Documentation]  Verify if the BMC FSI name property is populated.
   [Tags]  Check_BMC_FSI_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   fsi-master/name


Check BMC FSI Compatible Property Is Set
   [Documentation]  Verify if the BMC FSI compatible property is populated.
   [Tags]  Check_BMC_FSI_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   fsi-master/compatible


Check BMC GPIO-FSI Name Property Is Set
   [Documentation]  Verify if the BMC GPIO-FSI name property is populated.
   [Tags]  Check_BMC_GPIO_FSI_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   gpio-fsi/name


Check BMC GPIO-FSI Compatible Property Is Set
   [Documentation]  Verify if the BMC GPIO-FSI compatible property is populated.
   [Tags]  Check_BMC_GPIO_FSI_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   gpio-fsi/compatible


Check BMC GPIO-keys Name Property Is Set
   [Documentation]  Verify if the BMC GPIO-keys name property is
   ...  populated.
   [Tags]  Check_BMC_GPIO_keys_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   gpio-keys/name


Check BMC GPIO-keys Compatible Property Is Set
   [Documentation]  Verify if the BMC GPIO-keys compatible property is
   ...  populated.
   [Tags]  Check_BMC_GPIO_keys_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   gpio-keys/compatible


Check BMC IIO-HWMON Name Property Is Set
   [Documentation]  Verify if the BMC IIO-HWMON-DPS310 name property is
   ...  populated.
   [Tags]  Check_BMC_IIO-HWMON_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   iio-hwmon-dps310/name


Check BMC IIO-HWMON Compatible Property Is Set
   [Documentation]  Verify if the BMC IIO-HWMON-DPS310 compatible property is
   ...  populated.
   [Tags]  Check_BMC_IIO-HWMON_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   iio-hwmon-dps310/compatible


Check BMC LED Name Property Is Set
   [Documentation]  Verify if the BMC LED name property is populated.
   [Tags]  Check_BMC_LED_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   leds/name


Check BMC LED Compatible Property Is Set
   [Documentation]  Verify if the BMC LED compatible property is populated.
   [Tags]  Check_BMC_LED_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   leds/compatible


Check BMC Clocks Name Property Is Set
   [Documentation]  Verify if the BMC clocks name property is populated.
   [Tags]  Check_BMC_Clocks_Name_Property_Is_Set
   [Template]  Template Check Property

   #Property
   clocks/name


Check BMC Clocks Compatible Property Is Set
   [Documentation]  Verify if the BMC clocks compatible property is populated.
   [Tags]  Check_BMC_Clocks_Compatible_Property_Is_Set
   [Template]  Template Check Property

   #Property
   clocks/clk_clkin/compatible


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
