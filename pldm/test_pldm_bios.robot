*** Settings ***

Documentation    Module to test PLDM BIOS commands.

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

Verify GetDateTime
    [Documentation]  Verify host date & time.
    [Tags]  Verify_GetDateTime

    # Example output:
    # {
    #     "Response": "2020-11-07 07:10:10"
    # }

    ${pldm_output}=  Pldmtool  bios GetDateTime
    @{date_time}=  Split String  ${pldm_output['Response']}  ${SPACE}
    @{time}=  Split String  ${date_time}[1]  :

    # verify date & time.
    ${utc}=  Get Current Date  UTC  exclude_millis=True
    @{current_dmy}=  Split String  ${utc}  ${SPACE}
    @{current_time}=  Split String  ${current_dmy[1]}  :

    # Example output:
    # 2020-11-25 07:34:30

    Should Contain  ${current_dmy[0]}  ${date_time[0]}

Verify SetDateTime
    [Documentation]  Verify set date & time for the host.
    [Tags]  Verify_SetDateTime

    # Example output:
    # {
    #     "Response": "SUCCESS"
    # }

    ${current_date_time}=  Get Current Date  UTC  exclude_millis=True
    # Example output:
    # 2020-11-25 07:34:30

    ${date}=  Add Time To Date  ${current_date_time}  400 days  exclude_millis=True
    ${upgrade_date}=  Evaluate  re.sub(r'-* *:*', "", '${date}')  modules=re

    ${time}=  Add Time To Date  ${current_date_time}  01:01:00  exclude_millis=True
    ${upgrade_time}=  Evaluate  re.sub(r'-* *:*', "", '${time}')  modules=re

    # Set date.
    ${cmd_set_date}=  Evaluate  $CMD_SETDATETIME % '${upgrade_date}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date}
    Valid Value  pldm_output['Response']  ['SUCCESS']

    # Set time.
    ${cmd_set_time}=  Evaluate  $CMD_SETDATETIME % '${upgrade_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_time}

Verify GetBIOSTable For StringTable
    [Documentation]  Verify GetBIOSTable for table type string table.
    [Tags]  Verify_GetBIOSTable_For_StringTable

    # Example pldm_output:
    # [biosstringhandle]:                             BIOSString
    # [0]:                                            Allowed
    # [1]:                                            Disabled
    # [2]:                                            Enabled
    # [3]:                                            Not Allowed
    # [4]:                                            Perm
    # [5]:                                            Temp
    # [6]:                                            pvm_fw_boot_side
    # [7]:                                            pvm_inband_code_update
    # [8]:                                            pvm_os_boot_side
    # [9]:                                            pvm_pcie_error_inject
    # [10]:                                           pvm_surveillance
    # [11]:                                           pvm_system_name
    # [12]:                                           vmi_if_count

    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type StringTable
    @{keys}=  Get Dictionary Keys  ${pldm_output}
    ${string_list}=  Create List
    FOR  ${key}  IN  @{keys}
        Append To List  ${string_list}  ${pldm_output['${key}']}
    END
    Valid List  string_list  required_values=${RESPONSE_LIST_GETBIOSTABLE_ATTRTABLE}


Verify GetBIOSTable For AttributeTable
    [Documentation]  Verify if attribute table content exist for
    ...            GetBIOSTable with table type attribute table.
    [Tags]  Verify_GetBIOSTable_For_AttributeTable

    # Example pldm_output:
    # [pldm_attributetable]:                          True
    # [attributehandle]:                               0
    # [ AttributeNameHandle]:                          20(vmi-if1-ipv4-method)
    # [     attributetype]:                            BIOSStringReadOnly
    # [     StringType]:                               0x01
    # [     minimumstringlength]:                      1
    # [     maximumstringlength]:                      100
    # [     defaultstringlength]:                      15

    ${count}=  Get Length  ${attr_table_data}
    ${attr_list}=  Create List
    FOR  ${i}  IN RANGE  ${count}
        ${data}=  Set Variable  ${attr_table_data}[${i}][AttributeNameHandle]
        ${sub_string}=  Get Substring  ${data}  3  -1
        Append To List  ${attr_list}  ${sub_string}
    END
    Valid List  attr_list  required_values=${RESPONSE_LIST_GETBIOSTABLE_ATTRTABLE}

Verify GetBIOSTable For AttributeValueTable
    [Documentation]  Verify if attribute value table content exist for
    ...              GetBIOSTable with table type attribute value table.
    [Tags]  Verify_GetBIOSTable_For_AttributeValueTable

    # Example pldm_output:
    # [pldm_attributevaluetable]:                     True
    # [attributehandle]:                              0
    # [     attributetype]:                           BIOSStringReadOnly
    # [     currentstringlength]:                     15

    ${count}=  Get Length  ${attr_table_data} 
    ${attr_val_list}=  Create List
    FOR  ${i}  IN RANGE  ${count}
        Append To List  ${attr_val_list}  ${attr_table_data}[${i}][AttributeType]
    END
    Valid List  attr_val_list  required_values=${RESPONSE_LIST_GETBIOSTABLE_ATTRVALTABLE}


Verify GetBIOSAttributeCurrentValueByHandle

    [Documentation]  Verify GetBIOSAttributeCurrentValueByHandle with the
    ...              various BIOS attribute handle and its values.
    [Tags]  Verify_GetBIOSAttributeCurrentValueByHandle

    # Example output:
    #
    # pldmtool bios GetBIOSAttributeCurrentValueByHandle -a pvm_fw_boot_side
    # {
    #     "CurrentValue": "Temp"
    # }

    ${attr_val_data}=  GetBIOSEnumAttributeOptionalValues  ${attr_table_data}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        ${cur_attr}=  Pldmtool  bios GetBIOSAttributeCurrentValueByHandle -a ${i}
        @{attr_val_list}=  Set Variable  ${attr_val_data}[${i}]
        Run Keyword If  '${cur_attr['CurrentValue']}' not in @{attr_val_list}
        ...  Fail  Invalid GetBIOSAttributeCurrentValueByHandle value found.
    END

Verify Set BIOS String Attribute Type

    [Documentation]  Verify set BIOS String attribute type with
    ...              various BIOS attribute handle and its values.
    [Tags]  Verify_Set_BIOS_String_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSString  ${attr_table_data}

    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        ${random_value}=  GetRandomBIOSIntAndStrValues  ${i}  ${attr_val_data['${i}']["MaximumStringLength"]}
        ${attr_val_list}=  Create List
        Append To List  ${attr_val_list}  ${random_value}
        Validate SetBIOSAttributeCurrentValue  ${i}  @{attr_val_list}
    END


Verify Set BIOS Integer Attribute Type

    [Documentation]  Verify set BIOS Integer attribute type with
    ...              various BIOS attribute handle and its values.
    [Tags]  Verify_Set_BIOS_Integer_Attribute_Type

    ${attr_val_data}=  GetBIOSStrAndIntAttributeHandles  BIOSInteger  ${attr_table_data}
    Log To Console  ${attr_val_data}

    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}

    FOR  ${i}  IN  @{attr_handles}
        ${random_value}=  GetRandomBIOSIntAndStrValues  ${i}  ${attr_val_data['${i}']["UpperBound"]}
        ${attr_val_list}=  Create List
        Append To List  ${attr_val_list}  ${random_value}
        Log To Console  ${random_value}
        Log To Console  @{attr_val_list}
        Validate SetBIOSAttributeCurrentValue  ${i}  @{attr_val_list}
    END

Verify Set BIOS Enumeration Attribute Type

    [Documentation]  Verify set BIOS Enumeration attribute type with
    ...              various BIOS attribute handle and its values.
    [Tags]  Verify_SetBIOSAttributeCurrentValue

    # Example output:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_hostname -d BMC
    # {
    #     "Response": "SUCCESS"
    # }

    ${attr_val_data}=  GetBIOSEnumAttributeOptionalValues  ${attr_table_data}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}
    FOR  ${i}  IN  @{attr_handles}
        @{attr_val_list}=  Set Variable  ${attr_val_data}[${i}]
        Validate SetBIOSAttributeCurrentValue  ${i}  @{attr_val_list}
    END

*** Keywords ***

PLDM BIOS Suite Setup

    [Documentation]  Perform pldm BIOS suite setup.

    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    Set Global Variable  ${attr_table_data}  ${pldm_output}

    ${data}=  GetBIOSAttrOriginalValues  ${pldm_output}
    Set Global Variable  ${bios_org_data}  ${data}
    Log To Console  ${bios_org_data}

PLDM BIOS Suite Cleanup

    [Documentation]  Perform pldm BIOS suite cleanup.

    Set Back To Original BIOS Attribute Values  ${bios_org_data}

    ${result}=  Get Current Date  UTC  exclude_millis=True
    ${current_date_time}=  Evaluate  re.sub(r'-* *:*', "", '${result}')  modules=re
    ${cmd_set_date_time}=  Evaluate  $CMD_SETDATETIME % '${current_date_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date_time}
    Valid Value  pldm_output['Response']  ['SUCCESS']

Validate SetBIOSAttributeCurrentValue

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
    END

Set Back To Original BIOS Attribute Values

    [Documentation]  Set back to original BIOS attribute values.
    [Arguments]      ${bios_org_data}

    @{keys}=  Get Dictionary Keys  ${bios_org_data}

    FOR  ${key}  IN  @{keys}
        ${pldm_resp}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${key} -d ${bios_org_data['${key}']}
        Valid Value  pldm_resp['Response']  ['SUCCESS']
    END
