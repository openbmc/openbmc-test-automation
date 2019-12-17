*** Settings ***
[Documentation]  Bios reset through redfish and verify that boot settings
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot

*** Variables ***
${override_enabled}          Once
${override_target}           BiosSetup
${default_override_target}   None

*** Test Cases **

Verify Bios Reset Via Redfish
    [Documentation]  Do bios reset through redfish and verify that
    ...              boot setting are set to default 'None' after reset.
    [Tags]  Verify_System_Reset_Via_Redfish

    Redfish.Login
    ${data}=  Create Dictionary  BootSourceOverrideEnabled=${override_enabled}
    ...  BootSourceOverrideTarget=${override_target}
    ${payload}=  Create Dictionary  Boot=${data}

    # Set boot mode as 'Once' and target as 'BiosSetup'.
    Redfish.Patch  /redfish/v1/Systems/system  body=&{payload}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    ${resp}=  Redfish.Get  /redfish/v1/Systems/system
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideEnabled"]}
    ...  ${override_enabled}
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideTarget"]}
    ...  ${override_target}

    Reset Bios Via Redfish

    # Verify boot settings after bios reset.
    ${resp}=  Redfish.Get  /redfish/v1/Systems/system
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideEnabled"]}
    ...  Disabled
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideTarget"]}
    ...  None
