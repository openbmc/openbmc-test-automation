*** Settings ***
Documentation    This suite test various BIOS attributes operations using Redfish.

Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/common_utils.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bios_attr_utils.robot
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py

Test Teardown    FFDC On Test Case Fail

Suite Setup      Redfish BIOS Suite Setup
Suite Teardown   Run Keyword And Ignore Error  Redfish BIOS Suite Cleanup

Test Tags       Redfish_Bios_Attributes

*** Variables ***

${BIOS_ORIGINAL_DATA}       ${EMPTY}
${ATTR_TABLE_DATA}          ${EMPTY}


*** Test Cases ***

Redfish Verify Set BIOS Attribute With Invalid Attribute Name
    [Documentation]  Verify set BIOS attribute with invalid attribute name using
    ...              Redfish.
    [Tags]  Redfish_Verify_Set_BIOS_Attribute_With_Invalid_Attribute_Name

    ${random_str}=  Generate Random String  8  [LETTERS][NUMBERS]
    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${random_str}": '${random_str}'}}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]


Redfish Verify Set Invalid Optional Value For BIOS Enumeration Attribute Type
    [Documentation]  Verify set invalid optional value for BIOS enumeration attribute type
    ...              using Redfish.
    [Tags]  Redfish_Verify_Set_Invalid_Optional_Value_For_BIOS_Enumeration_Attribute_Type

    ${attr_val_data}=  GetBIOSEnumAttributeOptionalValues  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    ${enum_attr}=  Evaluate  random.choice(${attr_handles})  modules=random

    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${enum_attr}": '0'}}
    ...  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR},${HTTP_FORBIDDEN}]


Redfish Verify Set Out Of Range Integer Value For BIOS Integer Attribute Type
    [Documentation]  Verify set out of range integer value for BIOS integer attribute type
    ...              using Redfish.
    [Tags]  Redfish_Verify_Set_Out_Of_Range_Integer_Value_For_BIOS_Integer_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSInteger  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    ${int_attr}=  Evaluate  random.choice(${attr_handles})  modules=random
    ${count}=  Evaluate  ${attr_val_data['${int_attr}']["UpperBound"]} + 5

    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${int_attr}": ${count}}}
    ...  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR},${HTTP_BAD_REQUEST}]


Redfish Verify Set Out Of Range String Value For BIOS String Attribute Type

    [Documentation]  Verify set out of range string value for BIOS string attribute type
    ...              using Redfish.
    [Tags]  Redfish_Verify_Set_Out_Of_Range_String_Value_For_BIOS_String_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSString  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    ${str_attr}=  Evaluate  random.choice(${attr_handles})  modules=random
    ${count}=  Evaluate  ${attr_val_data['${str_attr}']["MaximumStringLength"]} + 5
    ${random_value}=  Generate Random String  ${count}  [LETTERS][NUMBERS]

    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${str_attr}": '${random_value}'}}
    ...  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR},${HTTP_BAD_REQUEST}]


Redfish Verify Set BIOS String Attribute Type
    [Documentation]  Verify set BIOS string attribute type for various BIOS
    ...              attribute handle with random values with in the range using Redfish.
    [Tags]  Redfish_Verify_Set_BIOS_String_Attribute_Type

    @{failed_attr_list}=  Create List

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSString  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        ${random_value}=  GetRandomBIOSIntAndStrValues  ${i}  ${attr_val_data['${i}']["MaximumStringLength"]}
        ${status}=  Run Keyword And Return Status
        ...  Set BIOS Attribute Value And Verify  ${i}  ${random_value}
        IF  ${status} == ${False}  Append To List  ${failed_attr_list}  ${i}
    END

    ${fail_count}=  Get Length  ${failed_attr_list}
    Should Be Equal  ${fail_count}  ${0}
    ...  msg= BIOS write Failed ${fail_count} list: ${failed_attr_list}



Redfish Verify Set BIOS Integer Attribute Type
    [Documentation]  Verify set BIOS integer attribute type for various BIOS
    ...              attribute handle with random values with in the range using Redfish.
    [Tags]  Redfish_Verify_Set_BIOS_Integer_Attribute_Type

    @{failed_attr_list}=  Create List

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSInteger  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        ${random_value}=  GetRandomBIOSIntAndStrValues  ${i}  ${attr_val_data['${i}']["UpperBound"]}
        ${status}=  Run Keyword And Return Status
        ...  Set BIOS Attribute Value And Verify  ${i}  ${random_value}
        IF  ${status} == ${False}  Append To List  ${failed_attr_list}  ${i}
    END

    ${fail_count}=  Get Length  ${failed_attr_list}
    Should Be Equal  ${fail_count}  ${0}
    ...  msg= BIOS write Failed ${fail_count} list: ${failed_attr_list}


Redfish Verify Set BIOS Enumeration Attribute Type
    [Documentation]  Validate get and update BIOS attribute optional values
    ...              and set back to original BIOS attribute values using Redfish.
    [Tags]  Redfish_Verify_Set_BIOS_Enumeration_Attribute_Type

    @{failed_attr_list}=  Create List

    # Fetch BIOS attribute optional values from pldmtool getbiostable.
    ${attr_val_data}=  GetBIOSEnumAttributeOptionalValues  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}

    # Example:
    # {'vmi_if0_ipv4_method': ['IPv4Static', 'IPv4DHCP']}

    # Update multiple attribute values for corresponding attribute handle.
    FOR  ${i}  IN  @{attr_handles}
        @{attr_val_list}=  Set Variable  ${attr_val_data}[${i}]
        ${status}=  Run Keyword And Return Status
        ...  Set Optional BIOS Attribute Values And Verify  ${i}  @{attr_val_list}
        IF  ${status} == ${False}  Append To List  ${failed_attr_list}  ${i}
    END

    ${fail_count}=  Get Length  ${failed_attr_list}
    Should Be Equal  ${fail_count}  ${0}
    ...  msg= BIOS write Failed ${fail_count} list: ${failed_attr_list}


Redfish Verify Restore BIOS Attribute Values
    [Documentation]  Restore all BIOS attribute values with its default values and verify
    ...              using Redfish.
    [Tags]  Redfish_Verify_Restore_BIOS_Attribute_Values

    ${bios_default_data}=  GetBIOSAttrDefaultValues  ${ATTR_TABLE_DATA}
    @{attr_handles}=  Get Dictionary Keys  ${bios_default_data}

    FOR  ${i}  IN  @{attr_handles}
        Set BIOS Attribute Value And Verify  ${i}  ${bios_default_data['${i}']}
    END

*** Keywords ***

Redfish BIOS Suite Setup
    [Documentation]  Perform Redfish BIOS suite setup.

    Redfish.Login
    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    Set Suite Variable  ${ATTR_TABLE_DATA}  ${pldm_output}

    ${data}=  GetBIOSAttrOriginalValues  ${pldm_output}
    Set Suite Variable  ${BIOS_ORIGINAL_DATA}  ${data}


Redfish BIOS Suite Cleanup
    [Documentation]  Perform Redfish BIOS suite cleanup.

    @{attr_handles}=  Get Dictionary Keys  ${BIOS_ORIGINAL_DATA}
    FOR  ${i}  IN  @{attr_handles}
        Set BIOS Attribute Value And Verify  ${i}  ${BIOS_ORIGINAL_DATA['${i}']}
    END
    Redfish.Logout
