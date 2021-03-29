*** Settings ***

Documentation    Module to test PLDM BIOS attribute types.

Library          Collections
Library          String
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail
Suite Setup      PLDM BIOS Suite Setup
Suite Teardown   PLDM BIOS Suite Cleanup

*** Variables ***

${bios_org_data}=       ${EMPTY}
${attr_table_data}=     ${EMPTY}


*** Test Cases ***

Verify Set BIOS String Attribute Type

    [Documentation]  Verify set BIOS String attribute type for various BIOS
    ...              attribute handle with random values with in the range.
    [Tags]  Verify_Set_BIOS_String_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSString  ${attr_table_data}

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_hostname -d BMC
    # {
    #     "Response": "SUCCESS"
    # }

    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        ${random_value}=  GetRandomBIOSIntAndStrValues  ${i}  ${attr_val_data['${i}']["MaximumStringLength"]}
        ${attr_val_list}=  Create List
        Append To List  ${attr_val_list}  ${random_value}
        Validate Set BIOS Attributes With Optional Values  ${i}  @{attr_val_list}
    END


Verify Set BIOS Integer Attribute Type

    [Documentation]  Verify set BIOS Integer attribute type for various BIOS
    ...              attribute handle with random values with in the range.
    [Tags]  Verify_Set_BIOS_Integer_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSInteger  ${attr_table_data}

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_if_count -d 1
    # {
    #     "Response": "SUCCESS"
    # }

    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}

    FOR  ${i}  IN  @{attr_handles}
        ${random_value}=  GetRandomBIOSIntAndStrValues  ${i}  ${attr_val_data['${i}']["UpperBound"]}
        ${attr_val_list}=  Create List
        Append To List  ${attr_val_list}  ${random_value}
        Validate Set BIOS Attributes With Optional Values  ${i}  @{attr_val_list}
    END

Verify Set BIOS Enumeration Attribute Type

    [Documentation]  Verify set BIOS Enumeration attribute type for various BIOS
    ...              attribute handle with random values with in the range of
    ...              default optional values.
    [Tags]  Verify_BIOS_Enumeration_Attribute_Type

    ${attr_val_data}=  GetBIOSEnumAttributeOptionalValues  ${attr_table_data}

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a pvm_default_os_type -d AIX
    # {
    #     "Response": "SUCCESS"
    # }

    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        @{attr_val_list}=  Set Variable  ${attr_val_data}[${i}]
        Validate Set BIOS Attributes With Optional Values  ${i}  @{attr_val_list}
    END

Verify Restore BIOS Attribute Values

    [Documentation]  Restore all the BIOS attribute values with
    ...              its default values and verify.
    [Tags]  Verify_Restore_BIOS_Attribute_Values

    ${bios_default_data}=  GetBIOSAttrDefaultValues  ${attr_table_data}
    Validate Set All BIOS Attributes Values  ${bios_default_data}


*** Keywords ***

PLDM BIOS Suite Setup

    [Documentation]  Perform pldm BIOS suite setup.

    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    Set Global Variable  ${attr_table_data}  ${pldm_output}

    ${data}=  GetBIOSAttrOriginalValues  ${pldm_output}
    Log To Console  ${data}
    Set Global Variable  ${bios_org_data}  ${data}

PLDM BIOS Suite Cleanup

    [Documentation]  Perform pldm BIOS suite cleanup.

    Validate Set All BIOS Attributes Values  ${bios_org_data}

Validate Set BIOS Attributes With Optional Values

    [Documentation]  Set BIOS attribute with the available attribute handle
    ...              values and revert back to original attribute handle value.
    [Arguments]      ${attr_handle}  @{attr_val_list}

    # Description of argument(s):
    # attr_handle    BIOS attribute handle (e.g. pvm_system_power_off_policy).
    # attr_val_list  List of the attribute values for the given attribute handle
    #                (e.g. ['"Power Off"', '"Stay On"', 'Automatic']).

    FOR  ${j}  IN  @{attr_val_list}
        ${pldm_resp}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${attr_handle} -d ${j}
        Valid Value  pldm_resp['Response']  ['SUCCESS']

        # Compare BIOS attribute values after set operation.
        ${output}=  pldmtool  bios GetBIOSAttributeCurrentValueByHandle -a ${attr_handle}
        ${value1}=  Convert To String  ${output["CurrentValue"]}
        ${value2}=  Convert To String  ${j}
        ${value2}=  Replace String  ${value2}  "  ${EMPTY}
        Should Be Equal  ${value1}  ${value2}

    END


Validate Set All BIOS Attributes Values

    [Documentation]  Validate Set BIOS Attributes Values 
    [Arguments]      ${bios_org_data}

    @{keys}=  Get Dictionary Keys  ${bios_org_data}

    FOR  ${key}  IN  @{keys}
        ${pldm_resp}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${key} -d ${bios_org_data['${key}']}
        Valid Value  pldm_resp['Response']  ['SUCCESS']

        # Compare BIOS attribute values after set operation.
        ${output}=  pldmtool  bios GetBIOSAttributeCurrentValueByHandle -a ${key}
        ${value1}=  Convert To String  ${output["CurrentValue"]}
        ${value2}=  Convert To String  ${bios_org_data['${key}']}
        ${value2}=  Replace String  ${value2}  "  ${EMPTY}
        Should Be Equal  ${value1}  ${value2}
    END
