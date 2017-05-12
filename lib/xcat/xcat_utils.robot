*** Settings ***

Resource    ../xcat/resource.txt

Library     SSHLibrary
Library     OperatingSystem

*** Keywords  ***

Open Connection And Login To XCAT
    [Documentation]  Open connection and login to xCAT server.
    [Arguments]  ${xcat_ip}=${XCAT_HOST}  ${xcat_port}=${XCAT_PORT}

    # Description of argument(s):
    # xcat_ip   IP address of the XCAT server.
    # xcat_port Network port on which XCAT server accepts ssh session.

    Open Connection  ${xcat_ip}  port= ${xcat_port}
    Login  ${XCAT_USERNAME}  ${XCAT_PASSWORD}

Get List Of BMC Nodes
    [Documentation]  Get list of BMC nodes.

    # Get the list of BMC nodes to be added.
    # This keyword expects file having list of BMC nodes
    # as an input.
    # File should have IP addresses of BMC nodes.

    OperatingSystem.File Should Exist  ${NODE_CFG_FILE}  msg=cfg file missing.
    File Should Not Be Empty  ${NODE_CFG_FILE}  msg=Empty config file.

    ${bmc_list} =  OperatingSystem.Get File  ${NODE_CFG_FILE}
    [Return]  ${bmc_list}
