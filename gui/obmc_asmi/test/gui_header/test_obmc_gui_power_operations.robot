*** Settings ***

Documentation  Test Open BMC GUI Power Operations under GUI Header.

Resource  ../../lib/resource.robot

Suite Setup  Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
Suite Teardown  Close Browser

*** Test Cases ***

Power On The Host
    [Documentation]  Power on the Host.
    [Tags]  Power_On_the_Host

    GUI Power On

Immediate Power Off The Host
    [Documentation]  Immediate power off the Host.
    [Tags]  Immediate_Power_Off_The_Host

    Controller Server Power Click Button  power__hard-shutdown
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${power_off}  ${confirm_msg}  ${yes}

Cold Boot The Host
    [Documentation]  Cold boot the Host.
    [Tags]  Cold_Boot_the_Host

    GUI Power On
    Controller Server Power Click Button  power__cold-boot
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${cold_boot}  ${confirm_msg}  ${yes}
    Page Should Contain  Running

Warm Boot The Host
    [Documentation]  Warm boot the Host.
    [Tags]  Warm_Boot_The_Host

    Controller Server Power Click Button  power__warm-boot
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${warm_boot}  ${confirm_msg}  ${yes}
    Page Should Contain  Running

Orderly Shutdown The Host
    [Documentation]  Orderly shutdown the Host.
    [Tags]  Orderly_Shutdown_The_Host

    Controller Server Power Click Button  power__soft-shutdown
    Controller Power Operations Confirmation Click Button  ${power_operations}
    ...  ${shut_down}  ${confirm_msg}  ${yes}
    Page Should Contain  Off

OpenBMC GUI Logoff
    [Documentation]  Log out from OpenBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Log  ${xpath_openbmc_url}
    Log To Console  ${xpath_openbmc_url}
    Click Element  header




