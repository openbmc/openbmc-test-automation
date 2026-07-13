*** Settings ***
Documentation             Test BMC using https://github.com/DMTF/Redfish-Usecase-Checkers
...                       DMTF tool.

Resource                  ../../lib/resource.robot
Resource                  ../../lib/dmtf_tools_utils.robot
Resource                  ../../lib/openbmc_ffdc.robot
Library                   OperatingSystem
Library                   ../../lib/state.py

Test Setup                Test Setup Execution
Test Teardown             Test Teardown Execution

Test Tags                 Redfish_Usecase_Checkers

*** Variables ***

${DEFAULT_PYTHON}         python3

${rsv_github_url}         https://github.com/DMTF/Redfish-Usecase-Checkers.git
${rsv_dir_path}           Redfish-Usecase-Checkers

${command_account}        ${DEFAULT_PYTHON} ${rsv_dir_path}${/}rf_use_case_checkers.py
...                       -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} --test-list AccountManagement

${command_power_control}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}rf_use_case_checkers.py
...                       -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} --test-list PowerControl

${command_boot_override}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}rf_use_case_checkers.py
...                       -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} --test-list BootOverride

${command_manager_ethernet}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}rf_use_case_checkers.py
...                          -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME}
...                          -p ${OPENBMC_PASSWORD} --test-list ManagerEthernetInterfaces

${command_query_parameters}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}rf_use_case_checkers.py
...                          -r https://${OPENBMC_HOST}:${HTTPS_PORT} -u ${OPENBMC_USERNAME}
...                          -p ${OPENBMC_PASSWORD} --test-list QueryParameters

${power_on_timeout}       15 mins
${power_off_timeout}      15 mins
${state_change_timeout}   3 mins
${branch_name}            main

*** Test Cases ***

Test BMC Redfish Account Management
    [Documentation]  Check Account Management with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Account_Management

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_account}  check_error=1

    Should Be Equal        ${rc}  ${0}
    Should Match Regexp    ${output}  Summary - PASS: \\d+, WARN: \\d+, FAIL: 0, NOT TESTED: \\d+


Test BMC Redfish Power Control Usecase
    [Documentation]  Power Control Usecase Test.
    [Tags]  Test_BMC_Redfish_Power_Control_Usecase

    DMTF Power


Test BMC Redfish Boot Override Usecase
    [Documentation]  Check Boot Override usecase with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Boot_Override_Usecase

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_boot_override}  check_error=1

    Should Be Equal        ${rc}  ${0}
    Should Match Regexp    ${output}  Summary - PASS: \\d+, WARN: \\d+, FAIL: 0, NOT TESTED: \\d+


Test BMC Redfish Manager Ethernet Interfaces Usecase
    [Documentation]  Check Manager Ethernet Interfaces usecase with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Manager_Ethernet_Interfaces_Usecase

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_manager_ethernet}  check_error=1

    Should Be Equal        ${rc}  ${0}
    Should Match Regexp    ${output}  Summary - PASS: \\d+, WARN: \\d+, FAIL: 0, NOT TESTED: \\d+


Test BMC Redfish Query Parameters Usecase
    [Documentation]  Check Query Parameters usecase with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Query_Parameters_Usecase

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_query_parameters}  check_error=1

    Should Be Equal        ${rc}  ${0}
    Should Match Regexp    ${output}  Summary - PASS: \\d+, WARN: \\d+, FAIL: 0, NOT TESTED: \\d+


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    Printn
    FFDC On Test Case Fail


DMTF Power
    [Documentation]  Power the BMC machine on via DMTF tools.

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_power_control}  check_error=1
    Log  ${rc}
    Log  ${output}

    Should Be Equal        ${rc}  ${0}
    Should Match Regexp    ${output}    Summary - PASS: \\d+, WARN: \\d+, FAIL: 0, NOT TESTED: \\d+
