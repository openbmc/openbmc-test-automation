*** Settings ***
Documentation          This suite tests IPMI chassis status in Open BMC.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/utils.robot
Resource               ../../lib/boot_utils.robot
Resource               ../../lib/resource.robot
Resource               ../../lib/state_manager.robot

Test Teardown          Test Teardown Execution

*** Test Cases ***

Verify Soft Shutdown via IPMI
    [Documentation]  Verify Host OS shutdown softly using IPMI command.
    [Tags]  Verify_Soft_Shutdown_via_IPMI

    REST Power On  stack_mode=skip
    Run IPMI Standard Command  chassis power soft
    Wait Until Keyword Succeeds  3 min  10 sec  Is Host Off


*** Keywords ***

Test Teardown Execution
    [Documentation]    Log FFDC if test failed.

    Set BMC Power Policy  ${ALWAYS_POWER_OFF}

    FFDC On Test Case Fail
