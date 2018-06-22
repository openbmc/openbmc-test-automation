*** Settings ***

Documentation  Test Open BMC GUI server configuration firmware update.

Resource        ../../lib/resource.robot
Resource        ../../../../lib/logging_utils.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Logout And Close Browser
Test Setup      Test Setup Execution
Test Teardown   Run Keyword If Test Failed  Re-Launch GUI on Failure

*** Variables ***
${xpath_select_server_config}   //*[@id="nav__top-level"]/li[4]/button
${xpath_select_firmware}        //a[@href='#/configuration/firmware']
${xpath_choose_file_button}     //*[@id="firmware__upload-form"]/div[1]/label/span[1]
${xpath_scroll_down}            //a[@href='/html/body/main/div[2]/p[2]/a']
${xpath_tftp_server_ip}         //*[@id="tftp-ip"]
${xpath_tftp_filename}          //*[@id="tftp-file-name"]
${xpath_download_firmware}      //*[@id="firmware__upload-form"]/div[2]/fieldset/div[1]/div[3]/input
${xpath_download_progress}      //*[@id="firmware__upload-form"]/div[2]/fieldset/div[2]

*** Test Cases ***

Verify Select Firmware From Server Configuration
    [Documentation]  Verify ability to select firmware option from server
    ...  configuration sub-menu.
    [Tags]  Verify_Select_Firmware_From_Server_Configuration

    Wait Until Page Contains  Firmware
    Page Should contain  Manage BMC and server firmware


Verify Scroll Down Link
    [Documentation]  Verify scroll down link works.
    [Tags]  Verify_Scroll_Down_Link

    Page Should Contain Element  ${xpath_scroll_down}
    Click Element  ${xpath_scroll_down}
    Page Should Contain Element  ${xpath_choose_file_button}


Verify Choose File Button Click
    [Documentation]  Verify choose file button is clickable.
    [Tags]  Verify_Choose_File_Button_Click

    Page Should Contain  No file chosen
    Page Should Contain Element  ${xpath_choose_file_button}
    Click Element  ${xpath_choose_file_button}

Verify BMC Firmware Download
    # BMC Firmware File Path located at TFTP server.
    ${BMC_IMAGE_FILE_PATH}
    [Template]  Upload Firmware using TFTP Server
    [Documentation]  Verify BMC image is download from TFTP server.
    [Tags]  Verify_BMC_Firmware_Download


Verify Host Firmware Download
    # Host Firmware File Path located at TFTP server.
    ${PNOR_IMAGE_FILE_PATH}
    [Template]  Upload Firmware using TFTP Server
    [Documentation]  Verify Host image is download from TFTP server.
    [Tags]  Verify_HOST_Firmware_Download


*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Delete All Error Logs
    Click Element  ${xpath_select_server_config}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_firmware}

Upload Firmware using TFTP Server
    [Documentation]  Upload firmware using TFTP server.
    [Arguments]  ${firmware_file_name}

    Page Should Contain Button  ${xpath_download_firmware}
    Page Should Contain Element  ${xpath_tftp_server_ip}
    Page Should Contain Element  ${xpath_tftp_filename}

    Input Text  ${xpath_tftp_server_ip}  ${TFTP_SERVER}
    Input Text  ${xpath_tftp_filename}  ${firmware_file_name}
    Click Button  ${xpath_download_firmware}
    Sleep  180s
    Wait Until Page Does Not Contain Element  ${xpath_download_progress}

    # ${message}=  Handle Alert  timeout=300s
    # Didn't work so commenting out currently.
    # Alert not getting captured.
    # TODO: Issue https://github.com/openbmc/openbmc-test-automation/issues/1412

    Check No Error Log Exist

Check No Error Log Exist
    [Documentation]  No error log should be logged.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=Codeupdate Failed with error.

Re-Launch GUI on Failure
    [Documentation]  On failure of test case, close and re-launch GUI.

    Logout And Close Browser
    Launch Browser And Login OpenBMC GUI
