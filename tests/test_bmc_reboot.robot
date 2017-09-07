*** Settings ***
Documentation           This suite is for testing OCC: Power capping setting

Resource                ../lib/rest_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/boot_utils.robot
Resource                ../lib/bmc_ssh_utils.py

Force Tags  bmcreboot

Suite Setup             Open Connection And Log In
Suite Teardown          Close All Connections
Test Teardown           FFDC On Test Case Fail

*** Variables ***
${SYSTEM_SHUTDOWN_TIME}    ${5}

*** Test Cases ***

Test BMC Reboot via REST
    [Documentation]   This testcase is to verify bmc reboot using REST.
    [Tags]  Test_BMC_Reboot_via_REST

    ${test_file_path}=  Set Variable  /tmp/before_bmcreboot
    BMC Execute Command  touch ${test_file_path}

    OBMC Reboot (off)
    ${max_wait_time}=
    ...  Evaluate  ${SYSTEM_SHUTDOWN_TIME}+${OPENBMC_REBOOT_TIMEOUT}

    ${output}  ${stderr}  ${rc}=  BMC Execute Command
    ...   Run Keyword if [ -f ${test_file_path} ] ; then false ; fi

*** Keywords ***
