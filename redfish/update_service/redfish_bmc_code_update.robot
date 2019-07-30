*** Settings ***
Documentation     Update the BMC code on a target BMC via Redifsh.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/common_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/dump_utils.robot
Resource          ../../lib/logging_utils.robot
Library           ../../lib/gen_robot_valid.py

Suite Setup       Suite Setup Execution
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail

Force Tags   BMC_Code_Update

*** Variables ***
${immediate}      Immediate
${onreset}        OnReset

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via redfish.
    [Tags]  Redfish_BMC_Code_Update

    Set ApplyTime  policy=${onreset}

    ${base_redfish_uri}=  Set Variable  ${REDFISH_BASE_URI}UpdateService

    Redfish Upload Image  ${base_redfish_uri}  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State  match_state='Disabled', 'Updating'  image_id=${image_id}

    # Wait a few seconds to check if the update progress started.
    Sleep  5s
    Check Image Update Progress State  match_state='Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  5 min  20 sec
    ...  Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}

    Redfish OBMC Reboot (off)
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    # Delete BMC dump and Error logs
    Delete All BMC Dump
    Redfish Purge Event Log

    Redfish.Login
    # Checking for file existence.
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}

