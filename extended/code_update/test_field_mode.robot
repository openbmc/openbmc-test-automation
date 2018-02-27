*** Settings ***
Documentation       Test BMC field mode.

Variables           ../../data/variables.py
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/rest_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/code_update_utils.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution

Test Teardown       FFDC On Test Case Fail

*** Test Cases ***

Verify Software Field Mode
    [Documentation]  Verify software field mode is set.
    [Tags]  Verify_Software_Field_Mode

    # After running, /xyz/openbmc_project/software should look like this:
    # /xyz/openbmc_project/software
    # {
    #     "FieldModeEnabled": 1,
    #     "associations": [
    #         [
    #             "active",
    #             "software_version",
    #             "/xyz/openbmc_project/software/fcf8e182"
    #         ],
    #         [
    #             "functional",
    #             "functional",
    #             "/xyz/openbmc_project/software/fcf8e182"
    #         ]
    #     ]
    # }

    Enable Field Mode And Verify Unmount


Attempt To Disable Field Mode Via REST And Veify
    [Documentation]  Attempt to disable field mode with REST and verify that
    ...              it remains enabled.
    [Tags]  Attempt_To_Disable_Field_Mode_Via_REST

    # This test case doesn't actually disable field mode. It attempts to, but
    # verifies that the FieldModeEnabled property keeps its value of '1'
    # after trying to set it to '0'. Field mode is disabled in suite teardown.

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

    Disable Field Mode And Verify Unmount
