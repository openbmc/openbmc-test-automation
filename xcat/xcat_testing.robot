*** Settings ***
Documentation   Module for testing BMC via XCAT.

Resource        ../lib/xcat/resource.txt
Resource        ../lib/xcat/xcat_utils.robot

Library         OperatingSystem

*** Test Cases ***

Connect And Add BMC Nodes To XCAT

    [Documentation]  Connect and add BMC nodes.
    [Tags]  Connect_And_Add_BMC_Nodes_To_XCAT

    Open Connection And Login To XCAT   ${XCAT_HOST}  ${XCAT_PORT}

    ${cmd_output}=  Execute Command  ${XCAT_PATH} -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Log To Console  \n XCAT Version is: \n${cmd_output}

    # It reads out file having list of BMC nodes and adds
    # those nodes into XCAT.

    ${bmc_list}=  Get List Of BMC Nodes
    Log To Console  \n List of BMC nodes \n ${bmc_list}

