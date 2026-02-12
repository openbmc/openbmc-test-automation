*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Library                ../lib/ipmi_utils.py


Suite Setup            Suite Setup Execution
Suite Teardown         Suite Teardown Execution
Test Teardown          Test Teardown Execution

Test Tags              IPMI_FRU

*** Variables ***

&{ipmi_redfish_fru_field_map}  product_serial=SerialNumber  product_part_number=PartNumber

*** Test Cases ***

Test FRU Info Of Power Supplies
    [Documentation]  Verify FRU info of power supply via IPMI and Redfish.
    [Tags]  Test_FRU_Info_Of_Power_Supplies

    # IPMI FRU info.
    ${ipmi_fru_component_info}=  Get Component FRU Info  ${COMPONENT_NAME_OF_POWER_SUPPLY}
    ...  ${fru_objs}

    # Redfish FRU info.
    ${redfish_power_details}=  Redfish.Get Members List
    ...  /redfish/v1/Chassis/${CHASSIS_ID}/PowerSubsystem/PowerSupplies
    ${redfish_power_dict}=  Create List
    FOR  ${power_supply}  IN  @{redfish_power_details}
        ${redfish_power_supply_reading}=  Redfish.Get Properties  ${power_supply}
        Append To List  ${redfish_power_dict}  ${redfish_power_supply_reading}
    END
    Verify IPMI And Redfish Subcomponents  ${redfish_power_dict}
    ...  ${ipmi_fru_component_info}

*** Keywords ***

Verify IPMI And Redfish Subcomponents
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
      IF  "${value}" == "${EMPTY}"  BREAK
      FOR  ${ipmi_fru_component}  IN  ${ipmi_fru_component_obj}
        FOR  ${redfish_fru_component}  IN  ${redfish_fru_component_obj}
            IF  '${ipmi_fru_component['product_name']}' == '${redfish_fru_component['Name']}'
                Should Contain  ${redfish_fru_component_obj['${value}']}
                ...  ${ipmi_fru_component_obj['${key}']}  msg=Comparison failed.
            END
        END
      END
    END


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    ${status}  ${fru_objs}=  Run Keyword And Ignore Error  Get Fru Info
    Log To Console  FRU: ${fru_objs}
    Set Suite Variable  ${fru_objs}
    Redfish.Login


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
