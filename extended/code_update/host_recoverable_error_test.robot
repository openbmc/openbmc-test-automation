*** Settings ***
Documentation   Test errors and changes in the environment that BMC code
...             update should recover from or not be effected by.

Resource        ../../lib/code_update_utils_serial.robot
Resource        ../../lib/openbmc_ffdc.robot

Force Tags      Host_Update_Recoverable_Error

Suite Setup     Suite Setup Execution

Test Setup      Test Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${QUIET}            ${1}
${IMAGE_FILE_PATH}  ${EMPTY}

*** Test Cases ***

Reset Network During Host Code Update
    [Documentation]  Disable and re-enable the network while doing a PNOR
    ...              code update.
    [Tags]  Reset_Network_During_Host_Code_Update
    [Template]  Reset Network Interface During Code Update

    # Image File Path   Reboot
    ${IMAGE_FILE_PATH}  ${FALSE}


Reboot BMC During Host Code Update
    [Documentation]  Attempt to reboot the BMC while an image is activating,
    ...              checking that the reboot has no effect.
    [Tags]  Reboot_BMC_During_Host_Code_Update

    Attempt To Reboot BMC During Image Activation  ${IMAGE_FILE_PATH}


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

    Delete All PNOR Images
