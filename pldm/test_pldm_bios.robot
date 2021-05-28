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


*** Keywords ***

PLDM BIOS Suite Setup

    [Documentation]  Perform PLDM BIOS suite setup.

    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    Set Global Variable  ${attr_table_data}  ${pldm_output}


PLDM BIOS Suite Cleanup

    [Documentation]  Perform PLDM BIOS suite cleanup.

    ${result}=  Get Current Date  UTC  exclude_millis=True
    ${current_date_time}=  Evaluate  re.sub(r'-* *:*', "", '${result}')  modules=re
    ${cmd_set_date_time}=  Evaluate  $CMD_SETDATETIME % '${current_date_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date_time}
    Valid Value  pldm_output['Response']  ['SUCCESS']
