*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Usecase-Checkers
...                DMTF tool.

Library            OperatingSystem
Resource           ../../lib/dmtf_tools_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3

${rsv_github_url}  https://github.com/DMTF/Redfish-Usecase-Checkers.git
${rsv_dir_path}    Redfish-Usecase-Checkers

${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}account_management/account_management.py
...                -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD} -S Always -d ${EXECDIR}${/}logs${/} -v


*** Test Case ***

Test BMC Redfish Account Management
    [Documentation]  Check Account Management with a Redfish interface.
    [Tags]  Test_BMC_Redfish_Account_Management

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string}
    Log  ${output}

    ${output}=  Shell Cmd  cat ${EXECDIR}${/}logs${/}results.json
    Log  ${output}
