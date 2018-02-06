*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Teardown       FFDC On Test Case Fail

*** Variables ***

${new_mc_id}=  HOST

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

Verify Get And Set Management Controller ID String
    [Documentation]  Verify get and set management controller ID string.
    [Tags]  Verify_Get_And_Set_Management_Controller_ID_String

    # Get the value of the managemment controller ID string.
    # Example:
    # Get Management Controller Identifier String: witherspoon

    ${cmd_output}=  Run IPMI Standard Command  dcmi get_mc_id_string

    # Extract management controller ID from cmd_output.
    ${initial_mc_id}=  Fetch From Right  ${cmd_output}  :${SPACE}

    # Set the management controller ID string to other value.
    # Example:
    # Set Management Controller Identifier String Command: HOST

    Set Management Controller ID String  ${new_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${new_mc_id}

    # Set the value back to the initial value and verify.
    Set Management Controller ID String  ${initial_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${initial_mc_id}

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


Verify Get Device ID
    [Documentation]  Verify get device ID command output.
    [Tags]  Verify_Get_Device_ID

    # Get device command output:
    # Device ID                 : 0
    # Device Revision           : 0
    # Firmware Revision         : 2.01
    # IPMI Version              : 2.0
    # Manufacturer ID           : 42817
    # Manufacturer Name         : Unknown (0xA741)
    # Product ID                : 16975 (0x424f)
    # Product Name              : Unknown (0x424F)
    # Device Available          : yes
    # Provides Device SDRs      : yes
    # Additional Device Support :
    #     Sensor Device
    #     SEL Device
    #     FRU Inventory Device
    #     Chassis Device
    # Aux Firmware Rev Info     :
    #     0x00
    #     0x00
    #     0x00
    #     0x00

    Verify Get Device Command Output  Device ID  0
    Verify Get Device Command Output  Device Revision  0
    Verify Get Device Command Output  IPMI Version  2.0

    # Get major BMC version from BMC cli i.e. 2.1 from "v2.1-51-g04ff12c"
    ${bmc_version}=  Get BMC Version
    ${bmc_version}=  Fetch From Left  ${bmc_version}  -
    ${bmc_version}=  Remove String  ${bmc_version}  "v

    Verify Get Device Command Output  Firmware Revision  ${bmc_version}
    Verify Get Device Command Output  Manufacturer ID  42817
    Verify Get Device Command Output  Product ID  16975
    Verify Get Device Command Output  Device Available  yes
    Verify Get Device Command Output  Provides Device SDRs  yes


*** Keywords ***

Set Management Controller ID String
    [Documentation]  Set the management controller ID string.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID String to be set

    ${set_mc_id_string}=  Run IPMI Standard Command
    ...  dcmi set_mc_id_string ${string}

Get Management Controller ID String And Verify
    [Documentation]  Get the management controller ID sting.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID string

    ${get_mc_id}=  Run IPMI Standard Command  dcmi get_mc_id_string
    Should Contain  ${get_mc_id}  ${string}
    ...  msg=Command failed: get_mc_id.

Verify Identify LED State
    [Documentation]  Verify the identify LED state
    ...  matches caller's expectations.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state  The LED state expected by the caller ("Blink" or "Off").

    ${resp}=  Read Attribute  ${LED_PHYSICAL_URI}/front_id  State
    Should Be Equal  ${resp}  xyz.openbmc_project.Led.Physical.Action.${expected_state}
    ...  msg=Unexpected LED state.

    ${resp}=  Read Attribute  ${LED_PHYSICAL_URI}/rear_id  State
    Should Be Equal  ${resp}  xyz.openbmc_project.Led.Physical.Action.${expected_state}
    ...  msg=Unexpected LED state.

Verify Get Device Command Output
    [Documentation]  Verify get device command output.
    [Arguments]  ${field}  ${expected_value}

    # Description of argument(s):
    # field           field which need to verify.
    # expected_value  expected value which needs to be checked.

    ${cmd_output}=  Run IPMI Standard Command  mc info
    ${field_line}=
    ...  Get Lines Containing String  ${cmd_output}  ${field}
    Should Contain  ${field_line}  ${expected_value}
