*** Settings ***
Documentation     Update the BMC code on a target BMC via Redifsh.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/common_utils.robot
Resource          ../../lib/code_update_utils.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

*** Variables ***
${immediate}  Immediate
${onreset}  OnReset

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via redfish.
    [Tags]  Redfish_BMC_Code_Update

    Redfish Set Apply Time  ${onreset}
    ${base_redfish_uri}=  Set Variable  ${REDFISH_BASE_URI}UpdateService
    Redfish Upload Image  ${IMAGE_FILE_PATH}
    ${image_id}=  Image Id Should Exist
    Rprint Vars  image_id  fmt=terse

    ${update_state}=  Image Update Progress State  image_id=${image_id}
    Should Not Be Equal  Disabled  ${update_state}

    Image Update Progress State  image_id=${image_id}  expect_state=Updating

    Wait Until Keyword Succeeds  5 min  20 sec
    ...  Image Update Progress State  image_id=${image_id}  expect_state=Enabled
    Redfish OBMC Reboot (off)
    Redfish.Login
    Redfish Verify Running BMC Image  ${IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login

Redfish Set Apply Time
    [Documentation]  Set apply time.
    [Arguments]  ${apply_time}

    # Description of arguments(s):
    # apply_time  Apply time attribute value.
    #             (e.g. "OnReset", "Immediate").

    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService  body={'ApplyTime' : '${apply_time}'}

Image Id Should Exist
    [Documentation]  Recent extracted image directory should exist.

    ${image_id}=  Get Latest File  /tmp/images/
    Should Not Be Empty  ${image_id}

    # It could so happen that image extract is in progress, check one of the file
    # needed to be in the extracted directory.
     BMC Execute Command  ls -l /tmp/images/${image_id}/MANIFEST

    [Return]  ${image_id}


Image Update Progress State
    [Documentation]  Firmware update progress state.
    [Arguments]  ${image_id}  ${expect_state}=${EMPTY}

    # Description of argument(s):
    # image_id         Temp image id name.
    # expect_state     Update progress (e.g. "Enabled", "Disabled", "Updating").

    # Example:
    #  "Status": {
    #              "Health": "OK",
    #              "HealthRollup": "OK",
    #              "State": "Enabled"
    #            },
    ${update_status}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Status
    Rprint Vars  update_status  fmt=terse

    Run Keyword If  '${expect_state}' != '${EMPTY}'  Should Be Equal  ${update_status["State"]}  ${expect_state}

    [Return]  ${update_status["State"]}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout

