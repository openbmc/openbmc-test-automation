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

Verify Get And Set Management Controller ID String
    [Documentation]  Verify get and set management controller ID string.
    [Tags]  Verify_Get_And_Set_Management_Controller_ID_String

    # Get the value of the managemment controller ID string.
    # Example:
    # Get Management Controller Identifier String: witherspoon

    ${get_mc_id_string}=  Run IPMI Standard Command  dcmi get_mc_id_string
    ...  msg=Command failed: dcmi get_mc_id_string

    # Fetch the value of the string.
    ${fetch_value}=  Fetch From Right  ${get_mc_id_string}  :${SPACE}

    # Set the management controller ID string to other value.
    ${set_mc_id_string}=  Run IPMI Standard Command
    ...  dcmi set_mc_id_string HOST
    Should Contain  ${set_mc_id_string}  HOST
    ...  msg=HOST is not displayed.

    # Set the value back to the initial value and verify.
    ${setback_mc_id_string}=  Run IPMI Standard Command
    ...  dcmi set_mc_id_string ${fetch_value}
    ${set_get_mc_id_string}=  Run IPMI Standard Command  dcmi get_mc_id_string
    Should Contain  ${set_get_mc_id_string}  ${fetch_value}
    ...  msg=Initial value is not displayed.

*** Keywords ***
