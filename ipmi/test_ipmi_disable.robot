*** Settings ***
Documentation    Module to test IPMI disable functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

*** Variables ***


*** Test Cases ***

Verify Disabling And Enabling IPMI Via Host
    [Documentation]  Verify disabling and enabling IPMI via host.
    [Tags]  Verify_Disabling_And_Enabling_IPMI_Via_Host
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Run Inband IPMI Standard Command  lan set 1 access on

    # Disable IPMI and verify
    Run Inband IPMI Standard Command  lan set 1 access off
    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Standard Command  lan print

    # Enable IPMI and verify
    Run Inband IPMI Standard Command  lan set 1 access on
    ${lan_print_output}=  Run External IPMI Standard Command  lan print

    ${openbmc_host_name}  ${openbmc_ip}  ${openbmc_short_name}=
    ...  Get Host Name IP  host=${OPENBMC_HOST}  short_name=1
    Should Contain  ${lan_print_output}  ${openbmc_ip}


Verify Disabling IPMI Via OOB IPMI
    [Documentation]  Verify disabling IPMI via out of band IPMI.
    [Tags]  Verify_Disabling_IPMI_Via_OOB_IPMI
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Run Inband IPMI Standard Command  lan set 1 access on

    # Disable IPMI via OOB IPMI and verify
    Run Keyword and Expect Error  *IPMI response is NULL*
    ...  Run IPMI Standard Command  lan set 1 access off
    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Standard Command  lan print

    # Enable IPMI via Host and verify
    Run Inband IPMI Standard Command  lan set 1 access on
    ${lan_print_output}=  Run External IPMI Standard Command  lan print

    ${openbmc_host_name}  ${openbmc_ip}  ${openbmc_short_name}=
    ...  Get Host Name IP  host=${OPENBMC_HOST}  short_name=1
    Should Contain  ${lan_print_output}  ${openbmc_ip}


Verify IPMI Disable Persistency After BMC Reboot
    [Documentation]  Verify IPMI disable persistency after BMC reboot.
    [Tags]  Verify_IPMI_Disable_Persistency_After_BMC_Reboot
    [Teardown]  Run Keywords  FFDC On Test Case Fail
    ...  AND  Run Inband IPMI Standard Command  lan set 1 access on

    # Disable IPMI and reboot BMC.
    Run Inband IPMI Standard Command  lan set 1 access off
    OBMC Reboot (run)

    # Verify that IPMI remains disabled after reboot.
    Run Keyword and Expect Error  *Unable to establish IPMI*
    ...  Run External IPMI Standard Command  lan print


*** Keywords ***

