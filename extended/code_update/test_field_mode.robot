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
    [Documentation]  Enable field mode and check that /usr/local is unmounted.
    [Tags]  Enable_Field_Mode

    ${args}=  Create Dictionary  data=${1}
    Write Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled  data=${args}
    BMC Execute Command  [ ! -d "/usr/local/share" ]


Attempt To Disable Field Mode Via REST
    [Documentation]  Attempt to disable field mode with REST and verify that
    ...              it remains enabled.
    [Tags]  Attempt_To_Disable_Field_Mode_Via_REST

    ${args}=  Create Dictionary  data=${0}
    Write Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled
    ...  verify=${TRUE}  expected_value=${1}  data=${args}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Check that /usr/local is mounted
    BMC Execute Command  [ -d "/usr/local/share" ]


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks.

    # 1. Disable field mode
    # 2. Check that /usr/local is mounted

    BMC Execute Command  /sbin/fw_setenv fieldmode
    BMC Execute Command  /bin/systemctl unmask usr-local.mount
    OBMC Reboot (off)  quiet=${1}
    BMC Execute Command  [ -d "/usr/local/share" ]