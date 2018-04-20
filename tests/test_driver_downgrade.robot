*** Settings ***
[Documentation]  Downgrade the BMC and PNOR drivers.

# Test Parameters:

# OPENBMC_HOST        The BMC host name or IP address.
# LCB_HOST            The LCB hostname where downgrade will be executed.
# LCB_USERNAME        The LCB username.
# LCB_PASSWORD        The LCB user's password.

Library         SSHLibrary
Library         String
Library         ../lib/bmc_ssh_utils.py
Resource        ../lib/resource.txt
Resource        ../lib/utils.robot
Resource        ../syslib/utils_os.robot

Suite Setup     Suite Setup Execution

*** Variables ***

${LCB_HOST}       ${EMPTY}
${LCB_USERNAME}   ${EMPTY}
${LCB_PASSWORD}   ${EMPTY}
${FIRMWARE_PATH}  ${EMPTY}
${IMAGE_ID}       ${EMPTY}

*** Test Cases ***
BMC Driver Downgrade
    [Documentation]  Downgrade the BMC driver.
    [Tags]  BMC_Driver_Downgrade

    Log Into BMC Directory
    Download Driver
    Install Driver
    REST OBMC Reboot (off)  stack_mode=normal
    Check If BMC Is Up  20 min  15 sec

PNOR Driver Downgrade
    [Documentation]  Downgraade the PNOR driver.
    [Tags]  PNOR_Driver Downgrade

    REST Power Off  stack_mode=skip
    Log Into BMC Directory
    Download Driver
    Install Driver
    REST Power On  stack_mode=skip

*** Keywords ***
Log Into BMC Directory
    [Documentation]  Log into the BMC from a directory you have write.
    ...  permission to.

    ${cmd_buffer}=  Catenate  curl -c cjar -k -X POST -H "Content-Type:
    ...  application/json" -d '{"data": [ "${OPENBMC_USERNAME}",
    ...  "${OPENBMC_PASSWORD}" ] }' https://${OPENBMC_HOST}/login
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buffer}
    Should Contain  ${stdout}  "status": "ok"

Download Driver
    [Documentation]  Download the firmware image into the BMC.

    ${cmd_buffer}=  Catenate  curl -c cjar -b cjar -k -H "Content-Type:
    ...  application/octet-stream" -X POST -T ${FIRMWARE_PATH}
    ...  https://$BMC_IP/upload/image
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buffer}
    Should Contain  ${stdout}  "status": "ok"

Install Driver
    [Documentation]  Install the firmware image.

    ${image_uri}=  Catenate  https://${OPENBMC_HOST}  xyz  openbmc_project
    ...  software  ${image_id}  attr  RequestedActivation
    Log  Install the firmware image.
    ${cmd_buffer}=  Catenate  curl -b cjar -k -H "Content-Type:
    ...  application/json" -X PUT -d '{"data":
    ...  "xyz.openbmc_project.Software.Activation.RequestedActivations.Active"
    ...  }'  ${image_uri}
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buffer}
    Should Contain  ${stdout}  "status": "ok"
    Wait Until Keyword Succeeds  30 min  15 sec  Run Keywords
    ...  Verify Recent Driver Installation
    ...  AND
    ...  Should Contain  ${status}  Activated

Verify Recent Driver Installation
    [Documentation]  Verify if the firmware image installation has finished.

    ${cmd_buffer}=  Catenate  curl -c cjar -b cjar -k -H "Content-Type:
    ...  application/json"
    ...  https://${OPENBMC_HOST}/xyz/openbmc_project/software/442e6ec8 | grep
    ...  Activation.Activations
    ${status}  ${stderr}  ${rc}=  OS Execute Command  ${cmd_buffer}
    Should Be Empty  ${stderr}
    Set Test Variable  ${status}

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Should Not Be Empty  ${FIRMWARE_PATH}  msg=A path to the firmware is
    ...  necessary.
    Should Not Be Empty  ${IMAGE_ID}  msg=An image-id is necessary
    Login To OS  ${LCB_HOST}  ${LCB_USERNAME}  ${LCB_PASSWORD}
    Tool Exist  curl
