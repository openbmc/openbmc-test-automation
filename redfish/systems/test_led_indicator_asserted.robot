*** Settings ***
Documentation       Check the indicator LEDs on the system can set the assert
...                 property to the correct state.

Resource            ../../lib/rest_client.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/resource.robot
Resource            ../../lib/boot_utils.robot
Library             ../../lib/gen_robot_valid.py
Library             ../../lib/gen_robot_keyword.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution


*** Test Cases ***

Verify LED Lamp Test Asserted At Standby
    [Documentation]  Verify the LED asserted at standby is set to off or blinking.
    [Tags]  Verify_LED_Lamp_Test_Asserted_At_Standby
    [Template]  Set and Verify Lamp LED Indicator

    # pre_req_state     asserted     expected_indicator_led
    Off                 1            Blinking
    Off                 0            Off


Verify LED Lamp Test Asserted At Runtime
    [Documentation]  Verify the LED asserted at runtime is set to off or blinking.
    [Tags]  Verify_LED_Lamp_Test_Asserted_At_Runtime
    [Template]  Set and Verify Lamp LED Indicator

    # pre_req_state     asserted     expected_indicator_led
    On                  1            Blinking
    On                  0            Off


Verify LED Power Supply Units Asserted At Standby
    [Documentation]  Verify the power supply units are asserted at standby to lit or off.
    [Tags]  Verify_LED_Power_Supply_Units_Asserted_At_Standby
    [Template]  Set and Verify LED Indicator

    # pre_req_state     asserted                                        expected_indicator_led
    Off                 "xyz.openbmc_project.Led.Physical.Action.On"    Lit
    Off                 "xyz.openbmc_project.Led.Physical.Action.Off"   Off


Verify LED Power Supply Units Asserted At Runtime
    [Documentation]  Verify the power supply units are asserted at runtime to lit or off.
    [Tags]  Verify_LED_Power_Supply_Units_Asserted_At_Runtime
    [Template]  Set and Verify LED Indicator

    # pre_req_state     asserted                                        expected_indicator_led
    On                  "xyz.openbmc_project.Led.Physical.Action.On"    Lit
    On                  "xyz.openbmc_project.Led.Physical.Action.Off"   Off


Verify LED Fans Asserted At Standby
    [Documentation]  Verify the fans are asserted at standby to lit or off.
    [Tags]  Verify_LED_Fans_Asserted_At_Standby
    [Template]  Set and Verify Fan LED Indicators

    # pre_req_state     asserted                                        expected_indicator_led
    Off                 "xyz.openbmc_project.Led.Physical.Action.On"    Lit
    Off                 "xyz.openbmc_project.Led.Physical.Action.Off"   Off


Verify LED Fans Asserted At Runtime
    [Documentation]  Verify the fans are asserted at runtime to lit or off.
    [Tags]  Verify_LED_Fans_Asserted_At_Runtime
    [Template]  Set and Verify Fan LED Indicators

    # pre_req_state     asserted                                        expected_indicator_led
    On                  "xyz.openbmc_project.Led.Physical.Action.On"    Lit
    On                  "xyz.openbmc_project.Led.Physical.Action.Off"   Off


*** Keywords ***

Set and Verify Lamp LED Indicator
    [Documentation]  Verify the indicator LED for the group lamp test is asserted.
    [Arguments]  ${pre_req_state}  ${asserted}  ${expected_indicator_led}

    # Description of Arguments(s):
    # pre_req_state           The pre-requisite state of the host to perform the test (e.g. "On")
    # asserted                The assert property that sets the value to 0 - Off or 1 - Blinking (e.g. "1")
    # expected_indicator_led  The expected value of the IndicatorLED attribute for all the
    #                         LEDs after the lamp test is initiated (e.g. "Blinking")

    Run Key U  Redfish Power ${pre_req_state} \ stack_mode=skip \ quiet=1
    Redfish.Login

    Redfish.Put  ${LED_LAMP_TEST_ASSERTED_URI}attr/Asserted  body={"data":${asserted}}

    # Example result:
    # power_supplies:
    #   [0]:
    #     [MemberId]:                                   powersupply0
    #     [PartNumber]:                                 02CL396
    #     [IndicatorLED]:                               Blinking
    #     [EfficiencyPercent]:                          90
    #     [Status]:
    #       [Health]:                                   OK
    #       [State]:                                    Enabled

    Verify Indicator LEDs  ${expected_indicator_led}


Set and Verify LED Indicator
    [Documentation]  Verify the indicator LED for the power supply units are asserted.
    [Arguments]  ${pre_req_state}  ${asserted}  ${expected_indicator_led}

    # Description of Arguments(s):
    # pre_req_state           The pre-requisite state of the host to perform the test (e.g. "On")
    # asserted                The assert property that sets the value
    #                         (e.g. "xyz.openbmc_project.Led.Physical.Action.On")
    # expected_indicator_led  The expected value of the IndicatorLED attribute for all the
    #                         power supplies units are initiated (e.g. "Lit")

    Run Key U  Redfish Power ${pre_req_state} \ stack_mode=skip \ quiet=1
    Redfish.Login

    # Put both power supply LEDs On/Off to check all units are asserted
    Redfish.Put  ${LED_PHYSICAL_PS0_URI}attr/State  body={"data":${asserted}}
    Redfish.Put  ${LED_PHYSICAL_PS1_URI}attr/State  body={"data":${asserted}}

    # Example output:
    # power_supplies:
    #   [0]:
    #     [MemberId]:                                   powersupply0
    #     [IndicatorLED]:                               Lit
    #     [Status]:
    #       [Health]:                                   OK
    #       [State]:                                    Enabled
    #   [1]:
    #     [MemberId]:                                   powersupply1
    #     [IndicatorLED]:                               Lit
    #     [Status]:
    #       [Health]:                                   OK
    #       [State]:                                    Enabled

    Verify Indicator LEDs  ${expected_indicator_led}


Verify Indicator LEDs
    [Documentation]  Verify the LEDs on the power supply units are set according to caller's expectation.
    [Arguments]  ${expected_indicator_led}

    # Description of Arguments(s):
    # expected_indicator_led  The expected value of the IndicatorLED attribute for all the
    #                         LEDs after the lamp test is initiated (e.g. "Blinking")

    ${power_supplies}=  Redfish.Get Attribute  ${REDFISH_CHASSIS_POWER_URI}  PowerSupplies
    Rprint Vars  power_supplies
    FOR  ${power_supply_leds}  IN  @{power_supplies}
        Valid Value  power_supply_leds['IndicatorLED']  ['${expected_indicator_led}']
    END


Set and Verify Fan LED Indicators
    [Documentation]  Verify the indicator LED for the fans are asserted.
    [Arguments]  ${pre_req_state}  ${asserted}  ${expected_indicator_led}

    # Description of Arguments(s):
    # pre_req_state           The pre-requisite state of the host to perform the test (e.g. "On")
    # asserted                The assert property that sets the value
    #                         (e.g. "xyz.openbmc_project.Led.Physical.Action.On")
    # expected_indicator_led  The expected value of the IndicatorLED attribute for all the fans
    #                         are initiated (e.g. "Lit")

    Run Key U  Redfish Power ${pre_req_state} \ stack_mode=skip \ quiet=1
    Redfish.Login

    # Put all the fan LEDs On/Off to check all are asserted
    Redfish.Put  ${LED_PHYSICAL_FAN0_URI}attr/State  body={"data":${asserted}}
    Redfish.Put  ${LED_PHYSICAL_FAN2_URI}attr/State  body={"data":${asserted}}
    Redfish.Put  ${LED_PHYSICAL_FAN3_URI}attr/State  body={"data":${asserted}}

    # Example output:
    # fans:
    #   [0]:
    #     [@odata.id]:                                  /redfish/v1/Chassis/chassis/Thermal#/Fans/0
    #     [@odata.type]:                                #Thermal.v1_3_0.Fan
    #     [IndicatorLED]:                               Lit
    #     [MemberId]:                                   fan0_0
    #     [Name]:                                       fan0 0
    #     [Status]:
    #       [Health]:                                   OK
    #       [State]:                                    Enabled

    ${fans}=  Redfish.Get Attribute  ${REDFISH_CHASSIS_THERMAL_URI}  Fans
    Rprint Vars  fans
    FOR  ${fan_leds}  IN  @{fans}
        Valid Value  fan_leds['IndicatorLED']  ['${expected_indicator_led}']
    END


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
