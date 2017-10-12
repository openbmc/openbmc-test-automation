*** Settings ***

Documentation   This testsuite is for testing boot policy function.

Resource           ../lib/rest_client.robot
Resource           ../lib/ipmi_client.robot
Resource           ../lib/utils.robot
Resource           ../lib/openbmc_ffdc.robot
Resource           ../lib/state_manager.robot
Resource           ../lib/boot_utils.robot

Suite Setup        Test Suite Setup
Test Setup         Test Init Setup
Test Teardown      FFDC On Test Case Fail
Suite Teardown     Restore Boot Settings

Force Tags  boot_policy_test

*** Test Cases ***

Set Boot Policy To ONETIME via REST
    [Documentation]   Set boot policy to ONETIME using REST URI and verify
    ...               using ipmitool.
    [Tags]  Set_Boot_Policy_To_ONETIME_via_REST

    Set Boot Policy To ONETIME
    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${1}
    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Options apply to only next boot

Set Boot Policy To PERMANENT via REST
    [Documentation]   Set boot policy to PERMANENT using REST URI and verify
    ...               using ipmitool.
    [Tags]  Set_Boot_Policy_To_PERMANENT_via_REST

    Set Boot Policy To PERMANENT
    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${0}
    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Options apply to all future boots

Set Boot Policy To ONETIME via IPMITOOL
    [Documentation]   Set boot policy to ONETIME via ipmitool and verify
    ...               using REST URI.
    [Tags]  Set_Boot_Policy_To_ONETIME_via_IPMITOOL

    Run IPMI command  0x0 0x8 0x05 0x80 0x00 0x00 0x00 0x00
    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${1}
    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Options apply to only next boot

Set Boot Policy To PERMANENT via IPMITOOL
    [Documentation]   Set boot policy to PERMANENT via ipmitool and verify
    ...               using REST URI.
    [Tags]  Set_Boot_Policy_To_PERMANENT_via_IPMITOOL

    Run IPMI command   0x0 0x8 0x05 0xC0 0x00 0x00 0x00 0x0
    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${0}
    ${output}=  Run IPMI Standard Command  chassis bootparam get 5
    Should Contain  ${output}  Options apply to all future boots

Test Boot Order via REST
    [Documentation]   Set boot policy to PERMANENT and boot device to CDROM
    ...               and verify that the order doesn't change post power on.
    [Tags]  chassisboot  Test_Boot_Order_via_REST

    Initiate Power Off

    Set Boot Policy To PERMANENT

    Set Boot Source  ${BOOT_SOURCE_CDROM}

    Initiate Host Boot

    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${1}

    ${flag}=   Read Attribute  ${CONTROL_URI}/host0/boot/  BootSource
    Should Be Equal  ${flag}  ${BOOT_SOURCE_CDROM}

Persist ONETIME Boot Policy After Reset
    [Documentation]   Verify ONETIME boot policy order does not change
    ...               on warm reset.
    [Tags]  chassisboot   Persist_ONETIME_Boot_Policy_After_Reset

    Initiate Host Boot

    Set Boot Policy To ONETIME

    Set Boot Source  ${BOOT_SOURCE_NETWORK}

    OBMC Reboot (off)

    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${1}

    ${flag}=   Read Attribute  ${CONTROL_URI}/host0/boot/  BootSource
    Should Be Equal  ${flag}  ${BOOT_SOURCE_NETWORK}

Persist PERMANENT Boot Policy After Reset
    [Documentation]   Verify PERMANENT boot policy order does not change
    ...               on warm reset.
    [Tags]  chassisboot    Persist_PERMANENT_Boot_Policy_After_Reset

    Initiate Host Boot

    Set Boot Policy To PERMANENT

    Set Boot Source  ${BOOT_SOURCE_CDROM}

    OBMC Reboot (off)

    ${boot}=   Read Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled
    Should Be Equal  ${boot}  ${0}

    ${flag}=   Read Attribute  ${CONTROL_URI}/host0/boot/  BootSource
    Should Be Equal  ${flag}  ${BOOT_SOURCE_CDROM}

Verify Boot Mode Persistency After BMC Reboot
    [Documentation]  Verify boot mode persistency after BMC reboot.
    [Tags]  Verify_Boot_Mode_Persistency_After_BMC_Reboot
    [Teardown]  Run Keywords  Restore Bootmode Setting
    ...  AND  FFDC On Test Case Fail

    # Record initial bootmode setting.
    ${boot_mode}=  Read Attribute
    ...  ${CONTROL_HOST_URI}/boot  BootMode
    Set Suite Variable  ${initial_boot_mode}  ${boot_mode}

    # Set bootmode to non default value.
    Set Boot Mode  ${BOOT_MODE_SAFE}

    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready

    ${boot_mode_after}=  Read Attribute
    ...  ${CONTROL_HOST_URI}/boot  BootMode

    Should Be Equal As Strings
    ...  ${boot_mode_after}  ${BOOT_MODE_SAFE}

*** Keywords ***

Set Boot Mode
    [Arguments]    ${args}
    ${bootmode}=  Set Variable   ${args}
    ${valueDict}=  Create Dictionary  data=${bootmode}
    Write Attribute  ${CONTROL_HOST_URI}/boot/  BootMode  data=${valueDict}

Set Boot Policy To ONETIME
    ${valueDict}=  create dictionary  data=${1}
    Write Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled  data=${valueDict}

Set Boot Policy To PERMANENT
    ${valueDict}=  create dictionary  data=${0}
    Write Attribute  ${CONTROL_URI}/host0/boot/one_time  Enabled  data=${valueDict}

Set Boot Source
    [Documentation]  Set given boot source.
    [Arguments]  ${boot_source}
    # Description of argument(s):
    # boot_source  Boot source which need to be set.

    ${valueDict}=  Create Dictionary  data=${boot_source}
    Write Attribute ${CONTROL_HOST_URI}/boot/  BootSource  data=${valueDict}

Restore Boot Settings
    [Documentation]  Restore default settings.
    Set Boot Policy To ONETIME
    Set Boot Source  ${BOOT_SOURCE_DEFAULT}
    Close All Connections

Test Init Setup
    [Documentation]  Do the initial test setup.
    Open Connection And Log In
    Initialize DBUS cmd  "boot_flags"

Test Suite Setup
    [Documentation]  Do the initial suite setup.

    # Reboot host to re-power on clean if host is not "off".
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot
    ...  ELSE  Initiate Host Reboot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is OS Starting

Restore Bootmode Setting
    [Documentation]  Restore initial bootmode setting.

    Set Boot Mode  ${initial_boot_mode}
