*** Settings ***
Documentation   Secondary BMC/PNOR image booting testing.


Resource        ../lib/rest_client.robot
Resource        ../lib/test_secondary_boot_resource.robot
Resource        ../lib/utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/state_manager.robot
Resource        ../lib/state_manager.robot

Test Setup  Open Connection And Log In


*** Test Cases ***
OBMC BMC Secondary Boot
    [Documentation]  Boot on secondary BMC side and then get back to primary.
    [Tags]  Secondary_Boot


    #Check if there are more than one BMC images
    ${BMC_IMG_NUM}=  OBMC Get Images Number  BMC
    Run Keyword If  ${BMC_IMG_NUM} < 2  FAIL  Less than 2 BMC images, cannot boot in a secondary BMC image

    ${1ST_BOOT_VER}=  Get BMC Version
    Log to Console  Active BMC Version: ${1ST_BOOT_VER}


    ${CURR_IMG}=  OBMC Get BMC Image With Priority  0
    ${SEC_IMG}=  OBMC Get BMC Image With Priority  1

    Log to Console  Switching priority to ${SEC_IMG}

    OBMC Set Bmc Image Priority  ${SEC_IMG}  0
    SLEEP  10
    Log to Console  Rebooting whitherspoon...
    Initiate BMC Reboot
    Wait For BMC Ready

    SLEEP  10
    ${2ND_BOOT_VER}=  Get BMC Version

    Should Not Be Equal  ${1ST_BOOT_VER}  ${2ND_BOOT_VER}
    ...  FAILED booting using the secondary image. The current image was booted even when the image priority was changed.

    Log to Console  Booting using BMC Version: ${2ND_BOOT_VER}

    Initiate Host Boot
    Wait For OS
    Power Off Request
    Wait Until Keyword Succeeds  4 min  10 sec  Is Host Off

    # Boot Back in previous
    Open Connection And Log In

    ${3RD_BOOT_VER}=  Get BMC Version

    Should Be Equal  ${2ND_BOOT_VER}  ${3RD_BOOT_VER}
    ...  FAILED booting using the secondary image. The BMC image was switched back after booting the OS

    Log to Console  BMC version after OS boot and power off: ${2ND_BOOT_VER}
    Log to Console  Switching back to BMC: ${1ST_BOOT_VER}
    Log to Console  Switching priority to ${CURR_IMG}

    OBMC Set Bmc Image Priority  ${CURR_IMG}  0
    SLEEP  10
    Log to Console  Rebooting whitherspoon...
    Initiate BMC Reboot
    Wait For BMC Ready


    Initiate Host Boot
    Wait For OS
    Power Off Request
    Wait Until Keyword Succeeds  4 min  10 sec  Is Host Off

    ${4TH_BOOT_VER}=  Get BMC Version

    Should Not Be Equal  ${3RD_BOOT_VER}  ${4TH_BOOT_VER}
    ...  FAILED booting using the primary image. The secondary image was booted even when the image priority was changed.

    Log to Console  BMC version after OS boot and power off: ${4TH_BOOT_VER}

OBMC PNOR Secondary Boot
    [Documentation]  Boot on secondary PNOR side and then get back to primary.
    [Tags]  Secondary_Boot


    #Check if there are more than one PNOR images
    ${PNOR_IMG_NUM}=  OBMC Get Images Number  PNOR
    Run Keyword If  ${PNOR_IMG_NUM} < 2  FAIL  Less than 2 BMC images, cannot boot in a secondary BMC image

    ${1ST_BOOT_VER}=  Get PNOR Version
    Log to Console  Active PNOR Version: ${1ST_BOOT_VER}

    ${CURR_IMG}=  OBMC Get PNOR Image With Priority  0
    ${SEC_IMG}=  OBMC Get PNOR Image With Priority  1

    Log to Console  Switching priority to ${SEC_IMG}

    OBMC Set Pnor Image Priority  ${SEC_IMG}  0
    SLEEP  10

    Initiate Host Boot
    Wait For OS
    Power Off Request
    Wait Until Keyword Succeeds  4 min  10 sec  Is Host Off

    # Boot Back in previous
    Open Connection And Log In
    ${2ND_BOOT_VER}=  Get PNOR Version
    Should Not Be Equal  ${1ST_BOOT_VER}  ${2ND_BOOT_VER}
    ...  FAILED booting using the secondary image. The current image was booted even when the image priority was changed.

    Log to Console  BMC version after OS boot and power off: ${2ND_BOOT_VER}

    OBMC Set Pnor Image Priority  ${CURR_IMG}  0
    SLEEP  10
    Log to Console  Rebooting whitherspoon...
    Initiate BMC Reboot
    Wait For BMC Ready

    Initiate Host Boot
    Wait For OS
    Power Off Request
    Wait Until Keyword Succeeds  4 min  10 sec  Is Host Off

    ${3RD_BOOT_VER}=  Get PNOR Version

    Should Not Be Equal  ${2ND_BOOT_VER}  ${3RD_BOOT_VER}
    ...  FAILED booting using the secondary image. The BMC image was switched back after booting the OS

    Log to Console  BMC version after OS boot and power off: ${3RD_BOOT_VER}








