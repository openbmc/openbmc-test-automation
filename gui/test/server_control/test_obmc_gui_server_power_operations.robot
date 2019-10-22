*** Settings ***

Documentation   Test OpenBMC GUI "Server power operation" sub-menu of
...             "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser


*** Variables ***

${xpath_select_access_control}           //button[@class="btn-control opened"]
${xpath_select_server_power_operations}  //a[@href='#/server-control/power-operations']


*** Test Cases ***

Verify Shutdown Button At Power Off
    [Documentation]  Verify that shutdown button is not present at power Off.
    [Tags]  Verify_Shutdown_Button_At_Power_Off
    [Setup]  Test Setup Execution  ${OBMC_PowerOff_state}

    Navigate To Power Operation Page
    Element Should Not Be Visible  //button[contains(text(), "Shut down")]


Verify Reboot Button At Power Off
    [Documentation]  Verify that reboot button is not present at power Off.
    [Tags]  Verify_Reboot_Button_At_Power_Off
    [Setup]  Test Setup Execution  ${OBMC_PowerOff_state}

    Navigate To Power Operation Page
    Element Should Not Be Visible  //button[contains(text(), "Reboot")]


*** Keywords ***

Navigate To Power Operation Page
   [Documentation]  Navigate to server power operation page.

    Click Element  ${xpath_select_access_control}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_power_operations}
    Wait Until Page Contains  Server power operations
