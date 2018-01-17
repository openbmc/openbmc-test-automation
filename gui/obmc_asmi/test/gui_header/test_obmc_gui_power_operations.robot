*** Settings ***

Documentation  Test Open BMC GUI Power Operations under GUI Header.

Resource  ../../../../lib/state_manager.robot
Resource  ../../lib/resource.robot


Suite Setup  Login OpenBMC GUI with failure enable
Suite Teardown  Close Browser

*** Test Cases ***

Power On The Host
    [Documentation]  Power on the host.
    [Tags]  Power_On_the_Host

    GUI Power On
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running
    Wait Until Page Contains  Running

Click Immediate Shutdown Then No
    [Documentation]  Click the "Immediate shutdown" button and then click the
    ...  "No" button.
    [Tags]  Click_Immediate_Shutdown_Then_No

    Controller Server Power Click Button  power__hard-shutdown
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${power_off}  ${confirm_msg}  ${No}

    Wait Until Page Contains  Running
    Is Host Running


Click Cold Reboot Then No
    [Documentation]  Click the "Cold reboot" button and then click the "No"
    ...  button.
    [Tags]  Click_Cold_Reboot_Then_No

    Controller Server Power Click Button  power__cold-boot
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${cold_boot}  ${confirm_msg}  ${No}

    Page Should Contain  Running
    Is Host Running

Click Warm Reboot Then No
    [Documentation]  Click the "Warm reboot" button and then click the "No"
    ...  button.
    [Tags]  Click_Warm_Reboot_Then_No

    Controller Server Power Click Button  power__warm-boot
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${warm_boot}  ${confirm_msg}  ${No}
    Page Should Contain  Running
    Is Host Running

Click Orderly Shutdown Then No
    [Documentation]  Click the "Orderly shutdown" button and then click the
    ...  "No" button.
    [Tags]  Click_Orderly_Shutdown_Then_No

    Controller Server Power Click Button  power__soft-shutdown
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${shut_down}  ${confirm_msg}  ${no}
    Page Should Contain  Running
    Is Host Running

Click Warm Reboot Then Yes
    [Documentation]  Click the "Warm reboot" button and then click the "Yes"
    ...  button.
    [Tags]  Click_Warm_Reboot_Then_Yes

    Controller Server Power Click Button  power__warm-boot
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${warm_boot}  ${confirm_msg}  ${yes}
    Page Should Contain  Running
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running

Click Cold Reboot Then Yes
    [Documentation]  Click the "Cold reboot" button and then click the "Yes"
    ...  button.
    [Tags]  Click_Cold_Reboot_Then_Yes

    Controller Server Power Click Button  power__cold-boot
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${cold_boot}  ${confirm_msg}  ${yes}
    Page Should Contain  Standby
    Wait Until Keyword Succeeds  10 min  10 sec  Is Host Running
    Page Should Contain  Running

Click Orderly Shutdown Then Yes
    [Documentation]  Click the "Orderly shutdown" button and then click the
    ...  "Yes" button.
    [Tags]  Click_Orderly_Shutdown_Then_Yes

    Controller Server Power Click Button  power__soft-shutdown
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${shut_down}  ${confirm_msg}  ${yes}
    Page Should Contain  Off
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off


Click Immediate Shutdown Then Yes
    [Documentation]  Click "Immediate shutdown" button and then click the "Yes"
    ...  button.
    [Tags]  Click_Immediate_Shutdown_Then_Yes

    GUI Power On
    Controller Server Power Click Button  power__hard-shutdown
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${power_off}  ${confirm_msg}  ${yes}

    Wait Until Page Contains  Off
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off


OpenBMC GUI Logoff
    [Documentation]  Log out from openBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Log  ${xpath_openbmc_url}
    Log To Console  ${xpath_openbmc_url}
    Click Element  header

*** Keywords ***

Login OpenBMC GUI with failure enable
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Register Keyword To Run On Failure  Login OpenBMC GUI




