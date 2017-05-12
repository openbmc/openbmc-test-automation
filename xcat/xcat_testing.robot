*** Settings ***
Documentation   Module for testing BMC via XCAT.

Resource        ../lib/xcat/resource.txt
Resource        ../lib/xcat/xcat_utils.robot

Library         OperatingSystem

Suite Setup  Validate XCAT Setup

*** Test Cases ***

Add BMC Nodes To XCAT
    [Documentation]  Connect and add BMC nodes.
    [Tags]  Add_BMC_Nodes_To_XCAT
    
    # It reads out file having list of BMC nodes and adds
    # those nodes into XCAT.

    # TBD- Adding BMC nodes to XCAT
    # https://github.com/openbmc/openbmc-test-automation/issues/620

*** Keywords ***

Validate XCAT Setup
    [Documentation]  Validate XCAT setup.

    Open Connection And Login To XCAT

    # Check if XCAT is installed.
    ${cmd_output}=  Execute Command  ${XCAT_PATH}/lsxcatd -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Log  \n XCAT Version is: \n${cmd_output}
