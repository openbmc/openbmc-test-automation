*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Library                ../lib/ipmi_utils.py


Suite Setup            Suite Setup Execution
Suite Teardown         Suite Teardown Execution
Test Teardown          Test Teardown Execution


*** Variables ***
&{ipmi_redfish_fru_field_map}  board_serial=SerialNumber  board_part_number=PartNumber
...  board_product=Name

*** Test Cases ***

Test FRU Info Of Power Supplies
    [Documentation]  Verify FRU info of power supply via IPMI and Redfish.
    [Tags]  Test_FRU_Info_Of_Power_Supplies

    # IPMI FRU info.
    ${ipmi_fru_component_info}=  Get Component FRU Info  powersupply
    ...  ${fru_objs}

    # Redfish FRU info.
    ${redfish_power_details}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Power
    ${redfish_power_supply_reading}=  Set Variable  ${redfish_power_details['PowerSupplies']}

    Verify IPMI and Redfish subcomponents  ${redfish_power_supply_reading}
    ...  ${ipmi_fru_component_info}

*** Keywords ***

Verify IPMI and Redfish subcomponents
    [Documentation]  Get IPMI And Redfish subcomponents of FRU and verify.
    [Arguments]  ${redfish_fru_info}  ${ipmi_fru_info}

    # Description of argument(s):
    # ${ipmi_fru_info}       IPMI FRU component values.
    # ${redfish_fru_info}    Redfish FRU component values.

    ${sub_component_count}=  Get Length  ${redfish_fru_info}

    # Fetch each subcomponent value of IPMI and Redfish and compare.
    FOR  ${sub_component_index}  IN RANGE  0  ${sub_component_count}
      ${ipmi_fru_sub_component}=
      ...  Get From List  ${ipmi_fru_info}  ${sub_component_index}
      ${redfish_fru_sub_component}=
      ...  Get From List  ${redfish_fru_info}  ${sub_component_index}
      Compare IPMI And Redfish FRU Component  ${ipmi_fru_sub_component}
      ...  ${redfish_fru_sub_component}
    END


Compare IPMI And Redfish FRU Component
    [Documentation]  Compare IPMI And Redfish FRU Component data objects.
    [Arguments]  ${ipmi_fru_component_obj}  ${redfish_fru_component_obj}

    # Description of argument(s):
    # ${ipmi_fru_component_obj}  IPMI FRU component data in dictionary.
    # Example:
    # FRU Device Description : powersupply0 (ID 75)
    # Board Mfg Date        : Sun Dec 31 18:00:00 1995
    # Board Product         : powersupply0
    # Board Serial          : 71G303
    # Board Part Number     : 01KL471
    # ${redfish_fru_component_obj}  Redfish FRU component data in dictionary.
    # Example:
    # "Name": "powersupply0",
    # "PartNumber": "01KL471",
    # "PowerInputWatts": 114.0,
    # "SerialNumber": "71G303",

    # Get key_map from ipmi_redfish_fru_field_map.
    ${key_map}=  Get Dictionary Items   ${ipmi_redfish_fru_field_map}

    FOR    ${key}    ${value}    IN    @{key_map}
      Should Contain  ${redfish_fru_component_obj['${value}']}
      ...  ${ipmi_fru_component_obj['${key}']}
      ...  msg=Comparison failed.
    END


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    ${fru_objs}=  Get Fru Info
    Set Suite Variable  ${fru_objs}
    Redfish.Login


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
