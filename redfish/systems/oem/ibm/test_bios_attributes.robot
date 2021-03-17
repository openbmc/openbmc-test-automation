*** Settings ***
Documentation    This suite test various BIOS attributes using Redfish.

Resource         ../../../../lib/resource.robot
Resource         ../../../../lib/bmc_redfish_resource.robot
Resource         ../../../../lib/common_utils.robot
Resource         ../../../../lib/openbmc_ffdc.robot
Resource         ../../../../lib/oem/ibm/bios_attr_utils.robot
Library          ../../../../lib/pldm_utils.py
Variables        ../../../../data/pldm_variables.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Test Cases ***


Validate Get And Update BIOS Attributes Optional Values


    [Documentation]  Validate get and update BIOS attribute optional values
    ...              and set back to original BIOS attribute values using Redfish.
    [Tags]  Validate_Get_And_Update_BIOS_Attributes_Optional_Values

    # Fetch BIOS attribute values using Redfish.
    ${bios_attr_data}=  Redfish.Get Attribute  ${BIOS_ATTR_URI}  Attributes

    # Example:
    # "Attributes": {"vmi_if0_ipv4_method": "IPv4Static"}

    # Fetch BIOS attribute optional values from pldmtool getbiostable.
    ${pldm_output}=  Pldmtool  bios GetBIOSTable --type AttributeTable
    ${attr_val_data}=  GenerateBIOSAttrHandleValueDict  ${pldm_output}
    @{attr_handles}=  Get Dictionary Keys  ${attr_val_data}

    # Example:
    # {'vmi_if0_ipv4_method': ['IPv4Static', 'IPv4DHCP']}

    # Update multiple attribute values for corresponding attribute handle.
    FOR  ${i}  IN  @{attr_handles}

        @{attr_val_list}=  Set Variable  ${attr_val_data}[${i}]
        Set Optional BIOS Attribute Values And Verify  ${i}  @{attr_val_list}

        # Set back to original BIOS attribute handle value.
        Set BIOS Attribute Value And Verify  ${i}  ${bios_attr_data['${i}']}

    END

*** Keywords ***


Test Setup Execution


    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution


    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout
