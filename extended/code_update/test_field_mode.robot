*** Settings ***
Documentation       Test BMC field mode.

Variables           ../../data/variables.py
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/rest_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution

Test Teardown       FFDC On Test Case Fail

*** Test Cases ***

Enable Field Mode
    [Documentation]  Enable field mode, check that /usr/local is unmounted.
    [Tags]  Enable_Field_Mode

    Write Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled  ${1}
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  [ -d "/usr/local/share" ]  ignore_err=${1}
    Should Be Equal  ${rc}  ${1}


Attempt To Disable Field Mode Via REST
    [Documentation]  Attempt to disable field mode with REST and verify that
    ...              it remains enabled.
    [Tags]  Attempt_To_Disable_Field_Mode_Via_REST

    Write Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled  ${0}
    ${field_mode}=  Read Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled
    Should Be Equal  ${field_mode}  ${1}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Check that /usr/local is mounted
    BMC Execute Command  [ -d "/usr/local/share/uyiytsyudyuf" ]


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks.

    # 1. Disable field mode
    # 2. Check that /usr/local is mounted

    BMC Execute Command  fw_setenv  fieldmode
    BMC Execute Command  systemctl unmask usr-local.mount
    OBMC Reboot (off)  quiet=${1}
    BMC Execute Command  [ -d "/usr/local/share" ]