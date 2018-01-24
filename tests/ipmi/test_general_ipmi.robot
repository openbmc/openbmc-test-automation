*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Teardown       FFDC On Test Case Fail

*** Variables ***

*** Test Cases ***

Set Asset Tag With Valid String Length
    [Documentation]  Set asset tag with valid string length and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length

    # Allowed MAX characters length for asset tag name is 63.
    ${random_string}=  Generate Random String  63
    Run Keyword  Run IPMI Standard Command  dcmi set_asset_tag ${random_string}

    ${asset_tag}=  Run Keyword  Run IPMI Standard Command  dcmi asset_tag
    Should Contain  ${asset_tag}  ${random_string}


Set Asset Tag With Invalid String Length
    [Documentation]  Verify error while setting invalid asset tag via IPMI.
    [Tags]  Set_Asset_Tag_With_Invalid_String_Length

    # Any string more than 63 character is invalid for asset tag.
    ${random_string}=  Generate Random String  64

    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  dcmi set_asset_tag ${random_string}
    Should Contain  ${resp}  Parameter out of range  ignore_case=True


Set Asset Tag With Valid String Length Via REST
    [Documentation]  Set valid asset tag via REST and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length_Via_REST

    ${random_string}=  Generate Random String  63
    ${args}=  Create Dictionary  data=${random_string}
    Write Attribute  /xyz/openbmc_project/inventory/system  AssetTag
    ...  data=${args}

    ${asset_tag}=  Read Attribute  /xyz/openbmc_project/inventory/system
    ...  AssetTag
    Should Be Equal As Strings  ${asset_tag}  ${random_string}

Verify Chassis Identify via IPMI
    [Documentation]  Verify "chassis identify" using IPMI command.
    [Tags]  Verify_Chassis_Identify_via_IPMI

    # Set to default "chassis identify" and verify that LED blinks for 15s.
    Run IPMI Standard Command  chassis identify
    Verify Identify LED State  Blink

    Sleep  15s
    Verify Identify LED State  Off

    # Set "chassis identify" to 10s and verify that the LED blinks for 10s.
    Run IPMI Standard Command  chassis identify 10
    Verify Identify LED State  Blink

    Sleep  10s
    Verify Identify LED State  Off

Verify Chassis Identify Off And Force Identify On via IPMI
    [Documentation]  Verify "chassis identify" off
    ...  and "force identify on" via IPMI.
    [Tags]  Verify_Chassis_Identify_Off_And_Force_Identify_On_via_IPMI

    # Set the LED to "Force Identify On".
    Run IPMI Standard Command  chassis identify force
    Verify Identify LED State  Blink

    # Set "chassis identify" to 0 and verify that the LED turns off.
    Run IPMI Standard Command  chassis identify 0
    Verify Identify LED State  Off

*** Keywords ***

Verify Identify LED State
    [Documentation]  Verify the identify LED state matches caller's expectations.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state  The LED state expected by the caller ("Blink" or "Off").

    ${resp}=  Read Attribute  ${LED_PHYSICAL_URI}/front_id  State
    Should Be Equal  ${resp}  xyz.openbmc_project.Led.Physical.Action.${expected_state}
    ...  msg=Command failure: Unexpected LED state.

    ${resp}=  Read Attribute  ${LED_PHYSICAL_URI}/rear_id  State
    Should Be Equal  ${resp}  xyz.openbmc_project.Led.Physical.Action.${expected_state}
    ...  msg=Command failure: Unexpected LED state.

