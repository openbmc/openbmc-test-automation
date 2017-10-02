*** Settings ***
Documentation   Test errors and changes in the environment that BMC code
...             update should recover from or not be effected by.

Resource        ../../lib/code_update_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution

Test Setup      Test Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${QUIET}                        ${1}
${IMAGE_FILE_PATH}              ${EMPTY}
${ALTERNATE_IMAGE_FILE_PATH}    ${EMPTY}

*** Test Cases ***

Reset Network During BMC Code Update
    [Documentation]  Disable and re-enable the network while doing a BMC
    ...              code update.
    [Tags]  Reset_Network_During_BMC_Code_Update
    [Template]  Reset Network During Code Update

    # Image File Path   Reboot
    ${ALTERNATE_IMAGE_FILE_PATH}  ${TRUE}


Reboot BMC During BMC Image Activation
    [Documentation]  Reboot the BMC while an image is activating.
    [Tags]  Reboot_BMC_During_BMC_Image_Activation

    ${version_id}=  Upload And Activate Image  ${ALTERNATE_IMAGE_FILE_PATH}
    ...  wait=${0}
    OBMC Reboot (off)
    ${priority}=  Read Software Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  Priority
    Should Be Equal  ${priority}  ${0}
    Verify Running BMC Image  ${ALTERNATE_IMAGE_FILE_PATH}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do setup tasks for recoverable errors.

    Should Not Be Empty  ${IMAGE_FILE_PATH}
    ...  msg=IMAGE_FILE_PATH should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_HOST}
    ...  msg=OPENBMC_SERIAL_HOST should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_PORT}
    ...  msg=OPENBMC_SERIAL_PORT should be set.


Test Setup Execution
    [Documentation]  Do setup tasks for every test case.

    Upload And Activate Image  ${IMAGE_FILE_PATH}  skip_if_active=true
    OBMC Reboot (off)
