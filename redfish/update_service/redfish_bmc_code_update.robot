*** Settings ***
Documentation     Update the BMC code on a target BMC via Redifsh.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/common_utils.robot
Resource          ../../lib/code_update_utils.robot
Library           ../../lib/gen_robot_valid.py

Suite Setup       Suite Setup Execution
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail

*** Variables ***
${immediate}      Immediate
${onreset}        OnReset

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via redfish.
    [Tags]  Redfish_BMC_Code_Update

    Redfish Set Apply Time  ${onreset}
    ${base_redfish_uri}=  Set Variable  ${REDFISH_BASE_URI}UpdateService

    # Checking for file existence.
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}

    Redfish Upload Image  ${base_redfish_uri}  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State  match_state='Disabled', 'Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  5 min  20 sec
    ...  Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}

    Redfish OBMC Reboot (off)
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login

Redfish Set Apply Time
    [Documentation]  Set apply time.
    [Arguments]  ${apply_time}

    # Description of arguments(s):
    # apply_time  Apply time attribute value
    #             ("OnReset", "Immediate").

    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService  body={'ApplyTime' : '${apply_time}'}

