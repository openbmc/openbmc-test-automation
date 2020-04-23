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
&{ipmi_redfish_fru_field_map}  board_serial=SerialNumber  board_part_number=PartNumber  board_product=Name

*** Test Cases ***

Test FRU Info Power Supplies
    [Documentation]  Verify FRU info via IPMI and Redfish at power on.
    [Tags]  Test_FRU_Info_At_Power_On

    ${fru_component}=  Set Variable  powersupply
    
    # IPMI FRU info.

    ${ipmi_fru_component_info}=  Get Component FRU Info  ${fru_component}
    ...  ${fru_objs}

    # Redfish FRU info.

    ${power}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Power
    ${redfish_reading}=  Set Variable  ${power['PowerSupplies']}

    # Verify IPMI and Redfish subcomponent.

    ${sub_component_count}=  Get Length  ${redfish_reading}
    
    FOR  ${redfish_fru_sub_component}  IN RANGE  0  ${sub_component_count}
      ${fru_component_section}=
      ...  Get From List  ${redfish_reading}  ${redfish_fru_sub_component}
      ${fru_name}=  Set Variable  ${fru_component_section['MemberId']}
      ${status}=  Run Keyword And Return Status  Should Not Be Equal  
      ...  ${fru_name}  ${fru_component}
      ${ipmi_fru_sub_component}=
      ...  Get From List  ${ipmi_fru_component_info}  ${redfish_fru_sub_component}
      ${redfish_fru_sub_component}=
      ...  Get From List  ${redfish_reading}  ${redfish_fru_sub_component}
      Compare IPMI And Redfish FRU Component  ${ipmi_fru_sub_component}
      ...  ${redfish_fru_sub_component}
      Exit For Loop If  '${status}' == True
    END


*** Keywords ***

Compare IPMI And Redfish FRU Component
    [Documentation]  Compare IPMI And Redfish FRU Component data objects.
    [Arguments]  ${ipmi_fru_component_obj}  ${redfish_fru_component_obj}

    # Get key_map from ipmi_redfish_fru_field_map.
    
    ${key_map}=  Get Dictionary Items   ${ipmi_redfish_fru_field_map} 

    FOR    ${key}    ${value}    IN    @{key_map}
      Should Contain  ${redfish_fru_component_obj['${value}']}
      ...  ${ipmi_fru_component_obj['${key}']}
      ...  msg=Comparison failed.
    END


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    ${fru_objs}=  Get Fru Info
    Set Suite Variable  ${fru_objs}
    Redfish.Login

