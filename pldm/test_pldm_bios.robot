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
Suite Teardown   Run Keyword And Ignore Error  PLDM BIOS Suite Cleanup

Force Tags       Pldm_Bios

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

    ${bmc_date}=  Get Current Date from BMC
    # Date format example: 2022-10-12 16:31:17
    Log To Console  BMC Date: ${bmc_date}
    # Example : ['2022-10-12', '16:31:17']
    @{current_time}=  Split String  ${bmc_date}  ${EMPTY}

    # verify date matching pldmtool vs BMC current time.
    Should Contain  ${current_time}  ${date_time[0]}


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

    Set Time To Manual Mode

    Sleep  10s


PLDM BIOS Suite Cleanup
    [Documentation]  Perform PLDM BIOS suite cleanup.

    ${result}=  Get Current Date  UTC  exclude_millis=True
    ${current_date_time}=  Evaluate  re.sub(r'-* *:*', "", '${result}')  modules=re
    ${cmd_set_date_time}=  Evaluate  $CMD_SETDATETIME % '${current_date_time}'
    ${pldm_output}=  Pldmtool  ${cmd_set_date_time}
    Valid Value  pldm_output['Response']  ['SUCCESS']


Set Time To Manual Mode
    [Documentation]  Set date time to manual mode via Redfish.

    Redfish.Login
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Get Current Date from BMC
    [Documentation]  Runs the date command from BMC and returns current date and time.

    # Get Current Date from BMC.
    ${date}  ${stderr}  ${rc}=  BMC Execute Command   date

    # Split the string and remove first and 2nd last value from the list and
    # join to form %d %b %H:%M:%S %Y date format
    ${date}=  Split String  ${date}
    Remove From List  ${date}  0
    Remove From List  ${date}  -2
    ${date}=  Evaluate  " ".join(${date})

    # Convert the date format to %Y/%m/%d %H:%M:%S
    ${date}=  Convert Date  ${date}  date_format=%b %d %H:%M:%S %Y
    ...  result_format=%Y-%m-%d %H:%M:%S  exclude_millis=True

    [Return]   ${date}
