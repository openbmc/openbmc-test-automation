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
${cmd_str_master}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py
...                --ip https://${OPENBMC_HOST}:${HTTPS_PORT} --authtype=Session -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD} --logdir ${EXECDIR}${/}logs${/} --debugging

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd_str_master}

    Redfish Service Validator Result  ${output}


Run Redfish Service Validator With Additional Roles
    [Documentation]  Check Redfish conformance using the Redfish Service Validator.
    ...  Run the validator as additional non-admin user roles.
    [Tags]  Run_Redfish_Service_Validator_With_Additional_Roles
    [Template]  Create User And Run Service Validator

    #username      password             role        enabled
    operator_user  ${OPENBMC_PASSWORD}  Operator    ${True}
    readonly_user  ${OPENBMC_PASSWORD}  ReadOnly    ${True}


*** Keywords ***

Create User And Run Service Validator
    [Documentation]  Create user and run validator.
    [Arguments]   ${username}  ${password}  ${role}  ${enabled}
    [Teardown]  Delete User Created  ${username}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role                The role of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Redfish.Login
    Redfish Create User  ${username}  ${password}  ${role}  ${enabled}
    Redfish.Logout

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${cmd}=  Catenate  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py
    ...  --ip ${OPENBMC_HOST}:${HTTPS_PORT} --nochkcert --authtype=Session -u ${username}
    ...  -p ${password} --logdir ${EXECDIR}${/}logs_${username}${/} --debug_logging

    Rprint Vars  cmd

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd}

    Redfish Service Validator Result  ${output}


Delete User Created
    [Documentation]  Delete user.
    [Arguments]   ${username}

    # Description of argument(s):
    # username            The username to be deleted.

    Redfish.Login
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}
    Redfish.Logout
