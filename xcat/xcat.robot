*** Settings ***
Documentation  This program opens connection, login to xCAT
...            add nodes (BMC). Then creates groups, performs
...            node poweron/off and group poweron/off.

Resource        ../lib/xcat/resource.txt
Resource        ../lib/xcat/xcat_utils.robot

Library         OperatingSystem

*** Variables ***

# Path of file having BMC nodes.
${cfg_file}  ../lib/xcat/bmc_nodes.cfg

*** Test Cases ***

Connect And Add BMC Nodes To XCAT

    [Documentation]  Connect and add BMC nodes.
    [Tags]  Connect_And_Add_BMC_Nodes_To_XCAT

    Open Connection And Login To XCAT   ${XCAT_IP}  ${XCAT_PORT}

    ${cmd_output}=  Execute Command  ${XCAT_PATH} -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Log To Console  \n XCAT Version is: \n${cmd_output}

    # It reads out file having list of BMC nodes and adds
    # those nodes into XCAT.

    ${bmc_list}=  Get List Of BMC Nodes
    Log To Console  \n List of BMC nodes \n ${bmc_list}

    #Add Nodes To XCAT

*** Keywords ***

Get List Of BMC Nodes

    [Documentation]  Get list of BMC nodes.

    # Get the list of BMC nodes to be added.
    # This keyword expects file having list of BMC nodes
    # as an input.
    # File should have IP addresses of BMC nodes.

    OperatingSystem.File Should Exist  ${cfg_file}  msg=cfg file missing.
    File Should Not Be Empty  ${cfg_file}  msg=Empty file.

    ${bmc_list} =  OperatingSystem.Get File  ${cfg_file}
    #Log To Console  ${bmc_list}
    [Return]  ${bmc_list}
