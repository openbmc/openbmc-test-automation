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

Test Tags       Boot_Devices

*** Variables ***
# Maps for correlating redfish data values to IPMI data values.
# The redfish values are obtained with Redfish.Get or Redfish.Get Properties.
# The corresponding IPMI values are obtained with the "chassis bootparam get
# 5" IPMI command.

# This dictionary maps the redfish 'BootSourceOverrideEnabled' value to the
# corresponding IPMI output value.
&{redfish_ipmi_enabled_map}  Once=Options apply to only next boot
...                          Continuous=Options apply to all future boots
...                          Disabled=Boot Flag Invalid

# This dictionary maps the redfish 'BootSourceOverrideTarget' value to the
# corresponding IPMI output value.
&{redfish_ipmi_target_map}  Hdd=Force Boot from default Hard-Drive
...                         Pxe=Force PXE
...                         Diags=Force Boot from default Hard-Drive, request Safe-Mode
...                         Cd=Force Boot from CD/DVD
...                         BiosSetup=Force Boot into BIOS Setup
...                         None=No override

# This dictionary maps the redfish 'BootSourceOverrideMode' value to the
# corresponding IPMI output value.
&{redfish_ipmi_mode_map}  Legacy=BIOS PC Compatible (legacy) boot
...                       UEFI=BIOS EFI boot

${loop_count}             2

*** Test Cases ***

Verify BMC Redfish Boot Source Override with Enabled Mode As Once
    [Documentation]  Verify BMC Redfish Boot Source Override with Enabled Mode As Once.
    [Tags]           Verify_BMC_Redfish_Boot_Source_Override_with_Enabled_Mode_As_Once
    [Template]  Set And Verify Boot Source Override

    #BootSourceOverrideEnabled    BootSourceOverrideTarget    BootSourceOverrideMode
    Once                          Hdd                         UEFI
    Once                          Pxe                         UEFI
    Once                          Diags                       UEFI
    Once                          Cd                          UEFI
    Once                          BiosSetup                   UEFI
    Once                          None                        UEFI
    Once                          Hdd                         Legacy
    Once                          Pxe                         Legacy
    Once                          Diags                       Legacy
    Once                          Cd                          Legacy
    Once                          BiosSetup                   Legacy
    Once                          None                        Legacy


Verify BMC Redfish Boot Source Override with Enabled Mode As Continuous
    [Documentation]  Verify BMC Redfish Boot Source Override with Enabled Mode As Continuous.
    [Tags]           Verify_BMC_Redfish_Boot_Source_Override_with_Enabled_Mode_As_Continuous
    [Template]  Set And Verify Boot Source Override

    #BootSourceOverrideEnabled    BootSourceOverrideTarget    BootSourceOverrideMode
    Continuous                    Hdd                         UEFI
    Continuous                    Pxe                         UEFI
    Continuous                    Diags                       UEFI
    Continuous                    Cd                          UEFI
    Continuous                    BiosSetup                   UEFI
    Continuous                    None                        UEFI
    Continuous                    Hdd                         Legacy
    Continuous                    Pxe                         Legacy
    Continuous                    Diags                       Legacy
    Continuous                    Cd                          Legacy
    Continuous                    BiosSetup                   Legacy
    Continuous                    None                        Legacy


Verify BMC Redfish Boot Source Override with Enabled Mode As Disabled
    [Documentation]  Verify BMC Redfish Boot Source Override with Enabled Mode As Disabled.
    [Tags]           Verify_BMC_Redfish_Boot_Source_Override_with_Enabled_Mode_As_Disabled
    [Template]  Set And Verify Boot Source Override

    #BootSourceOverrideEnabled    BootSourceOverrideTarget    BootSourceOverrideMode
    Disabled                      Hdd                         UEFI
    Disabled                      Pxe                         UEFI
    Disabled                      Diags                       UEFI
    Disabled                      Cd                          UEFI
    Disabled                      BiosSetup                   UEFI
    Disabled                      None                        UEFI
    Disabled                      Hdd                         Legacy
    Disabled                      Pxe                         Legacy
    Disabled                      Diags                       Legacy
    Disabled                      Cd                          Legacy
    Disabled                      BiosSetup                   Legacy
    Disabled                      None                        Legacy


Verify Boot Source Override Policy Persistency With Enabled Mode As Once After BMC Reboot
    [Documentation]  Verify Boot Source Override Policy Persistency with Enabled Mode As Once After BMC Reboot.
    [Tags]           Verify_Boot_Source_Override_Policy_Persistency_With_Enabled_Mode_As_Once_After_BMC_Reboot
    [Template]  Verify Boot Source Override After BMC Reboot

    #BootSourceOverrideEnabled    BootSourceOverrideTarget    BootSourceOverrideMode
    Once                          Hdd                         UEFI
    Once                          Pxe                         UEFI
    Once                          Diags                       UEFI
    Once                          Cd                          UEFI
    Once                          BiosSetup                   UEFI
    Once                          None                        UEFI
    Once                          Hdd                         Legacy
    Once                          Pxe                         Legacy
    Once                          Diags                       Legacy
    Once                          Cd                          Legacy
    Once                          BiosSetup                   Legacy
    Once                          None                        Legacy


Verify Boot Source Override Policy Persistency With Enabled Mode As Continuous After BMC Reboot
    [Documentation]  Verify Boot Source Override Policy Persistency with Enabled Mode As Continuous After BMC Reboot.
    [Tags]           Verify_Boot_Source_Override_Policy_Persistency_With_Enabled_Mode_As_Continuous_After_BMC_Reboot
    [Template]  Verify Boot Source Override After BMC Reboot

    #BootSourceOverrideEnabled    BootSourceOverrideTarget    BootSourceOverrideMode
    Continuous                    Hdd                         UEFI
    Continuous                    Pxe                         UEFI
    Continuous                    Diags                       UEFI
    Continuous                    Cd                          UEFI
    Continuous                    BiosSetup                   UEFI
    Continuous                    None                        UEFI
    Continuous                    Hdd                         Legacy
    Continuous                    Pxe                         Legacy
    Continuous                    Diags                       Legacy
    Continuous                    Cd                          Legacy
    Continuous                    BiosSetup                   Legacy
    Continuous                    None                        Legacy


Verify Boot Source Override Policy With Enabled Mode As Once After Host Reboot
    [Documentation]  Verify Boot Source Override Policy with Enabled Mode As Once After Host Reboot.
    [Tags]           Verify_Boot_Source_Override_Policy_With_Enabled_Mode_As_Once_After_Host_Reboot
    [Template]  Verify Boot Source Override with Enabled Mode As Once After Host Reboot

    #BootSourceOverrideTarget    BootSourceOverrideMode
    Hdd                         UEFI
    Pxe                         UEFI
    Diags                       UEFI
    Cd                          UEFI
    None                        UEFI
    Hdd                         Legacy
    Pxe                         Legacy
    Diags                       Legacy
    Cd                          Legacy
    None                        Legacy


Verify Boot Source Override Policy With Enabled Mode As Continuous After Host Reboot
    [Documentation]  Verify Boot Source Override Policy With Enabled Mode As Continuous After Host Reboot.
    [Tags]           Verify_Boot_Source_Override_Policy_With_Enabled_Mode_As_Continuous_After_Host_Reboot
    [Template]  Verify Boot Source Override with Enabled Mode As Continuous After Host Reboot

    #BootSourceOverrideTarget    BootSourceOverrideMode
    Hdd                         UEFI
    Pxe                         UEFI
    Diags                       UEFI
    Cd                          UEFI
    None                        UEFI
    Hdd                         Legacy
    Pxe                         Legacy
    Diags                       Legacy
    Cd                          Legacy
    None                        Legacy


Verify Boot Source Override With Enabled Mode As Once After Host Reboot For Bios Setup
    [Documentation]  Verify Boot Source Override with Enabled Mode As Once After Host Reboot For Bios Setup.
    [Tags]           Verify_Boot_Source_Override_With_Enabled_Mode_As_Once_After_Host_Reboot_For_Bios_Setup
    [Template]  Verify Boot Source Override with Enabled Mode As Once After Host Reboot

    #BootSourceOverrideTarget   BootSourceOverrideMode   Biosflag
    BiosSetup                   UEFI                     True
    BiosSetup                   Legacy                   True


Verify Boot Source Override With Enabled Mode As Continuous After Host Reboot For Bios Setup
    [Documentation]  Verify Boot Source Override with Enabled Mode As Continuous After Host Reboot For Bios Setup.
    [Tags]           Verify_Boot_Source_Override_With_Enabled_Mode_As_Continuous_After_Host_Reboot_For_Bios_Setup
    [Template]  Verify Boot Source Override with Enabled Mode As Continuous After Host Reboot

    #BootSourceOverrideTarget   BootSourceOverrideMode   Biosflag
    BiosSetup                   UEFI                     True
    BiosSetup                   Legacy                   True


*** Keywords ***

Set And Verify Boot Source Override
    [Documentation]  Set and Verify Boot source override.
    [Arguments]      ${override_enabled}  ${override_target}  ${override_mode}=UEFI

    # Description of argument(s):
    # override_enabled    Boot source override enable type.
    #                     ('Once', 'Continuous', 'Disabled').
    # override_target     Boot source override target.
    #                     ('Pxe', 'Cd', 'Hdd', 'Diags', 'BiosSetup', 'None').
    # override_mode       Boot source override mode (relevant only for x86 arch).
    #                     ('Legacy', 'UEFI').

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

    Redfish Set Boot Default  ${override_enabled}  ${override_target}  ${override_mode}

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  ${redfish_ipmi_enabled_map['${override_enabled}']}
    Should Contain  ${output}  ${redfish_ipmi_target_map['${override_target}']}
    IF  '${PLATFORM_ARCH_TYPE}' == 'x86'
        Should Contain  ${output}  ${redfish_ipmi_mode_map['${override_mode}']}
    END

Verify Boot Source Override After BMC Reboot
    [Documentation]  Verify Boot Source Override After BMC Reboot.
    [Arguments]      ${override_enabled}  ${override_target}  ${override_mode}=UEFI

    # Description of argument(s):
    # override_enabled    Boot source override enable type.
    #                     ('Once', 'Continuous', 'Disabled').
    # override_target     Boot source override target.
    #                     ('Pxe', 'Cd', 'Hdd', 'Diags', 'BiosSetup', 'None').
    # override_mode       Boot source override mode (relevant only for x86 arch).
    #                     ('Legacy', 'UEFI').

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

    Redfish Set Boot Default  ${override_enabled}  ${override_target}  ${override_mode}

    Redfish OBMC Reboot (run)

    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  ${redfish_ipmi_enabled_map['${override_enabled}']}
    Should Contain  ${output}  ${redfish_ipmi_target_map['${override_target}']}
    IF  '${PLATFORM_ARCH_TYPE}' == 'x86'
        Should Contain  ${output}  ${redfish_ipmi_mode_map['${override_mode}']}
    END


Verify Boot Source Override with Enabled Mode As Once After Host Reboot
    [Documentation]  Verify Boot Source Override with Enabled Mode As Once After Host Reboot.
    [Arguments]      ${override_target}  ${override_mode}=UEFI  ${is_bios_setup}=False

    # Description of argument(s):
    # override_enabled    Boot source override enable type.
    #                     ('Once', 'Continuous', 'Disabled').
    # override_target     Boot source override target.
    #                     ('Pxe', 'Cd', 'Hdd', 'Diags', 'BiosSetup', 'None').
    # override_mode       Boot source override mode (relevant only for x86 arch).
    #                     ('Legacy', 'UEFI').

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

    Redfish Set Boot Default  Once  ${override_target}  ${override_mode}

    IF  '${is_bios_setup}' == 'True'
         Repeat Keyword  ${loop_count} times  Host Reboot For Bios Setup
    ELSE
         RF SYS GracefulRestart
         ${output}=  Run IPMI Standard Command  chassis bootparam get 5
         Should Contain  ${output}  ${redfish_ipmi_enabled_map['Once']}
         Should Contain  ${output}  ${redfish_ipmi_target_map['None']}
         IF  '${PLATFORM_ARCH_TYPE}' == 'x86'
             Should Contain  ${output}  ${redfish_ipmi_mode_map['Legacy']}
         END
    END

    ${resp}=  Redfish.Get Attribute  /redfish/v1/Systems/system  Boot
    Should Be Equal As Strings  ${resp["BootSourceOverrideEnabled"]}  Disabled
    Should Be Equal As Strings  ${resp["BootSourceOverrideTarget"]}  None
    IF  '${PLATFORM_ARCH_TYPE}' == 'x86'
        Should Be Equal As Strings  ${resp["BootSourceOverrideMode"]}  Legacy
    END

Verify Boot Source Override with Enabled Mode As Continuous After Host Reboot
    [Documentation]  Verify Boot Source Override with Enabled Mode As Continuous After Host Reboot.
    [Arguments]      ${override_target}  ${override_mode}=UEFI  ${is_bios_setup}=False

    # Description of argument(s):
    # override_enabled    Boot source override enable type.
    #                     ('Once', 'Continuous', 'Disabled').
    # override_target     Boot source override target.
    #                     ('Pxe', 'Cd', 'Hdd', 'Diags', 'BiosSetup', 'None').
    # override_mode       Boot source override mode (relevant only for x86 arch).
    #                     ('Legacy', 'UEFI').

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

    Redfish Set Boot Default  Continuous  ${override_target}  ${override_mode}

    IF  '${is_bios_setup}' == 'True'
         Repeat Keyword  ${loop_count} times  Host Reboot For Bios Setup
    ELSE
         RF SYS GracefulRestart
         ${output}=  Run IPMI Standard Command  chassis bootparam get 5
         Should Contain  ${output}  ${redfish_ipmi_enabled_map['Continuous']}
         Should Contain  ${output}  ${redfish_ipmi_target_map['${override_target}']}
         IF  '${PLATFORM_ARCH_TYPE}' == 'x86'
             Should Contain  ${output}  ${redfish_ipmi_mode_map['${override_mode}']}
         END
    END

    ${resp}=  Redfish.Get Attribute  /redfish/v1/Systems/system  Boot
    Should Be Equal As Strings  ${resp["BootSourceOverrideEnabled"]}  Continuous
    Should Be Equal As Strings  ${resp["BootSourceOverrideTarget"]}  ${override_target}

    IF  '${PLATFORM_ARCH_TYPE}' == 'x86'
        Should Be Equal As Strings  ${resp["BootSourceOverrideMode"]}  ${override_mode}
    END

Host Reboot For Bios Setup
    [Documentation]  Rebooting Host without checking Host state.

    Redfish Power Operation  GracefulRestart

    Sleep  1min


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Login
    Set And Verify Boot Source Override  Disabled  None  UEFI
    Redfish.Logout


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout
