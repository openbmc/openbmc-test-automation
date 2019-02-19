*** Settings ***
Documentation  BMC OEM serial update utilities keywords.

Resource    code_update_utils.robot
Resource    serial_connection/serial_console_client.robot

*** Keywords ***

Reset Network Interface During Code Update
    [Documentation]  Disable and re-enable the network while doing code update.
    [Arguments]  ${image_file_path}  ${reboot}

    # Resetting the network will be done via the serial console.
    #
    # Description of argument(s):
    # image_file_path   Path to the image file to update to.
    # reboot            If set to true, will reboot the BMC after the code
    #                   update is finished.

    ${version_id}=  Upload And Activate Image  ${image_file_path}  wait=${0}
    Reset Network Interface

    # Verify code update was successful and 'Activation' state is 'Active'.
    Wait For Activation State Change  ${version_id}  ${ACTIVATING}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  &{software_state}[Activation]  ${ACTIVE}

    Run Keyword If  '${reboot}'  OBMC Reboot (off)  stack_mode=normal


Reset Network Interface
    [Documentation]  Turn the ethernet network interface off and then on again
    ...              through the serial console.

    Import Resource  ${CURDIR}/serial_connection/serial_console_client.robot
    Set Library Search Order  SSHLibrary  Telnet
    Execute Command On Serial Console  ifconfig eth0 down
    Sleep  30s
    Execute Command On Serial Console  ifconfig eth0 up
