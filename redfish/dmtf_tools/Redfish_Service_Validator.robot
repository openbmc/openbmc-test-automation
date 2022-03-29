*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Service-Validator.
...                DMTF tool.

Library            OperatingSystem
Library            ../../lib/gen_robot_print.py
Resource           ../../lib/dmtf_tools_utils.robot
Resource           ../../lib/bmc_redfish_resource.robot
Resource           ../../lib/bmc_redfish_utils.robot

*** Variables ***

${DEFAULT_PYTHON}           python3
${rsv_dir_path}             Redfish-Service-Validator
${rsv_github_url}           https://github.com/DMTF/Redfish-Service-Validator.git
${cmd_str_master}=          ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py
...                         --ip https://${OPENBMC_HOST}:${HTTPS_PORT} --authtype=Session -u ${OPENBMC_USERNAME}
...                         -p ${OPENBMC_PASSWORD} --logdir ${EXECDIR}${/}${root_user_execution} --debugging
${dmtf_directory}           dmtf_tools${/}redfish_service_validator
${root_user_execution}      logs${/}${dmtf_directory}${/}Redfish_Service_Validator_With_Default_Root_User
${operator_user_execution}  logs${/}${dmtf_directory}${/}Redfish_Service_Validator_With_New_Operator_Privilege_User
${user_user_execution}      logs${/}${dmtf_directory}${/}Redfish_Service_Validator_With_New_User_Privilege_User

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    # Save the conformance logs by creating an directory in the name of test case inside openbmc-test-automation/logs directory
    Create Directory  ${EXECDIR}${/}${root_user_execution}

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd_str_master}  check_error=1

    Redfish Service Validator Result  ${output}
    Run Keyword If  ${rc} != 0  Fail  Redfish-Service-Validator Failed.


Run Redfish Service Validator With Additional Roles
    [Documentation]  Check Redfish conformance using the Redfish Service Validator.
    ...  Run the validator as additional non-admin user roles.
    [Tags]  Run_Redfish_Service_Validator_With_Additional_Roles
    [Template]  Create User And Run Service Validator

    #username      password  role        enabled
    operator_user  0penBmc1  Operator    ${True}
    readonly_user  0penBmc1  ReadOnly    ${True}


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
    ...  --ip https://${OPENBMC_HOST}:${HTTPS_PORT} --authtype=Session -u ${username}
    ...  -p ${password} --logdir ${EXECDIR}${/}logs_${username}${/} --debugging

    # Save the conformance logs by creating an directory in the name of test case inside openbmc-test-automation/logs directory
    Run Keyword If  '${role}' == 'Operator'
    ...    Creating Logs For Operator Privilege User
    ...  ELSE
    ...    Creating Logs For User Privilege User

    ${cmd}=  Catenate  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py
    ...                --ip https://${OPENBMC_HOST}:${HTTPS_PORT} --authtype=Session -u ${username}
    ...                -p ${password} --logdir ${rsv_logs_dir_path} --debugging
    Rprint Vars  cmd

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd}  check_error=1

    Redfish Service Validator Result  ${output}
    Run Keyword If  ${rc} != 0  Fail


Delete User Created
    [Documentation]  Delete user.
    [Arguments]   ${username}

    # Description of argument(s):
    # username            The username to be deleted.

    Redfish.Login
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${username}
    Redfish.Logout

Creating Logs For Operator Privilege User
    [Documentation]  Creating Logs Folder For Operator Privilege User.

    Create Directory  ${EXECDIR}${/}${operator_user_execution}
    ${rsv_logs_dir_path}  Catenate  ${EXECDIR}${/}${operator_user_execution}
    Set Global Variable  ${rsv_logs_dir_path}

Creating Logs For User Privilege User
    [Documentation]  Creating Logs Folder For User Privilege User.

    Create Directory  ${EXECDIR}${/}${user_user_execution}
    ${rsv_logs_dir_path}  Catenate  ${EXECDIR}${/}${user_user_execution}
    Set Global Variable  ${rsv_logs_dir_path}
