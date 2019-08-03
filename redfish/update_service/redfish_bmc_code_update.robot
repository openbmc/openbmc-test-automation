*** Settings ***
Documentation     Update the BMC code on a target BMC via Redifsh.

# Test Parameters:
# ${IMAGE_FILE_PATH}    The BMC or Host image file name.
#
# Firmware update states:
#     Enabled  -> Image is installed and either functional or active.
#     Disabled -> Image installation failed or ready for activation.
#     Updating -> Image installation currently in progress.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/common_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/dump_utils.robot
Resource          ../../lib/logging_utils.robot
Resource          ../../lib/redfish_code_update_utils.robot
Library           ../../lib/gen_robot_valid.py
Library           ../../lib/tftp_update_utils.py

Suite Setup       Suite Setup Execution
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail

Force Tags   BMC_Code_Update

*** Variables ***
${immediate}      Immediate
${onreset}        OnReset

*** Test Cases ***

Redfish Code Update With ApplyTime OnReset Policy
    [Documentation]  Firmware image update with OnReset policy and
    ...  verify installation.
    [Tags]  Redfish_Code_Update_With_ApplyTime_OnReset_Policy
    [Template]  Code Update With Apply Time

    # policy
    ${onreset}


Redfish Code Update With ApplyTime Immediate Policy
    [Documentation]  Firmware image update with Immediate policy and
    ...  verify installation.
    [Tags]  Redfish_Code_Update_With_ApplyTime_Immediate_Policy
    [Template]  Code Update With Apply Time

    # policy
    ${immediate}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login

    # Delete BMC dump and Error logs
    Delete All BMC Dump
    Redfish Purge Event Log

    # Checking for file existence.
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}


Code Update With Apply Time
    [Documentation]  Code update with ApplyTime policy and verify installation.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Set ApplyTime  policy=${policy}

    ${base_redfish_uri}=  Set Variable  ${REDFISH_BASE_URI}UpdateService

    Redfish Upload Image  ${base_redfish_uri}  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State
    ...  match_state='Disabled', 'Updating'  image_id=${image_id}

    # Wait a few seconds to check if the update progress started.
    Sleep  5s
    Check Image Update Progress State
    ...  match_state='Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Enabled'  image_id=${image_id}

    Reboot BMC And Verify BMC Image
    ...  ${policy}  start_boot_seconds=${state['epoch_seconds']}


Reboot BMC And Verify BMC Image
    [Documentation]  Reboot or wait for BMC standby post reboot and
    ...  verify installed image is functional.
    [Arguments]  ${policy}  ${start_boot_seconds}

    # Description of argument(s):
    # policy                ApplyTime allowed values (e.g. "OnReset", "Immediate").
    # start_boot_seconds    See 'Wait For Reboot' for details.

    Run Keyword if  'OnReset' == '${policy}'
    ...  Run Keywords
    ...      Redfish OBMC Reboot (off)  AND  Redfish.Login  AND
    ...        Redfish Verify BMC Version  ${IMAGE_FILE_PATH}
    ...  ELSE
    ...    Run Keywords
    ...        Wait For Reboot  start_boot_seconds=${start_boot_seconds}  AND
    ...          Redfish.Login  AND  Redfish Verify BMC Version  ${IMAGE_FILE_PATH}

