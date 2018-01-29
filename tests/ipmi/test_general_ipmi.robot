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

Verify Watchdog Reset Via IPMI And Verify Using REST
    [Documentation]  Verify watchdog reset via IPMI and verify using REST.
    [Tags]  Verify_Watchdog_Reset_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    # Setting the Enabled bit to 1
    Set Watchdog Enabled Using REST  ${1}

    # Check watchdog exists
    Watchdog Object Should Exist

    # Resetting the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog reset

    # Verify the watchdog is reset using REST.
    ${watchdog_timeremaining}=
    ...  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be True  ${watchdog_timeremaining}>0
    ...  msg=Watchdog is not reset properly

Verify Watchdog Off Via IPMI And Verify Using REST
    [Documentation]  Verify Watchdog Off Via IPMI And Verify Using REST
    [Tags]  Verify_Watchdog_Off_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    # Setting the Enabled bit to 1
    Set Watchdog Enabled Using REST  ${1}

    # Check watchdog exists
    Watchdog Object Should Exist

    # Turn off the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog off

    # Verify the watchdog is off using REST
    ${watchdog_off}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal  ${watchdog_off}  ${0}

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

Set Watchdog Enabled Using REST
    [Documentation]  Set watchdog Enabled field using REST.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  Watchdog setting value

    ${valueDict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}/attr/Enabled
    ...       data=${valueDict}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Watchdog Object Should Exist
    [Documentation]  Check if watchdog object exists.

    ${resp}=  OpenBMC Get Request  ${WATCHDOG_URI}host0
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
