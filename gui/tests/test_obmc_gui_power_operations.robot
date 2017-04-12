*** Settings ***

Documentation  Test OBMC GUI Power Operations 

Resource  ../lib/obmcgui_utils.robot

Suite Setup  OpenBMC GUI Login
Suite Teardown  Close Browser

*** Test Cases ***

Power On the CEC
    [Documentation]  Power on the CEC.
    [Tags]  Power_On_the_CEC

    GUI Power On

Warm Boot the CEC
    [Documentation]  Warm boot the CEC.
    [Tags]  Warm_Boot_the_CEC

    GUI Power On
    Wait Until Element Is Visible  ${obmc_xpath_warm_boot}
    Click Element  ${obmc_xpath_warm_boot}
    Wait Until Element Is Visible  ${obmc_xpath_warm_boot_confirmation}
    Click Element  ${obmc_xpath_yes_button_warm_boot}

Immediate Power Off the CEC
    [Documentation]  Immediate power off the CEC.
    [Tags]  Immediate_Power_Off_the_CEC

    Wait Until Element Is Visible  ${obmc_xpath_immediate_shutdown}
    Click Element  ${obmc_xpath_immediate_shutdown}
    Wait Until Element Is Visible  ${obmc_xpath_immediate_shutdown_confirmation}
    Click Element  ${obmc_xpath_yes_button}

Cold Boot the CEC
    [Documentation]  Cold boot the CEC.
    [Tags]  Cold_Boot_the_CEC

    Wait Until Element Is Visible  ${obmc_xpath_cold_boot}
    Click Element  ${obmc_xpath_cold_boot}
    Wait Until Element Is Visible  ${obmc_xpath_cold_boot_confirmation}
    Click Element  ${obmc_xpath_yes_button_cold_boot}

Orderly Shutdown the CEC
    [Documentation]  Orderly shutdown  the CEC.
    [Tags]  Orderly_Shutdown_the_CEC

    Wait Until Element Is Visible  ${obmc_xpath_orderly_shutdown}
    Click Element  ${obmc_xpath_orderly_shutdown}
    Wait Until Element Is Visible  ${obmc_xpath_orderly_shutdown_confirmation}
    Click Element  ${obmc_xpath_yes_button_orderly_shutdown}

OpenBMC GUI Logoff
    [Documentation]  Log out from OpenBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Log  ${obmc_BMC_URL}
    Log To Console  ${obmc_BMC_URL}
    Click Element  ${obmc_xpath_logout}




