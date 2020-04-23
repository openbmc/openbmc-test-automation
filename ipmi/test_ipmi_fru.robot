*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot
Library                ../../lib/ipmi_utils.py
Library                ../../data/model.py


Test Teardown          Test Teardown Execution
Suite Setup            Suite Setup Execution

*** Variables ***
${fru_component}       powersupply
&{ipmi_redfish_fru_field_map}  board_serial=SerialNumber  board_part_number=PartNumber  board_product=Name
${status}              True

*** Test Cases ***

Test FRU Info At Power On
    [Documentation]  Verify FRU info via IPMI and Redfish at power on.
    [Tags]  Test_FRU_Info_At_Power_On

    #IPMI fru info
    ${ipmi_fru_component_info}=  Get Component FRU Info  ${fru_component}
    ...  ${fru_objs}
    ${inventory_uris}=  Read Properties
    ...  ${HOST_INVENTORY_URI}list  quiet=${1}
    ${component_uris}=  Get Matches  ${inventory_uris}
    ...  regexp=^.*[0-9a-z_].${fru_component}\[0-9]*$

    #Redfish fru info
    Redfish.Login
    ${power}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Power
    ${redfish_reading}=  Set Variable  ${power['PowerSupplies']}

    #Verify IPMI and Redfish subcomponent

    ${sub_component_count}=  Get Length  ${redfish_reading}
    ${index}=  Set Variable  ${0}

    FOR  ${redfish_fru_sub_component}  IN  @{redfish_reading}
      ${fru_component_section}=
      ...  Get From List  ${redfish_reading}  ${index}
      ${fru_name}=  Set Variable  ${fru_component_section['MemberId']}
      ${status}=  Run Keyword And Return Status  Should Be Equal
      ...  ${fru_name}  ${fru_component}
      ${ipmi_fru_sub_component}=
      ...  Get From List  ${ipmi_fru_component_info}  ${index}
      ${redfish_fru_sub_component}=
      ...  Get From List  ${redfish_reading}  ${index}
      Compare IPMI And Redfish FRU Component Info  ${ipmi_fru_sub_component}
      ...  ${redfish_fru_sub_component}
      Exit For Loop If  '${status}' == '${True}'
      ${index}=  Evaluate  ${index} + 1
      Exit For Loop If  ${index} >= ${sub_component_count}
    END


*** Keywords ***

Compare IPMI And Redfish FRU Component Info
    [Documentation]  Compare IPMI And Redfish FRU Component data objects.
    [Arguments]  ${ipmi_fru_component_obj}  ${redfish_fru_component_obj}

    # Get key_map from ipmi_redfish_fru_field_map.

    ${key_map}=  Set Variable  ${ipmi_redfish_fru_field_map}
    FOR  ${ipmi_key}  IN  @{ipmi_redfish_fru_field_map.keys()}
      ${redfish_key}=  Set Variable  ${key_map['${ipmi_key}']}
      Log  ${key_map['${ipmi_key}']}
      Log  ${redfish_fru_component_obj['${redfish_key}']}
      Should Contain  ${redfish_fru_component_obj['${redfish_key}']}
      ...  ${ipmi_fru_component_obj['${ipmi_key}']}
      ...  msg=Comparison failed.
    END



Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    ${fru_objs}=  Get Fru Info
    Set Suite Variable  ${fru_objs}


