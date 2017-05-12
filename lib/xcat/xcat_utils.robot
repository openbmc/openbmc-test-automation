*** Settings ***

Resource    ../xcat/resource.txt

Library     SSHLibrary

*** Keywords  ***

Open Connection And Login To XCAT

    [Documentation]  Open connection and login to xCAT server.
    [Arguments]  ${xcat_ip}=" "  ${xcat_port}=" "

    # Description of arguments:
    # xcat_ip=> IP address of the XCAT server.
    # xcat_port=> Network port on which XCAT server accepts ssh session.

    Open Connection  ${xcat_ip}  port= ${xcat_port}
    Login  ${XCAT_USERNAME}  ${XCAT_PASSWORD}
