*** Settings ***
Documentation    Suite description

Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot

#Test Teardown    FFDC On Test Case Fail

*** Variables ***
${QUIET}            ${1}
${IMAGE_FILE_PATH}  ${EMPTY}

*** Test Cases ***

Reset Network During Host Code Update
    [Documentation]  Disable and re-enable the network while doing a PNOR
    ...              code update.
    [Tags]  Reset_Network_During_Host_Code_Update
    [Template]  Reset Network During Code Update
    [Setup]  Reset Network Setup

    # Image File Path   Reboot
    ${IMAGE_FILE_PATH}  ${FALSE}


*** Keywords ***

Reset Network Setup
    [Documentation]  Do setup tasks for network reset.

    Should Not Be Empty  ${IMAGE_FILE_PATH}
    ...  msg=IMAGE_FILE_PATH should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_HOST}
    ...  msg=OPENBMC_SERIAL_HOST should be set.
    Should Not Be Empty  ${OPENBMC_SERIAL_PORT}
    ...  msg=OPENBMC_SERIAL_PORT should be set.
    Should Not Be Empty  ${OPENBMC_MODEL}
    ...  msg=OPENBMC_MODEL should be set.
