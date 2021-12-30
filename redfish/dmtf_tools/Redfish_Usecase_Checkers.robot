*** Settings ***
Documentation             Test BMC using https://github.com/DMTF/Redfish-Usecase-Checkers
...                       DMTF tool.

Library                   OperatingSystem
Library                   ../../lib/state.py
Resource                  ../../lib/dmtf_tools_utils.robot
Resource                  ../../lib/openbmc_ffdc.robot

Test Setup                Test Setup Execution
Test Teardown             Test Teardown Execution

*** Variables ***

${DEFAULT_PYTHON}         python3

${rsv_github_url}         https://github.com/DMTF/Redfish-Usecase-Checkers.git
${rsv_dir_path}           Redfish-Usecase-Checkers

${command_account}        ${DEFAULT_PYTHON} ${rsv_dir_path}${/}account_management/account_management.py
...                       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} -S Always -d ${EXECDIR}${/}logs${/}

${command_power_control}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}power_control/power_control.py
...                       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} -S Always

${power_on_timeout}       15 mins
${power_off_timeout}      15 mins
${state_change_timeout}   3 mins

*** Test Case ***

Test BMC Redfish Account Management
    [Documentation]  Check Account Management with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Account_Management

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_account}  check_error=1

    ${output}=  Shell Cmd  cat ${EXECDIR}${/}logs${/}results.json
    Log  ${output}

    ${json}=  OperatingSystem.Get File    ${EXECDIR}${/}logs${/}results.json

    ${object}=  Evaluate  json.loads('''${json}''')  json

    ${result_list}=  Set Variable  ${object["TestResults"]}

    @{failed_tc_list}=    Create List

    FOR  ${result}  IN  @{result_list}
       ${rc}=    evaluate    'ErrorMessages'=='${result}'
       ${num}=  Run Keyword If  ${rc} == False  Set Variable  ${result_list["${result}"]["fail"]}
       Run Keyword If  ${num} != None and ${num} > 0  Append To List  ${failed_tc_list}   ${result}
    END

    Should Be Empty  ${failed_tc_list}  Failed test cases are ${failed_tc_list}


Test BMC Redfish Power Control Usecase
    [Documentation]  Power Control Usecase Test.
    [Tags]  Test_BMC_Redfish_Power_Control_Usecases

    DMTF Power


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    Printn
    FFDC On Test Case Fail


DMTF Power
    [Documentation]  Power the BMC machine on via DMTF tools.

    Print Timen  Doing "DMTF Power".

    Run DMTF Tool  ${rsv_dir_path}  ${command_power_control}


