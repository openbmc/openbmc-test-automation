*** Settings ***
Documentation    This suite test various boot types with boot source.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail
Suite Setup      redfish.Login
Suite Teardown   Suite Teardown Execution 

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
    #                     (e.g. 'Once'/'Continuous'/'Disabled')
    # override_target     Boot target type.
    #                     (e.g. 'Pxe'/'Cd'/'Hdd'/'Diags'/'BiosSetup'/'None')

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

    ${data}=  Create Dictionary  BootSourceOverrideEnabled=${override_enabled}
    ...  BootSourceOverrideTarget=${override_target}
    ${payload}=  Create Dictionary  Boot=${data}

    ${resp}=  redfish.patch  Systems/system  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    ${resp}=  redfish.Get  /redfish/v1/Systems/system
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideEnabled"]}
    ...  ${override_enabled}
    Should Be Equal As Strings  ${resp.dict["Boot"]["BootSourceOverrideTarget"]}
    ...  ${override_target}
    Sleep  30s

Suite Teardown Execution
    [Documentation]  Do the post suite teardown. 

    Set And Verify BootSource And BootType  Disabled  None
    redfish.Logout
