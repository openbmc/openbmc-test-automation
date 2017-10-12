*** Settings ***
Documentation   Test errors and changes in the environment that BMC code
...             update should recover from or not be effected by.

Resource        ../../lib/code_update_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution

Test Teardown   FFDC On Test Case Fail

*** Variables ***
${QUIET}            ${1}
${IMAGE_FILE_PATH}  ${EMPTY}

*** Test Cases ***

Reset Network During BMC Code Update
    [Documentation]  Disable and re-enable the network while doing a BMC
    ...              code update.
    [Tags]  Reset_Network_During_BMC_Code_Update
    [Template]  Reset Network Interface During Code Update

    # Image File Path   Reboot
    ${IMAGE_FILE_PATH}  ${TRUE}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do setup tasks for recoverable errors.

    Should Not Be Empty  ${IMAGE_FILE_PATH}
    ...  msg=IMAGE_FILE_PATH should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_HOST}
    ...  msg=OPENBMC_SERIAL_HOST should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_PORT}
    ...  msg=OPENBMC_SERIAL_PORT should be set.
