*** Settings ***
Documentation             Test BMC using
...                       https://github.com/DMTF/Redfish-Protocol-Validator
...                       DMTF tool.

Library                   OperatingSystem
Resource                  ../../lib/dmtf_tools_utils.robot

Test Setup                Test Setup Execution

*** Variables ***

${DEFAULT_PYTHON}         python3

${rsv_github_url}         https://github.com/DMTF/Redfish-Protocol-Validator
${rsv_dir_path}           Redfish-Protocol-Validator

${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}rf_protocol_validator.py
...                -r ${OPENBMC_HOST}:${HTTPS_PORT}
...                -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD}
...                --no-cert-check
...

${branch_name}    main

*** Test Cases ***

Test BMC Redfish Protocol Validator
    [Documentation]  The Redfish Protocol Validator tests the HTTP protocol
    ...              behavior of a Redfish service to validate that it
    ...              conforms to the Redfish Specification.
    [Tags]  Test_BMC_Redfish_Protocol_Validator

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string}  check_error=1

    # Example output and fail count regex:
    # Summary - PASS: 61, WARN: 1, FAIL: 42, NOT_TESTED: 60
    # Fail count group returned from regex ['FAIL: 42', '42']

    ${fail_count}=  Should Match Regexp  ${output}  FAIL: (\\d+)

    Run Keyword If  ${fail_count[1]} != 0
    ...  Fail  Redfish Protocol Validator Failed


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}
