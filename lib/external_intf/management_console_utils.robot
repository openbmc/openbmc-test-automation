*** Settings ***
Documentation    Management console utilities keywords.

Library          ../../lib/gen_robot_valid.py
Library          Collections
Library          ../../lib/bmc_ssh_utils.py
Library          SSHLibrary

*** Variables ***
&{demon_commad}  start=systemctl start avahi-daemon
                 ...  stop=systemctl stop avahi-daemon

*** Keywords *** 

Set AvahiDemon Service
    [Documentation]  To check for avahi service.
    [Arguments]  ${command}

    # Description of argument(s):
    # demon_commad    Get status command from dictionay.

    ${service_command}=  Get From Dictionary  ${demon_commad}  ${command}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Should Be Equal As Integers  ${rc}  0

