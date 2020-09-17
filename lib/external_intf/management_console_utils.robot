*** Settings ***
Documentation    Management console utilities keywords.

Library          ../../lib/gen_robot_valid.py
Library          Collections
Library          ../../lib/bmc_ssh_utils.py
Library          SSHLibrary

*** Variables ***
&{daemon_command}  start=systemctl start avahi-daemon
                  ...  stop=systemctl stop avahi-daemon
                  ...  status=systemctl status avahi-daemon -l
&{daemon_message}  start=Active: active (running)
                  ...  stop=Active: inactive (dead)

*** Keywords ***

Set AvahiDaemon Service
    [Documentation]  To enable or disable avahi service.
    [Arguments]  ${command}

    # Description of argument(s):
    # command  Get command from dictionary.

    ${service_command}=  Get From Dictionary  ${daemon_command}  ${command}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Should Be Equal As Integers  ${rc}  0


Verify AvahiDaemon Service Status
    [Documentation]  To check for avahi service.
    [Arguments]  ${message}

    # Description of argument(s):
    # message  Get status message from dictionary.

    ${service_command}=  Get From Dictionary  ${daemon_command}  status
    ${service_message}=  Get From Dictionary  ${daemon_message}  ${message}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Should Contain  ${resp}  ${service_message}


Get Lock Resource Information
    [Documentation]  Get lock resource information.

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${resource_lock_json}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/resource_lock_table.json'))  modules=json
    Rprint Vars  resource_lock_json

    [Return]  ${resource_lock_json}
