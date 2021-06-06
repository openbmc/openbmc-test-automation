*** Settings ***
Documentation    Utilities for redfish BIOS attribute operations.

Resource         resource.robot
Resource         bmc_redfish_resource.robot
Resource         common_utils.robot


*** Keywords ***

Set BIOS Attribute Value And Verify

    [Documentation]  Set BIOS attribute handle with attribute value and verify.
    [Arguments]      ${attr_handle}  ${attr_val}  ${verify}=${True}

    # Description of argument(s):
    # ${attr_handle}    BIOS Attribute handle (e.g. 'vmi_if0_ipv4_method').
    # @{attr_val}       Attribute value for the given attribute handle.
    # ${verify}         Verify the new value.


    ${type_int}=    Evaluate  isinstance($attr_val, int)
    ${value}=  Set Variable If  '${type_int}' == '${True}'  ${attr_val}  '${attr_val}'

    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body={"Attributes":{"${attr_handle}": ${value}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Run Keyword If  '${verify}' == '${True}'  Verify BIOS Attribute  ${attr_handle}  ${attr_val}


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


Verify BIOS Attribute

    [Documentation]  Verify BIOS attribute value.
    [Arguments]  ${attr_handle}  ${attr_val}

    # Description of argument(s):
    # ${attr_handle}    BIOS Attribute handle (e.g. 'vmi_if0_ipv4_method').
    # ${attr_val}       The expected value for the given attribute handle.

    ${output}=  Redfish.Get Attribute  ${BIOS_ATTR_URI}  Attributes
    Should Be Equal  ${output['${attr_handle}']}  ${attr_val}
