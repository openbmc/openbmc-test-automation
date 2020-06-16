*** Settings ***
Documentation    This suite test various boot types with boot source.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Teardown   Suite Teardown Execution

*** Variables ***
# Maps for correlating redfish data values to IPMI data values.
# The redfish values are obtained with Redfish.Get or Redfish.Get Properties.
# The corresponding IPMI values are obtained with the "chassis bootparam get
# 5" IPMI command.

# This dictionary maps the redfish 'BootSourceOverrideEnabled' value to the
# corresponding IPMI output value.
&{redfish_ipmi_enabled_map}  Once=Options apply to only next boot
...                          Continuous=Options apply to all future boots
...                          Disabled=Options apply to all future boots

# This dictionary maps the redfish 'BootSourceOverrideTarget' value to the
# corresponding IPMI output value.
&{redfish_ipmi_target_map}  Hdd=Force Boot from default Hard-Drive
...                         Pxe=Force PXE
...                         Diags=Force Boot from default Hard-Drive, request Safe-Mode
...                         Cd=Force Boot from CD/DVD
...                         BiosSetup=Force Boot into BIOS Setup
...                         None=No override

*** Test Cases ***

Verify BMC Redfish Boot Types With BootSource As Once
    [Documentation]  Verify BMC Redfish Boot Types With BootSource As Once.
    [Tags]           Verify_BMC_Redfish_Boot_Types_With_BootSource_As_Once
    [Template]  Set And Verify BootSource And BootType

    #BootSourceEnableType    BootTargetType
    Once                     Hdd
    Once                     Pxe
    Once                     Diags
    Once                     Cd
    Once                     BiosSetup

Verify BMC Redfish Boot Types With BootSource As Continuous
    [Documentation]  Verify BMC Redfish Boot Types With BootSource As Continuous.
    [Tags]           Verify_BMC_Redfish_Boot_Types_With_BootSource_As_Continuous
    [Template]  Set And Verify BootSource And BootType

    #BootSourceEnable    BootTargetType
    Continuous           Hdd
    Continuous           Pxe
    Continuous           Diags
    Continuous           Cd
    Continuous           BiosSetup

*** Keywords ***

Set And Verify BootSource And BootType
    [Documentation]  Set And Verify BootSource And BootType.
    [Arguments]      ${override_enabled}  ${override_target}

    # Description of argument(s):
    # override_enabled    Boot source enable type.
    #                     ('Once', 'Continuous', 'Disabled').
    # override_target     Boot target type.
    #                     ('Pxe', 'Cd', 'Hdd', 'Diags', 'BiosSetup', 'None').

    # Example:
    # "Boot": {
    # "BootSourceOverrideEnabled": "Disabled",
    # "BootSourceOverrideMode": "Legacy",
    # "BootSourceOverrideTarget": "None",
    # "BootSourceOverrideTarget@Redfish.AllowableValues": [
    # "None",
    # "Pxe",
    # "Hdd",
    # "Cd",
    # "Diags",
    # "BiosSetup"]}

    # The values set using Redfish are verified via IPMI using the command:
    # chassis bootparam get 5
    # Option 5 returns the boot parameters.
    #
    # Sample output:
    # Boot parameter version: 1
    # Boot parameter 5 is valid/unlocked
    # Boot parameter data: c000000000
    # Boot Flags :
    # - Boot Flag Valid
    # - Options apply to all future boots
    # - BIOS PC Compatible (legacy) boot
    # - Boot Device Selector : No override
    # - Console Redirection control : System Default
    # - BIOS verbosity : Console redirection occurs per BIOS configuration
    #   setting (default)
    # - BIOS Mux Control Override : BIOS uses recommended setting of the mux at
    #   the end of POST

    Redfish Set Boot Default  ${override_enabled}  ${override_target}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  ${redfish_ipmi_enabled_map['${override_enabled}']}
    Should Contain  ${output}  ${redfish_ipmi_target_map['${override_target}']}

Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Login
    Set And Verify BootSource And BootType  Disabled  None
    Redfish.Logout


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout
