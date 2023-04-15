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

*** Variables ***

${DEFAULT_PYTHON}         python3

${rsv_github_url}         https://github.com/DMTF/Redfish-Usecase-Checkers.git
${rsv_dir_path}           Redfish-Usecase-Checkers

${command_account}        ${DEFAULT_PYTHON} ${rsv_dir_path}${/}account_management/account_management.py
...                       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} -S Always -d ${EXECDIR}${/}account-logs${/}

${command_power_control}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}power_control/power_control.py
...                       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME}
...                       -p ${OPENBMC_PASSWORD} -S Always -d ${EXECDIR}${/}power-logs${/}

${power_on_timeout}       15 mins
${power_off_timeout}      15 mins
${state_change_timeout}   3 mins
${branch_name}            main

*** Test Case ***

Test BMC Redfish Account Management
    [Documentation]  Check Account Management with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Account_Management

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_account}  check_error=1

    ${output}=  Shell Cmd  cat ${EXECDIR}${/}account-logs${/}results.json
    Log  ${output}

    ${json}=  OperatingSystem.Get File    ${EXECDIR}${/}account-logs${/}results.json

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
    [Tags]  Test_BMC_Redfish_Power_Control_Usecase

    DMTF Power


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

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_power_control}  check_error=1
    Log  ${output}

    ${json}=  OperatingSystem.Get File    ${EXECDIR}${/}power-logs${/}results.json

    ${object}=  Evaluate  json.loads('''${json}''')  json

    ${result_list}=  Set Variable  ${object["TestResults"]}
    Log To Console  result: ${result_list}

    @{failed_tc_list}=    Create List
    @{error_messages}=    Create List

    FOR  ${result}  IN  @{result_list}
       ${rc}=    evaluate    'ErrorMessages'=='${result}'
       ${num}=  Run Keyword If  ${rc} == False  Set Variable  ${result_list["${result}"]["fail"]}
       Run Keyword If  ${num} != None and ${num} > 0  Append To List  ${failed_tc_list}   ${result}
       Run Keyword If  ${rc} == True   Set Variable
       ...  Append To List  ${error_messages}  ${result_list["ErrorMessages"]}
    END

    Log Many            ErrorMessages:   @{error_messages}
    Log To Console      ErrorMessages:
    FOR   ${msg}  IN  @{error_messages}
       Log To Console   ${msg}
    END

    Should Be Empty  ${error_messages}   DMTF Power keyword failed.
