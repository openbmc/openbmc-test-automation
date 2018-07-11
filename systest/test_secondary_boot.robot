*** Settings ***
Resource                ../lib/rest_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/code_update_utils.robot
Resource                ../lib/boot_utils.robot

*** Test Cases ***
OBMC BMC Secondary Boot
    [Documentation]  Boot on secondary BMC side and then get back to primary.
    [Tags]  OBMC_BMC_Secondary_Boot

    ${bmc_images}=  Get Software Objects  ${VERSION_PURPOSE_BMC}
    ${current_image}=  Set Variable  ${EMPTY}
    ${secondary_image}=  Set Variable  ${EMPTY}
    # Check if there is more than one BMC image to proceed with the test.
    ${bmc_image_number}=  Get Length  ${bmc_images}
    Run Keyword If  ${bmc_image_number} < 2
    ...   Fail  Less than 2 BMC images, cannot boot in a secondary BMC image
    ${first_boot_version}=  Get BMC Version
    # Look for active image.
    :FOR  ${image}  IN  @{bmc_images}
    \   ${image_priority}=  Get Host Software Property  ${image}
    \   ${current_image}=
    ...   Run Keyword If  "${image_priority["Priority"]}" == "0"
    ...      Set Variable  ${image}
    \   Run Keyword If  "${image_priority["Priority"]}" == "0"
    ...   Exit For Loop
    # Look for the secondary image.
    :FOR  ${image}  IN  @{bmc_images}
    \   ${image_priority}=  Get Host Software Property  ${image}
    \   ${secondary_image}=
    ...   Run Keyword If  "${image_priority["Priority"]}" == "1"
    ...      Set Variable  ${image}
    \   Run Keyword If  "${image_priority["Priority"]}" == "1"
    ...   Exit For Loop
    # Boot into secondary image.
    Set Host Software Property  ${secondary_image}  Priority  ${0}
    REST OBMC Reboot (off)
    ${second_boot_version}=  Get BMC Version
    Should Not Be Equal  ${first_boot_version}  ${second_boot_version}
    ...   Failed booting using the secondary image. The current image
    ...   was booted even when the image priority was changed.
    REST Power On
    REST Power Off
    ${third_boot_version}=  Get BMC Version
    Should Be Equal  ${second_boot_version}  ${third_boot_version}
    ...   Failed booting using the secondary image.
    ...   The BMC image was switched back after booting the OS
    # Boot back into previous image.
    Set Host Software Property  ${current_image}  Priority  ${0}
    REST OBMC Reboot (off)
    REST Power On
    REST Power Off
    ${fourth_boot_version}=  Get BMC Version
    Should Not Be Equal  ${third_boot_version}  ${fourth_boot_version}
    ...   Failed booting using the primary image. The secondary image
    ...   was booted even when the image priority was changed.

OBMC PNOR Secondary Boot
    [Documentation]  Boot on secondary PNOR side and then get back to primary.
    [Tags]  OBMC_PNOR_Secondary_Boot

    ${pnor_images}=  Get Software Objects  ${VERSION_PURPOSE_HOST}
    ${current_image}=  Set Variable  ${EMPTY}
    ${secondary_image}=  Set Variable  ${EMPTY}
    # Check if there is more than one PNOR image to proceed with the test.
    ${pnor_image_number}=  Get Length  ${pnor_images}
    Run Keyword If  ${pnor_image_number} < 2
    ...   Fail  Less than 2 PNOR images, cannot boot in a secondary PNOR image
    ${first_boot_version}=  Get PNOR Version
    # Look for active image.
    :FOR  ${image}  IN  @{pnor_images}
    \   ${image_priority}=  Get Host Software Property  ${image}
    \   ${current_image}=
    ...   Run Keyword If  "${image_priority["Priority"]}" == "0"
    ...      Set Variable  ${image}
    \   Run Keyword If  "${image_priority["Priority"]}" == "0"
    ...   Exit For Loop
    # Look for the secondary image.
    :FOR  ${image}  IN  @{pnor_images}
    \   ${image_priority}=  Get Host Software Property  ${image}
    \   ${secondary_image}=
    ...   Run Keyword If  "${image_priority["Priority"]}" == "1"
    ...      Set Variable  ${image}
    \   Run Keyword If  "${image_priority["Priority"]}" == "1"
    ...   Exit For Loop
    # Boot into secondary image.
    Set Host Software Property  ${secondary_image}  Priority  ${0}
    REST OBMC Reboot (off)
    ${second_boot_version}=  Get PNOR Version
    Should Not Be Equal  ${first_boot_version}  ${second_boot_version}
    ...   Failed booting using the secondary image. The current image
    ...   was booted even when the image priority was changed.
    REST Power On
    REST Power Off
    ${third_boot_version}=  Get PNOR Version
    Should Be Equal  ${second_boot_version}  ${third_boot_version}
    ...   Failed booting using the secondary image.
    ...   The PNOR image was switched back after booting the OS
    # Boot back into previous image.
    Set Host Software Property  ${current_image}  Priority  ${0}
    REST OBMC Reboot (off)
    REST Power On
    REST Power Off
    ${fourth_boot_version}=  Get PNOR Version
    Should Not Be Equal  ${third_boot_version}  ${fourth_boot_version}
    ...   Failed booting using the primary image. The secondary image
    ...   was booted even when the image priority was changed.