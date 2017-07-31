*** Settings ***
Documentation   Module for testing BMC inventory via XCAT.

Resource        ../lib/xcat/resource.txt
Resource        ../lib/xcat/xcat_utils.robot
Resource        ../lib/state_manager.robot

Suite Setup     XCAT Suite Setup

*** Variables ***

*** Test Cases ***

Verify BMC Version Via XCAT
    [Documentation]  Verify BMC version using XCAT and REST.
    [Tags]  Verify_BMC_Version_Via_XCAT

    ${xcat_resp}=  Execute Command On XCAT  rinv  firm
    ${rest_resp}=  Get BMC Version

    Should contain  ${xcat_resp}  ${rest_resp}


*** Keywords ***

XCAT Suite Setup
    [Documentation]  XCAT suite setup.

    Open Connection And Login To XCAT

    # Check if XCAT is installed.
    ${cmd_output}=  Execute Command  ${XCAT_DIR_PATH}/lsxcatd -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Add Nodes To XCAT  ${OPENBMC_HOST}
