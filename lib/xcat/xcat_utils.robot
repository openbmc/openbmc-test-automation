*** Settings ***

Resource    ../xcat/resource.txt
Resource    ../../lib/resource.txt

Library     SSHLibrary
Library     OperatingSystem
Library     String

*** Keywords  ***

Open Connection And Login To XCAT
    [Documentation]  Open connection and login to xCAT server.
    [Arguments]  ${xcat_host}=${XCAT_HOST}  ${xcat_port}=${XCAT_PORT}

    # Description of argument(s):
    # xcat_host  IP address of the XCAT server.
    # xcat_port  Network port on which XCAT server accepts ssh session.

    Open Connection  ${xcat_host}  port=${xcat_port}
    Login  ${XCAT_USERNAME}  ${XCAT_PASSWORD}

Get List Of BMC Nodes
    [Documentation]  Get list of BMC nodes.
    [Arguments]  ${node_cfg_file_path}=${NODE_CFG_FILE_PATH}

    # Get the list of BMC nodes to be added.
    # This keyword expects file having list of BMC nodes
    # as an input.
    # File should have IP addresses of BMC nodes.

    OperatingSystem.File Should Exist  ${node_cfg_file_path}  msg=cfg file missing.
    File Should Not Be Empty  ${node_cfg_file_path}  msg=Empty config file.

    ${bmc_list} =  OperatingSystem.Get File  ${node_cfg_file_path}
    [Return]  ${bmc_list}

Add Nodes To XCAT
    [Documentation]  Add nodes to XCAT.
    [Arguments]  ${node}=" "  ${username}=${OPENBMC_USERNAME}
    ...          ${password}=${OPENBMC_PASSWORD}

    ${cmd}=  Set Variable  ${XCAT_DIR_PATH}/mkdef
    ${cmd_parm1}=  Set Variable  ${node} bmc=${node} bmcusername=${username}
    ${cmd_parm2}=  Set Variable  bmcpassword=${password} mgt=openbmc groups=all
    ${full_cmd}=  Catenate  ${cmd}  ${cmd_parm1}  ${cmd_parm2}
    Execute Command  ${full_cmd}

Validate Added Node
    [Documentation]  Validate added node.
    [Arguments]  ${node}=" "

    # Description of the argument(s):
    # ${node}  Name of the node, it is to check whether node is added into XCAT data base.

    ${cmd_output}=  Execute Command  ${XCAT_DIR_PATH}/nodels
    Should Contain  ${cmd_output}  ${node}  msg=Node is not added.

Power On Via XCAT
    [Documentation]  Power on via XCAT.
    [Arguments]  ${node}=" "

    # Description of the argument(s):
    # ${node}  Name of the node.

    ${stdout}  ${stderr}=  Execute Command  ${XCAT_DIR_PATH}/rpower ${node} on
    ...  return_stderr=True
    Should Be Empty  ${stderr}

Power Off Via XCAT
    [Documentation]  Power off via XCAT.
    [Arguments]  ${node}=" "

    # Description of the argument(s):
    # ${node}  Name of the node.

    ${stdout}  ${stderr}=  Execute Command  ${XCAT_DIR_PATH}/rpower ${node} off
    ...  return_stderr=True
    Should Be Empty  ${stderr}

Get Power Status
    [Documentation]  Get power status via XCAT.
    [Arguments]  ${node}=" "

    # Description of the argument(s):
    # ${node}  Name of the node.

    ${stdout}  ${stderr}=  Execute Command  ${XCAT_DIR_PATH}/rpower ${node} state
    ...  return_stderr=True
    Should Be Empty  ${stderr}

    [Return]  ${stdout}
