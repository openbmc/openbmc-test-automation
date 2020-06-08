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


Test BMC Redfish Boot Host And ForceOff
    [Documentation]  Boot host and ForceOff.
    [Tags]  Test_BMC_Redfish_Boot_Host_And_ForceOff

    DMTF Power On
    DMTF Hard Power Off


Test BMC Redfish Boot Host And GracefulShutdown
    [Documentation]  Boot host and issue GracefulShutdown.
    [Tags]  Test_BMC_Redfish_Boot_Host_And_GracefulShutdown

    DMTF Power On
    DMTF Power Off


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${status}  ${state}=  Run Keyword And Ignore Error
    ...  Check State  standby_match_state
    Return From Keyword If  '${status}' == 'PASS'
    DMTF Power Off


Test Teardown Execution
    [Documentation]  Do the post-test teardown.

    Printn
    FFDC On Test Case Fail


DMTF Power On
    [Documentation]  Power the BMC machine on via DMTF tools.

    Print Timen  Doing "DMTF Power On".

    ${state}=  Get State
    ${match_state}=  Anchor State  ${state}
    Run DMTF Tool  ${rsv_dir_path}  ${command_power_control} On
    ${state}=  Wait State  ${match_state}  wait_time=${state_change_timeout}  interval=10 seconds  invert=1
    ${state}=  Wait State  os_running_match_state  wait_time=${power_on_timeout}  interval=10 seconds

    [Return]  ${state}


DMTF Power Off
    [Documentation]  Power the BMC machine off via DMTF tools.

    Print Timen  Doing "DMTF Hard Power Off".

    ${state}=  Get State
    ${match_state}=  Anchor State  ${state}
    Run DMTF Tool  ${rsv_dir_path}  ${command_power_control} GracefulShutdown
    ${state}=  Wait State  ${match_state}  wait_time=${state_change_timeout}  interval=10 seconds  invert=1
    ${state}=  Wait State  standby_match_state  wait_time=${power_off_timeout}  interval=10 seconds

    [Return]  ${state}


DMTF Hard Power Off
    [Documentation]  Power the BMC machine off via DMTF tools.

    Print Timen  Doing "DMTF Hard Power Off".

    ${state}=  Get State
    ${match_state}=  Anchor State  ${state}
    Run DMTF Tool  ${rsv_dir_path}  ${command_power_control} ForceOff
    ${state}=  Wait State  ${match_state}  wait_time=${state_change_timeout}  interval=10 seconds  invert=1
    ${state}=  Wait State  standby_match_state  wait_time=${power_off_timeout}  interval=10 seconds

    [Return]  ${state}
