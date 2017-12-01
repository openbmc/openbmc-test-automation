*** Settings ***
Documentation  This file is resourced by obmc_boot_test.py to set initial
...            variable values, etc.

Resource  ../lib/openbmc_ffdc.robot
Resource  ../lib/utils.robot
Library   Collections

*** Variables ***


*** Keywords ***

OBMC Get Bmc Images
    ${BMC_IMAGES}=  Create Dictionary
    ${sw}=  Set Variable  /xyz/openbmc_project/software

    # Get active images
    ${resp}=  OpenBMC Get Request  ${sw}/enumerate  quiet=${1}
    ${json}=  To JSON  ${resp.content}
    :FOR  ${IMAGE}  IN  @{json["data"]["/xyz/openbmc_project/software/active"]["endpoints"]}
    \   Log  ${IMAGE}
    \   Run Keyword If  "${json["data"]["${IMAGE}"]["Purpose"]}" == "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"  Set to Dictionary  ${BMC_IMAGES}  ${IMAGE}=${json["data"]["${IMAGE}"]}
    Log Dictionary  ${BMC_IMAGES}
    [return]  ${BMC_IMAGES}


OBMC Get Pnor Images
    ${PNOR_IMAGES}=  Create Dictionary
    ${sw}=  Set Variable  /xyz/openbmc_project/software

    # Get active images
    ${resp}=  OpenBMC Get Request  ${sw}/enumerate  quiet=${1}
    ${json}=  To JSON  ${resp.content}
    :FOR  ${IMAGE}  IN  @{json["data"]["/xyz/openbmc_project/software/active"]["endpoints"]}
    \   Log  ${IMAGE}
    \   Run Keyword If  "${json["data"]["${IMAGE}"]["Purpose"]}" == "xyz.openbmc_project.Software.Version.VersionPurpose.Host"  Set to Dictionary  ${PNOR_IMAGES}  ${IMAGE}=${json["data"]["${IMAGE}"]}
    Log List  ${PNOR_IMAGES}
    [return]  ${PNOR_IMAGES}


OBMC Get Images Number
    [arguments]  ${IMAGE_TYPE}

    ${IMAGES}=  Set Variable If  "${IMAGE_TYPE}" == "BMC"  OBMC Get Bmc Images  OBMC Get Pnor Images

    [return]  Get Length  ${IMAGES}



OBMC Set Bmc Image Priority

    [arguments]  ${IMAGE}  ${PRIO}
    ${ret}=  Execute Command On BMC  busctl call xyz.openbmc_project.Software.BMC.Updater ${IMAGE} org.freedesktop.DBus.Properties Set ssv xyz.openbmc_project.Software.RedundancyPriority Priority y ${PRIO}
    Log  ${ret}


OBMC Set Pnor Image Priority

    [arguments]  ${IMAGE}  ${PRIO}
    ${ret}=  Execute Command On BMC  busctl call org.open_power.Software.Host.Updater ${IMAGE} org.freedesktop.DBus.Properties Set ssv xyz.openbmc_project.Software.RedundancyPriority Priority y ${PRIO}
    Log  ${ret}


OBMC Get BMC Image With Priority
    [arguments]  ${PRIO}

    ${IMAGES}=  OBMC Get Bmc Images
    ${PRIO_IMAGE}=  Set Variable  ${EMPTY}

    :FOR  ${ITEM}  IN  @{IMAGES}
    \   ${PRIO_IMAGE}=  Set Variable If  "${IMAGES["${ITEM}"]["Priority"]}" == "${PRIO}"  ${ITEM}  ${PRIO_IMAGE}

    [return]  ${PRIO_IMAGE}


OBMC Get PNOR Image With Priority
    [arguments]  ${PRIO}

    ${IMAGES}=  OBMC Get Pnor Images
    ${PRIO_IMAGE}=  Set Variable  ${EMPTY}

    :FOR  ${ITEM}  IN  @{IMAGES}
    \   ${PRIO_IMAGE}=  Set Variable If  "${IMAGES["${ITEM}"]["Priority"]}" == "${PRIO}"  ${ITEM}  ${PRIO_IMAGE}

    [return]  ${PRIO_IMAGE}

