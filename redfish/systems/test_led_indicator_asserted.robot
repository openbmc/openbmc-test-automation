*** Settings ***
Documentation       Check the indicator leds on the system are asserted.

Resource            ../../lib/rest_client.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/resource.robot
Resource            ../../lib/boot_utils.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution


*** Test Cases ***

Verify LED Lamp Test Asserted At Standby
    [Documentation]  Verify the led asserted at standby is set to off or blinking.
    [Tags]  Verify_LED_Lamp_Test_Asserted_At_Standby
    [Template]  Verify Lamp LED Indicator

    # asserted_type    set_type   expected_state
    Blinking           1          Off
    Off                0          Off


Verify LED Lamp Test Asserted At Runtime
    [Documentation]  Verify the led asserted at runtime is set to off or blinking.
    [Tags]  Verify_LED_Lamp_Test_Asserted_At_Runtime
    [Template]  Verify Lamp LED Indicator

    # asserted_type    set_type   expected_state
    Blinking           1          Running
    Off                0          Running


Verify LED Power Supply Units Asserted At Standby
    [Documentation]  Verify the power supply units are asserted at standby to lit or off.
    [Tags]  Verify_LED_Power_Supply_Units_Asserted_At_Standby
    [Template]  Verify LED Indicator Asserted

    # asserted_type    set_type                                       expected_state
    Lit                "xyz.openbmc_project.Led.Physical.Action.On"   Running
    Off                "xyz.openbmc_project.Led.Physical.Action.Off"  Running


Verify LED Power Supply Units Asserted At Runtime
    [Documentation]  Verify the power supply units are asserted at runtime to lit or off.
    [Tags]  Verify_LED_Power_Supply_Units_Asserted_At_Runtime
    [Template]  Verify LED Indicator Asserted

    # asserted_type    set_type                                       expected_state
    Lit                "xyz.openbmc_project.Led.Physical.Action.On"   Running
    Off                "xyz.openbmc_project.Led.Physical.Action.Off"  Running


*** Keywords ***

Verify Lamp LED Indicator
    [Documentation]  Verify the indicator led for the group lamp test is asserted.
    [Arguments]  ${asserted_type}  ${set_type}  ${expected_state}

    # Description of Arguments(s):
    # asserted_type  Read the led is asserted to blinking or off (e.g. "Blinking")
    # set_type       Set the type to 0 - Off or 1 - Blinking (e.g. "1")
    # expected_state Set the state of the host to Standby or Runtime (e.g. "Running")

    Set Initial Test State  ${expected_state}
    Redfish.Put  ${LED_LAMP_TEST_ASSERTED_URI}  body={"data":${set_type}}

    # Example output:
    # led_indicator:
    #   [0]:
    #     [MemberId]:                                   powersupply0
    #     [PartNumber]:                                 02CL396
    #     [IndicatorLED]:                               Blinking
    #     [EfficiencyPercent]:                          90
    #     [Status]:
    #       [Health]:                                   OK
    #       [State]:                                    Enabled

    Verify Indicator LEDs Are Asserted  ${asserted_type}


Verify LED Indicator Asserted
    [Documentation]  Verify the indicator led for the power supply units are asserted.
    [Arguments]  ${asserted_type}  ${set_type}  ${expected_state}

    # Description of Arguments(s):
    # asserted_type  Read the led is asserted to lit or off (e.g. "Lit")
    # set_type       Set the type to 0n or Off (e.g. "xyz.openbmc_project.Led.Physical.Action.On")
    # expected_state Set the state of the host to Standby or Runtime (e.g. "Running")

    Set Initial Test State  ${expected_state}

    # Put both power supply LEDs On/Off to check all units are asserted
    Redfish.Put  ${LED_PHYSICAL_PS0_URI}  body={"data": ${set_type}}
    Redfish.Put  ${LED_PHYSICAL_PS1_URI}  body={"data": ${set_type}}

    # Example output:
    # led_indicator:
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

    Verify Indicator LEDs Are Asserted  ${asserted_type}


Verify Indicator LEDs Are Asserted
    [Documentation]  Check the leds on the power supply units are set according to asserted type.
    [Arguments]  ${asserted_type}

    ${led_indicator}=  Redfish.Get Attribute  ${REDFISH_CHASSIS_POWER_URI}  PowerSupplies
    Rprint Vars  led_indicator

    ${resp}=  Redfish.Get  ${REDFISH_CHASSIS_POWER_URI}
    @{power_supply_led}=  Get From Dictionary  ${resp.dict}  PowerSupplies
    FOR  ${power_supply_led}  IN  @{power_supply_led}
        Valid Value  power_supply_led['IndicatorLED']  [${asserted_type}]
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
