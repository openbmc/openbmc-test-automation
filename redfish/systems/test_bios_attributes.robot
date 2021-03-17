*** Settings ***
Documentation    This suite test various BIOS attributes using redfish.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot
Library          ../../lib/pldm_utils.py
Variables        ../../data/pldm_variables.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Suite Teardown Execution

*** Test Cases ***

Validate Get And Update BIOS Attributes Values
    [Documentation]  Validate get and update BIOS attribute values using redfish
    ...              and set back to original BIOS attribute values.
    [Tags]  Validate_Get_And_Update_BIOS_Attributes_Values

    # Fetch BIOS attribute values using redfish.
    ${bios_attr_data}=  Redfish.Get Attribute  ${BIOS_ATTR_URI}  Attributes

    # Example:
    # "Attributes": {"vmi_if0_ipv4_method": "IPv4Static",
    #                 ...
    #                "hb_hyp_switch": "PowerVM"}

    # Fetch BIOS attribute optional values from pldmtool getbiostable.
    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    ${attr_val_data}=  GenerateBIOSAttrHandleValueDict  ${pldm_output}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}

    # Example:
    # {'vmi_if0_ipv4_method': ['IPv4Static', 'IPv4DHCP']
    #  'hb_hyp_switch': ['PowerVM', 'OPAL']}

    # Update multiple attribute values for corresponding attribute handle.
    FOR  ${i}  IN  @{attr_handles}

        @{attr_val_list}=  Set Variable  ${attr_val_data}[${i}]
        Set Multiple BIOS Attribute Values And Verify  ${i}  @{attr_val_list}

        # Set back to original BIOS attribute handle value.
        Set BIOS Attribute Value And Verify  ${i}  ${bios_attr_data['${i}']}
        
    END

*** Keywords ***

Set Multiple BIOS Attribute Values And Verify

    [Documentation]  For the given BIOS attribute handle update with available
    ...              attribute handle values and verify.
    [Arguments]  ${attr_handle}  @{attr_val_list}

    # Description of argument(s):
    # ${attr_handle}    BIOS Attribute handle (e.g. pvm_system_power_off_policy).
    # @{attr_val_list}  List of the attribute values for the given attribute handle.
    #                   (e.g. ['Power Off', 'Stay On', 'Automatic'])

    FOR  ${attr}  IN  @{attr_val_list}
        ${new_attr}=  Evaluate  $attr.replace('"', '')
        Set BIOS Attribute Value And Verify  ${attr_handle}  ${new_attr}
    END

Set BIOS Attribute Value And Verify

    [Documentation]  Set BIOS attribute handle with attribute values and verify.
    [Arguments]      ${attr_handle}  ${attr_val}

    # Example:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_if0_ipv4_prefix_length -d 1
    # {
    # "Response": "SUCCESS"
    # }

    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${attr_handle}": "${attr_val}"}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${output}=  Redfish.Get Attribute  ${BIOS_ATTR_URI}  Attributes
    Should Be Equal  ${output['${attr_handle}']}  ${attr_val}

Suite Teardown Execution

    [Documentation]  Do the post suite teardown.

    Redfish.Logout

Test Setup Execution

    [Documentation]  Do test case setup tasks.

    Redfish.Login

Test Teardown Execution

    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout
