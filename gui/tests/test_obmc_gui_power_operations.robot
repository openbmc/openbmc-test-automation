*** Settings ***

Documentation  Test OBMC GUI Power Operations

Resource  ../lib/obmcgui_utils.robot

Suite Teardown  Close Browser

*** Test Cases ***

OpenBMC GUI Login
    [Documentation]  Log into OpenBMC GUI.
    [Tags]  Log_into_OpenBMC_GUI

    Log  ${BMC_URL}
    Log To Console  ${BMC_URL}
    # Open Browser with URL  ${BMC_URL}
    Open Browser With URL  ${BMC_URL}  gc
    Page Should contain Button  ${login_button}
    Wait Until Page Contains Element  ${xpath_uname}
    Input Text  ${xpath_uname}  ${username}
    Input Password  ${xpath_password}  ${password}
    Click Element  ${login_button}
    Page Should Contain  System Overview

Power On the CEC
    [Documentation]  Power on the CEC.
    [Tags]  Test_Power_On_the_CEC

    Power-Operations Power On the CEC

Warm Boot the CEC
    [Documentation]  Warm Boot the CEC.
    [Tags]  Warm_Boot_the_CEC

    Power-Operations Power On the CEC
    Wait Until Element Is Visible  ${xpath_warm-boot}
    Click Element  ${xpath_warm-boot}
    Wait Until Element Is Visible  ${xpath_warm-boot-confirmation}
    Click Element   ${xpath_yes_button_warm-boot}

Immediate Power Off the CEC
    [Documentation]  Immediate Power off the CEC.
    [Tags]  Immediate_Power_Off_the_CEC

    Wait Until Element Is Visible  ${xpath_immediate-shutdown}
    Click Element  ${xpath_immediate-shutdown}
    Wait Until Element Is Visible  ${xpath_immediate-shutdown-confirmation}
    Click Element  ${xpath_yes_button}

Cold Boot the CEC
    [Documentation]  Cold Boot the CEC.
    [Tags]  Cold_Boot_the_CEC

    Wait Until Element Is Visible  ${xpath_cold-boot}
    Click Element  ${xpath_cold-boot}
    Wait Until Element Is Visible  ${xpath_cold-boot-confirmation}
    Click Element   ${xpath_yes_button_cold-boot}

Orderly Shutdown the CEC
    [Documentation]  Orderly Shutdown  the CEC.
    [Tags]  Orderly_Shutdown_the_CEC

    Wait Until Element Is Visible  ${xpath_orderly-shutdown}
    Click Element  ${xpath_orderly-shutdown}
    Wait Until Element Is Visible  ${xpath_orderly-shutdown-confirmation}
    Click Element   ${xpath_yes_button_orderly-shutdown}

OpenBMC GUI Logoff
    [Documentation]  Log out from OpenBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Log  ${BMC_URL}
    Log To Console  ${BMC_URL}
    Click Element  ${xpath_logout}




