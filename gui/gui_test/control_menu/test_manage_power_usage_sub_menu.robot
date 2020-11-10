*** Settings ***

Documentation  Test OpenBMC GUI "Manage power usage" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_manage_power_heading}      //h1[text()="Manage power usage"]
${xpath_power_ops_checkbox}        //*[@data-test-id='managePowerUsage-checkbox-togglePowerCapField']
${xpath_cap_input_button}          //*[@data-test-id='managePowerUsage-input-powerCapValue']
${xpath_submit_button}             //*[@data-test-id='managePowerUsage-button-savePowerCapValue']

*** Test Cases ***

Verify Navigation To Manage Power Usage Page
    [Documentation]  Verify navigation to manage power usage page.
    [Tags]  Verify_Navigation_To_Manage_Power_Usage_Page

    Page Should Contain Element  ${xpath_manage_power_heading}


Verify Existence Of All Sections In Manage Power Usage Page
    [Documentation]  Verify existence of all sections in Manage Power Usage page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Manage_Power_Usage_Page

    Page Should Contain  Current power consumption
    Page Should Contain  Power cap setting
    Page Should Contain  Power cap value


Verify Server Power Cap Setting Is On
    [Documentation]  Verify server power cap setting is on.
    [Tags]  Verify_Server_Power_Cap_Setting_Is_On

    Page Should Contain Element  ${xpath_power_ops_checkbox}
    Click Element At Coordinates  ${xpath_power_ops_checkbox}  0  0
    ${Is_Checkbox_Selected}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${xpath_power_ops_checkbox}
    Run Keyword If  False == ${Is_Checkbox_Selected}  Click Element  ${xpath_power_ops_checkbox}
    Checkbox Should Be Selected  ${xpath_power_ops_checkbox}

    # With chcekbox selected, apply cap text successfully.
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10

    # Now put a cap value and submit annd check if submitted cap value is effective.
    Input Text  ${xpath_cap_input_button}  ${10}
    Click Element  ${xpath_submit_button}
    Sleep  1s
    ${cap}=  Get Power Cap Value

    # Convert to strings and compare
    ${cap}=  Convert To String  ${cap}
    ${applied_cap}=  Convert To String  10

    # Both should be same
    Should Be Equal  ${cap}  ${applied_cap}

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_manage_power_usage_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  manage-power-usage


Get Power Cap Value
    [Documentation]  Retrieve power cap value.

    ${redfish_serial_number}=  Redfish.Get Attribute  /redfish/v1/Chassis/chassis/Power/   PowerControl

    # In Redfish version, LimitInWatts is for power cap. However, its stored NOT exactly in json
    # format so with additional steps in consequent steps string is converted to json formatted
    # so that a json object can be formed.
    #
    # "PowerControl": [
    #    {
    #        "@odata.id": "/redfish/v1/Chassis/chassis/Power#/PowerControl/0",
    #        "@odata.type": "#Power.v1_0_0.PowerControl",
    #        "MemberId": "0",
    #        "Name": "Chassis Power Control",
    #        "PowerLimit": {
    #            "LimitInWatts": 3000.0
    #        },
    #        "PowerMetrics": {
    #            "AverageConsumedWatts": 16,
    #            "IntervalInMin": 10,
    #            "MaxConsumedWatts": 22
    #        }
    #    }
    # ],

    ${redfish_serial_number2}=  Convert To String  ${redfish_serial_number}
    ${redfish_serial_number3}=  Replace String  ${redfish_serial_number2}   '  "
    ${redfish_serial_number3}=  Replace String  ${redfish_serial_number3}   None  "None"
    ${redfish_serial_number3}=  Remove String        ${redfish_serial_number3}   [    ]

    ${redfish_serial_number4}=  Convert To String  ${redfish_serial_number3}
    ${json_object}=  Evaluate  json.loads('''${redfish_serial_number4}''')  json
    ${power_cap}=  Evaluate  ${json_object["PowerLimit"]["LimitInWatts"]}
    [return]  ${power_cap}
