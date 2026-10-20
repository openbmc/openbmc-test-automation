*** Settings ***
Documentation       Check the indicator LEDs on the system can set the assert
...                 property to the correct state.

Resource            ../../lib/rest_client.robot
Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/resource.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution

Test Tags           Led_Indicator_Asserted

*** Test Cases ***

Verify Location Indicator Active status
    [Documentation]  Verify the Location Indicator Active status to true or false.
    [Tags]  Verify_Location_Indicator_Active_status
    [setup]     Set Suite LED Indicator Initial Value
    [Teardown]  Set Initial Value  ${value}

    Set And Verify LED Location Indicator Active  ${set_value}

*** Keywords ***

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


Set Suite LED Indicator Initial Value
    [Documentation]  set suite For LED Initial value.

    ${value}=  Redfish.Get Attribute      /redfish/v1/Systems/${SYSTEM_ID}  LocationIndicatorActive
    Set Suite Variable  ${value}

    IF  ${value} == False
        Set Suite Variable  ${set_value}  ${True}
    ELSE
        Set Suite Variable  ${set_value}  ${False}
    END


Set And Verify LED Location Indicator Active
    [Documentation]  Set And Verify LED Location Indicator State.
    [Arguments]  ${set_value}

    # Description of argument(s):
    # set_value      Location indicator active value (True, False).

    ${payload}=  Create Dictionary    LocationIndicatorActive=${set_value}
    Redfish.Patch      /redfish/v1/Systems/${SYSTEM_ID}    body=&{payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    ${value}=  Redfish.Get Attribute      /redfish/v1/Systems/${SYSTEM_ID}  LocationIndicatorActive

    Should Be Equal As Strings  ${value}    ${set_value}


Set Initial Value
    [Documentation]  setting back Initial value.
    [Arguments]  ${value}

    # Description of argument(s):
    # value      Location indicator active value (True, False).

    ${payload}=  Create Dictionary    LocationIndicatorActive=${value}
    Redfish.Patch      /redfish/v1/Systems/${SYSTEM_ID}    body=&{payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    ${intial_value}=  Redfish.Get Attribute      /redfish/v1/Systems/${SYSTEM_ID}  LocationIndicatorActive
    Should Be Equal As Strings  ${intial_value}  ${value}
