*** Settings ***
Documentation  This suite tests boot setting after bios reset operation through redfish.

Resource              ../../lib/bmc_redfish_utils.robot
Resource              ../../lib/openbmc_ffdc.robot

Suite Setup           Redfish.Login
Suite Teardown        Redfish.Logout
Test Teardown         FFDC On Test Case Fail

*** Variables ***

${default_override_target}    None
${default_override_enabled}   Disabled

*** Test Cases **

Verify Boot Setting After BIOS Reset
    [Documentation]  Do BIOS reset through redfish and verify that
    ...  boot setting is set to default 'None' after reset.
    [Tags]  Verify_System_Reset_Via_Redfish

    ${data}=  Create Dictionary  BootSourceOverrideEnabled=Once
    ...  BootSourceOverrideTarget=BiosSetup
    ${payload}=  Create Dictionary  Boot=${data}

    # Set boot mode as 'Once' and target as 'BiosSetup'.
    Redfish.Patch  /redfish/v1/Systems/system  body=&{payload}
    ...  valid_status_codes=[${HTTP_NO_CONTENT}]

    Reset BIOS Via Redfish

    # Verify boot settings after BIOS reset.
    ${resp}=  Redfish.Get  /redfish/v1/Systems/system
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideEnabled"]}
    ...  ${default_override_enabled}
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideTarget"]}
    ...  ${default_override_target}
