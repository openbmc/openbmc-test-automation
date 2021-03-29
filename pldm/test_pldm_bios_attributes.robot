*** Settings ***

Documentation    Module to test PLDM BIOS attribute types.

Library          Collections
Library          String
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail
Suite Setup      PLDM BIOS Attribute Suite Setup
Suite Teardown   PLDM BIOS Attribute Suite Cleanup


*** Variables ***

${bios_original_data}       ${EMPTY}
${attr_table_data}     ${EMPTY}


*** Test Cases ***

Verify Get BIOS Attribute With Invalid Attribute Name

    [Documentation]  Verify get BIOS attribute with invalid attribute name.
    [Tags]  Verify_Get_BIOS_Attribute_With_Invalid_Attribute_Name

    ${random_attr}=  Generate Random String  8  [LETTERS][NUMBERS]
    ${pldm_output}=  pldmtool  bios GetBIOSAttributeCurrentValueByHandle -a ${random_attr}

    # Example output:
    #
    # pldmtool bios GetBIOSAttributeCurrentValueByHandle -a hjkhkj
    # Can not find the attribute hjkhkj
    #

    Should Contain  ${pldm_output}  Can not find the attribute


Verify Set BIOS Attribute With Invalid Attribute Name

    [Documentation]  Verify set BIOS attribute with invalid attribute name.
    [Tags]  Verify_Set_BIOS_Attribute_With_Invalid_Attribute_Name

    ${random_str}=  Generate Random String  8  [LETTERS][NUMBERS]
    ${pldm_output}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${random_str} -d ${random_str}

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a hjkhkj -d 0
    # Could not find attribute :hjkhkj
    #

    Should Contain  ${pldm_output}  Could not find attribute


Verify Set Invalid Optional Value For BIOS Enumeration Attribute Type

    [Documentation]  Verify set invalid optional value for BIOS enumeration attribute type.
    [Tags]  Verify_Set_Invalid_Optional_Value_For_BIOS_Enumeration_Attribute_Type

    ${attr_val_data}=  GetBIOSEnumAttributeOptionalValues  ${attr_table_data}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    ${enum_attr}=  Evaluate  random.choice(${attr_handles})  modules=random

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a pvm_os_boot_side -d hhhhhj
    # Set Attribute Error: It's not a possible value
    #

    ${pldm_output}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${enum_attr} -d 0
    Should Contain  ${pldm_output}  Set Attribute Error


Verify Set Out Of Range Integer Value For BIOS Integer Attribute Type

    [Documentation]  Verify set out of range integer value for BIOS integer attribute type.
    [Tags]  Verify_Set_Out_Of_Range_Integer_Value_For_BIOS_Integer_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSInteger  ${attr_table_data}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    ${int_attr}=  Evaluate  random.choice(${attr_handles})  modules=random
    ${count}=  Evaluate  ${attr_val_data['${int_attr}']["UpperBound"]} + 5

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_if_count -d 12
    # Response Message Error: rc=0,cc=2
    #

    ${pldm_output}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${int_attr} -d ${count}
    Should Contain  ${pldm_output}  Response Message Error


Verify Set Out Of Range String Value For BIOS String Attribute Type

    [Documentation]  Verify set out of range string value for BIOS string attribute type.
    [Tags]  Verify_Set_Out_Of_Range_String_Value_For_BIOS_String_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSString  ${attr_table_data}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    ${str_attr}=  Evaluate  random.choice(${attr_handles})  modules=random
    ${count}=  Evaluate  ${attr_val_data['${str_attr}']["MaximumStringLength"]} + 5
    ${random_value}=  Generate Random String  ${count}  [LETTERS][NUMBERS]

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_if0_ipv4_ipaddr -d 1234566788999
    # Response Message Error: rc=0,cc=2
    #

    ${pldm_output}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${str_attr} -d ${random_value}
    Should Contain  ${pldm_output}  Response Message Error


Verify Set BIOS String Attribute Type

    [Documentation]  Verify set BIOS string attribute type for various BIOS
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

    [Documentation]  Verify set BIOS integer attribute type for various BIOS
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

    [Documentation]  Verify set BIOS enumeration attribute type for various BIOS
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

    [Documentation]  Restore all BIOS attribute values with its default values and verify.
    [Tags]  Verify_Restore_BIOS_Attribute_Values

    ${bios_default_data}=  GetBIOSAttrDefaultValues  ${attr_table_data}
    Validate Set All BIOS Attributes Values  ${bios_default_data}


*** Keywords ***

PLDM BIOS Attribute Suite Setup

    [Documentation]  Perform PLDM BIOS attribute suite setup.

    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    Set Global Variable  ${attr_table_data}  ${pldm_output}

    ${data}=  GetBIOSAttrOriginalValues  ${pldm_output}
    Set Global Variable  ${bios_original_data}  ${data}


PLDM BIOS Attribute Suite Cleanup

    [Documentation]  Perform PLDM BIOS attribute suite cleanup.

    Validate Set All BIOS Attributes Values  ${bios_original_data}


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
        Should Be Equal  ${value1.strip()}  ${value2.strip()}

    END


Validate Set All BIOS Attributes Values

    [Documentation]  Validate Set BIOS Attributes Values.
    [Arguments]      ${bios_attr_data}

    # Description of argument(s):
    # bios_attr_data  Dictionary containing BIOS attribute name and values.

    @{keys}=  Get Dictionary Keys  ${bios_attr_data}

    FOR  ${key}  IN  @{keys}
        ${pldm_resp}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${key} -d ${bios_attr_data['${key}']}
        Valid Value  pldm_resp['Response']  ['SUCCESS']

        # Compare BIOS attribute values after set operation.
        ${output}=  pldmtool  bios GetBIOSAttributeCurrentValueByHandle -a ${key}
        ${value1}=  Convert To String  ${output["CurrentValue"]}
        ${value2}=  Convert To String  ${bios_attr_data['${key}']}
        ${value2}=  Replace String  ${value2}  "  ${EMPTY}
        Should Be Equal  ${value1.strip()}  ${value2.strip()}
    END
