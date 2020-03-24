*** Settings ***
Documentation    Management console utilities keywords.

Library          ../../lib/gen_robot_valid.py
Library          Collections
Library          ../../lib/bmc_ssh_utils.py
Library          SSHLibrary

*** Variables ***
&{daemon_commad}  start=systemctl start avahi-daemon
                  ...  stop=systemctl stop avahi-daemon
                  ...  status=systemctl status avahi-daemon -l
&{daemon_message}  start=Active: active (running)
                  ...  stop=Active: inactive (dead)

*** Keywords ***

Set AvahiDaemon Service
    [Documentation]  To enable or disable avahi service.
    [Arguments]  ${command}

    # Description of argument(s):
    # commad    Get status command from dictionay.

    ${service_command}=  Get From Dictionary  ${daemon_commad}  ${command}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Should Be Equal As Integers  ${rc}  0


Verify AvahiDaemon Service Status
    [Documentation]  To check for avahi service.
    [Arguments]  ${message}

    # Description of argument(s):
    # demon_commad    Get status command from dictionay.

    ${service_command}=  Get From Dictionary  ${daemon_commad}  status
    ${service_message}=  Get From Dictionary  ${daemon_message}  ${message}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Log  ${resp}

    Should Contain  ${resp}  ${service_message}
