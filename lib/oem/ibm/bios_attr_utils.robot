*** Settings ***
Documentation     Utilities for power management tests.

Resource         ../../../../lib/resource.robot
Resource         ../../../../lib/bmc_redfish_resource.robot
Resource         ../../../../lib/common_utils.robot


*** Keywords ***


Set BIOS Attribute Value And Verify


    [Documentation]  Set BIOS attribute handle with attribute value and verify.
    [Arguments]      ${attr_handle}  ${attr_val}

    Redfish.Login
    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${attr_handle}": "${attr_val}"}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # Example:
    #
    # pldmtool bios SetBIOSAttributeCurrentValue -a vmi_if0_ipv4_method -d 1
    # {
    # "Response": "SUCCESS"
    # }

    ${output}=  Redfish.Get Attribute  ${BIOS_ATTR_URI}  Attributes
    Should Be Equal  ${output['${attr_handle}']}  ${attr_val}
    Redfish.Logout


Set Optional BIOS Attribute Values And Verify


    [Documentation]  For the given BIOS attribute handle update with optional
    ...              attribute values and verify.
    [Arguments]  ${attr_handle}  @{attr_val_list}

    # Description of argument(s):
    # ${attr_handle}    BIOS Attribute handle (e.g. 'vmi_if0_ipv4_method').
    # @{attr_val_list}  List of the attribute values for the given attribute handle.
    #                   (e.g. ['IPv4Static', 'IPv4DHCP']).

    FOR  ${attr}  IN  @{attr_val_list}
        ${new_attr}=  Evaluate  $attr.replace('"', '')
        Set BIOS Attribute Value And Verify  ${attr_handle}  ${new_attr}
    END
