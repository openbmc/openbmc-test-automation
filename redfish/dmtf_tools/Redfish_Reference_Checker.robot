*** Settings ***
Documentation             Test BMC using https://github.com/DMTF/Redfish-Reference-Checker
...                       DMTF tool.

Library                   OperatingSystem
Resource                  ../../lib/dmtf_tools_utils.robot
Resource                  ../../lib/openbmc_ffdc.robot

Test Setup                Test Setup Execution

*** Variables ***

${DEFAULT_PYTHON}         python3

${rsv_github_url}         https://github.com/DMTF/Redfish-Reference-Checker.git
${rsv_dir_path}           Redfish-Reference-Checker

${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishReferenceTool.py
...                --nochkcert 'https://${OPENBMC_HOST}:${HTTPS_PORT}/redfish/v1/$metadata'

${branch_name}    main

*** Test Cases ***

Test BMC Redfish Reference
    [Documentation]  Checks for valid reference URLs in CSDL XML files.
    [Tags]  Test_BMC_Redfish_Reference

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string}  check_error=1

    # Work complete, total failures:  0
    Should Match Regexp    ${output}  Work complete, total failures:[ ]+0
    IF  ${rc} != 0  Fail  Redfish-Reference-Checker Failed.

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}

