*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Service-Validator.
...                DMTF tool.

Library            OperatingSystem
Library            ../../lib/gen_robot_print.py
Resource           ../../lib/dmtf_tools_utils.robot
Resource           ../../lib/bmc_redfish_resource.robot
Resource           ../../lib/bmc_redfish_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-Service-Validator
${rsv_github_url}  https://github.com/DMTF/Redfish-Service-Validator.git
${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py
...                --ip ${OPENBMC_HOST} --nochkcert --forceauth -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD} --logdir ${EXECDIR}${/}logs${/} --debug_logging

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string}

    Redfish Service Validator Result  ${output}


Test BMC Redfish Using Redfish Service Validator With Users
    [Documentation]  Check conformance with a Redfish service interface using
    ...  differnt user roles.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator_With_Users
    [Template]  Create User And Run Service Validator

    #username      password             role_id         enabled
    operator_user  ${OPENBMC_PASSWORD}  Operator        ${True}
    #readonly_user  ${OPENBMC_PASSWORD}  ReadOnly        ${True}


*** Keywords ***

Create User And Run Service Validator
    [Documentation]  Create user and run validator.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}
    [Teardown]  Delete User Created  ${username}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish.Login
    Redfish Create User  ${username}  ${password}  ${role_id}  ${enabled}
    Redfish.Logout

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${cmd}=  Catenate  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py
    ...  --ip ${OPENBMC_HOST} --nochkcert --forceauth -u ${username}
    ...  -p ${password} --logdir ${EXECDIR}${/}logs_${username}${/} --debug_logging

    Rprint Vars  cmd

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd}

    Redfish Service Validator Result  ${output}


Delete User Created
    [Documentation]  Delete user.
    [Arguments]   ${username}

    # Description of argument(s):
    # username            The username to be delete.

    Redfish.Login
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}
    Redfish.Logout
