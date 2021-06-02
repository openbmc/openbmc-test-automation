*** Settings ***
Documentation    Module to test In band firmware update.

Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/connection_client.robot
Resource         ../../lib/code_update_utils.robot

Suite Setup      Suite Setup Execution

*** Variables ***
${image-bios}        image-bios
${image-bios-sig}    image-bios.sig
${image-bmc}         image-bmc
${image-bmc-sig}     image-bmc.sig
${BAD_IMG}           tmp.bin
${BAD_SIG}           tmp.sig
${lpcshm_address}    ${0}

*** Test Cases ***

Test BIOS Firmware Update
    [Documentation]  Test BIOS firmware update over IPMI.
    [Tags]  Test_BIOS_Firmware_Update

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins

    Get LPC SHM Address
    Update BIOS Firmware  ${IMAGE_HOST_FILE_PATH_0}
    Verify BIOS Version  ${IMAGE_HOST_FILE_PATH_0}
    BMC Execute Command
    ...  systemctl restart phosphor-ipmi-host.service
    Sleep  10s
    Get LPC SHM Address
    Update BIOS Firmware  ${IMAGE_HOST_FILE_PATH_1}
    Verify BIOS Version  ${IMAGE_HOST_FILE_PATH_1}
    BMC Execute Command
    ...  systemctl restart phosphor-ipmi-host.service
    Sleep  10s

Test Invalid BIOS Firmware Update
    [Documentation]  Test Invalid BIOS firmware update over IPMI.
    [Tags]  Test_Invalid_BIOS_Firmware_Update

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins
    Get LPC SHM Address

    ${cmd}=  Catenate  ${HOST_WORK_DIR}/burn_my_bmc --command update --interface ipmilpc
    ...  --image ${HOST_WORK_DIR}/${BAD_IMG} --sig ${HOST_WORK_DIR}/${BAD_SIG} --type bios
    ...  --address 0x${lpcshmaddress} --length 0xFFC

    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  ignore_err=1
    Should Contain  ${stderr}  Verification failed

Test BMC Firmware Update
    [Documentation]  Test BMC firmware update over IPMI.
    [Tags]  Test_BMC_Firmware_Update

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins
    Get LPC SHM Address
    Update BMC Firmware  ${IMAGE_BMC_FILE_PATH_0}
    Verify BMC Version  ${IMAGE_BMC_FILE_PATH_0}
    Sleep  10s
    Update BMC Firmware  ${IMAGE_BMC_FILE_PATH_1}
    Verify BMC Version  ${IMAGE_BMC_FILE_PATH_1}

Test Invalid BMC Firmware Update
    [Documentation]  Test Invalid BMC firmware update over IPMI.
    [Tags]  Test_Invalid_BMC_Firmware_Update

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins
    Get LPC SHM Address

    ${cmd}=  Catenate  ${HOST_WORK_DIR}/burn_my_bmc --command update --interface ipmilpc
    ...  --image ${HOST_WORK_DIR}/${BAD_IMG} --sig ${HOST_WORK_DIR}/${BAD_SIG} --type image
    ...  --address 0x${lpcshmaddress} --length 0xFFC

    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  ignore_err=1
    Should Contain  ${stderr}  Verification failed


*** Keywords ***

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    ${os_state}=  Get Host State Attribute  OperatingSystemState
    Rprint Vars  os_state
    Run Keyword if  '${OS_BOOT_COMPLETE}' != '${os_state}'
    ...  Redfish Power On

    # generate bad image for test
    ${cmd}=  Catenate  dd if=/dev/urandom of=${HOST_WORK_DIR}/${BAD_IMG} bs=1K count=4
    OS Execute Command  ${cmd}  ignore_err=1
    ${cmd}=  Catenate  dd if=/dev/urandom of=${HOST_WORK_DIR}/${BAD_SIG} bs=1 count=128
    OS Execute Command  ${cmd}  ignore_err=1


Get LPC SHM Address
    [Documentation]  Get Mapped Address of LPC hare Memory.

    # select SHM logic device
    OS Execute Command  outb 0x4e 0x07
    OS Execute Command  outb 0x4f 0x0f

    OS Execute Command  outb 0x4e 0xf4
    ${output}  ${stderr}  ${rc}=  OS Execute Command  inb 0x4f
    ${output}=  Evaluate  ${output} + 4
    ${b0}=  Convert To Hex  ${output}  length=2

    OS Execute Command  outb 0x4e 0xf5
    ${output}  ${stderr}  ${rc}=  OS Execute Command  inb 0x4f
    ${b1}=  Convert To Hex  ${output}  length=2

    OS Execute Command  outb 0x4e 0xf6
    ${output}  ${stderr}  ${rc}=  OS Execute Command  inb 0x4f
    ${b2}=  Convert To Hex  ${output}  length=2

    OS Execute Command  outb 0x4e 0xf7
    ${output}  ${stderr}  ${rc}=  OS Execute Command  inb 0x4f
    ${b3}=  Convert To Hex  ${output}  length=2

    Set Global Variable  ${lpcshm_address}  ${b3}${b2}${b1}${b0}
    Rprint Vars  lpcshm_address

BIOS Update Status Should Be
    [Documentation]  Check the Update Process is Activating.
    [Arguments]  ${state}

    # Description of argument(s):
    # state   The state of update process.

    ${cmd}=  Catenate  systemctl show --property=ActiveState --property=LoadState
    ...  --property=Result phosphor-ipmi-flash-bios-update.service
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}

    Should Contain  ${output}  ${state}  case_insensitive=True

Verify BIOS Version
    [Documentation]  Verify BIOS Version.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    ${image_version}=  Get Version Tar  ${image_file_path}
    Rprint Vars  image_version

    ${BIOS_Version}=  Get BIOS Version
    Rprint Vars  BIOS_Version
    Should Be Equal  ${BIOS_Version}  ${image_version}

Verify BMC Version
    [Documentation]  Verify that the version on the BMC is the same as the
    ...              version in the given image via Redfish.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    # Extract the version from the image tarball on our local system.
    ${image_version}=  Get Version Tar  ${image_file_path}
    Rprint Vars  image_version
    Redfish.Login
    ${bmc_version}=  Redfish Get BMC Version
    Rprint Vars  bmc_version

    Valid Value  bmc_version  valid_values=['${image_version}']

Update BIOS Firmware
    [Documentation]  Update BIOS Firmware.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    OperatingSystem.File Should Exist  ${image_file_path}

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins

    scp.Open connection  ${OS_HOST}  username=${OS_USERNAME}
    ...  password=${OS_PASSWORD}
    scp.Put File  ${image_file_path}  ${HOST_WORK_DIR}/${image_file_path}

    ${cmd}=  Catenate  tar -xf ${HOST_WORK_DIR}/${image_file_path} -C ${HOST_WORK_DIR}
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}

    ${cmd}=  Catenate  ${HOST_WORK_DIR}/burn_my_bmc --command update --interface ipmilpc
    ...  --image ${HOST_WORK_DIR}/${image-bios} --sig ${HOST_WORK_DIR}/${image-bios-sig} --type bios
    ...  --address 0x${lpcshm_address} --length 0xFFC

    OS Execute Command  ${cmd}  fork=1

    Wait Until Keyword Succeeds  5 mins  10 secs
    ...  BIOS Update Status Should Be  ActiveState=activating

    Wait Until Keyword Succeeds  20 mins  30 secs
    ...  BIOS Update Status Should Be  ActiveState=inactive

    ${cmd}=  Catenate  systemctl show --property=Result
    ...  phosphor-ipmi-flash-bios-update.service
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Contain  ${output}  Result=success

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  5 mins

Update BMC Firmware
    [Documentation]  Update BIOS Firmware.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    OperatingSystem.File Should Exist  ${image_file_path}

    Run Keyword  Wait For Host To Ping  ${OS_HOST}  3 mins

    scp.Open connection  ${OS_HOST}  username=${OS_USERNAME}
    ...  password=${OS_PASSWORD}
    scp.Put File  ${image_file_path}  ${HOST_WORK_DIR}/${image_file_path}

    ${cmd}=  Catenate  tar -xf ${HOST_WORK_DIR}/${image_file_path} -C ${HOST_WORK_DIR}
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}

    ${cmd}=  Catenate  ${HOST_WORK_DIR}/burn_my_bmc --command update --interface ipmilpc
    ...  --image ${HOST_WORK_DIR}/${image-bmc} --sig ${HOST_WORK_DIR}/${image-bmc-sig} --type image
    ...  --address 0x${lpcshm_address} --length 0xFFC --ignore-update

    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  ignore_err=1
    Should Not Contain  ${stderr}  Exception received

    Sleep  10s
    Check If BMC is Up  20 min  20 sec
    Wait For BMC Ready
