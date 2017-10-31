*** Settings ***
Documentation   Test errors and changes in the environment that BMC code
...             update should recover from or not be effected by.

Resource        ../../lib/code_update_utils_serial.robot
Resource        ../../lib/openbmc_ffdc.robot

Force Tags     BMC_Update_Recoverable_Error

Suite Setup     Suite Setup Execution

Test Setup      Test Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${QUIET}                        ${1}
${IMAGE_FILE_PATH}              ${EMPTY}

# In order to test the code update features of the image at ${IMAGE_FILE_PATH},
# we need another BMC image to update to.
${ALTERNATE_IMAGE_FILE_PATH}    ${EMPTY}

*** Test Cases ***

Reset Network During BMC Code Update
    [Documentation]  Disable and re-enable the network while doing a BMC
    ...              code update.
    [Tags]  Reset_Network_During_BMC_Code_Update
    [Template]  Reset Network Interface During Code Update

    # Image File Path   Reboot
    ${ALTERNATE_IMAGE_FILE_PATH}  ${TRUE}


Reboot BMC During BMC Image Activation
    [Documentation]  Attempt to reboot the BMC while an image is activating,
    ...              checking that the reboot has no effect.
    [Tags]  Reboot_BMC_During_BMC_Image_Activation

    Attempt To Reboot BMC During Image Activation  ${ALTERNATE_IMAGE_FILE_PATH}
    OBMC Reboot (off)


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do setup tasks for recoverable errors.

    Should Not Be Empty  ${IMAGE_FILE_PATH}
    ...  msg=IMAGE_FILE_PATH should be set.
    Should Not Be Empty  ${ALTERNATE_IMAGE_FILE_PATH}
    ...  msg=ALTERNATE_IMAGE_FILE_PATH should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_HOST}
    ...  msg=OPENBMC_SERIAL_HOST should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_PORT}
    ...  msg=OPENBMC_SERIAL_PORT should be set.


Test Setup Execution
    [Documentation]  Do setup tasks for every test case.

    Upload And Activate Image  ${IMAGE_FILE_PATH}  skip_if_active=true
    OBMC Reboot (off)
    Delete All Non Running BMC Images
