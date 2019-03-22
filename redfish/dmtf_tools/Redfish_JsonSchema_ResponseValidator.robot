*** Settings ***
Documentation     Test BMC using https://github.com/DMTF/Redfish-JsonSchema-ResponseValidator
...               DMTF tool.

Library           OperatingSystem
Resource          ../../lib/dmtf_tools_utils.robot
Resource          ../../lib/bmc_redfish_resource.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-JsonSchema-ResponseValidator
${rsv_github_url}  https://github.com/DMTF/Redfish-JsonSchema-ResponseValidator.git
${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}Redfish-JsonSchema-ResponseValidator.py
...                -r https://${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S -v

*** Test Case ***

Test BMC Redfish Using Redfish JsonSchema ResponseValidator
    [Documentation]  Check OpenBMC conformance with JsonSchema files at the DMTF site.
    [Tags]  Test_BMC_Redfish_Using_Redfish_JsonSchema_ResponseValidator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    Redfish.Login
    ${url_list}=  redfish_utils.List Request  /redfish/v1
    Redfish.Logout

    Shell Cmd  mkdir -p logs/

    Set Test Variable  ${test_run_status}  ${True}

    :FOR  ${url}  IN  @{url_list}
    \  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string} -i ${url}
    \  ${status}=  Run Keyword And Return Status  Redfish JsonSchema ResponseValidator Result  ${output}
    \  Run Keyword If  ${status} == ${False}  Set Test Variable  ${test_run_status}  ${status}
    \  Save Logs For Debugging  ${status}  ${url}

    Run Keyword If  ${test_run_status} == ${False}
    ...  Fail  Redfish-JsonSchema-ResponseValidator detected errors.


*** Keywords ***

Save Logs For Debugging
    [Documentation]  Save validate_errs on errors.
    [Arguments]      ${status}  ${url}

    # Description of arguments:
    # status    True/False.
    # url       Redfish resource path (e.g. "/redfish/v1/AccountService").

    ${validate_errs}=  Shell Cmd  cat validate_errs
    Log  ${validate_errs}

    # URL /redfish/v1/Managers/bmc strip the last ending string and save off
    # the logs for debugging "validate_errs_AccountService" and move to logs/.
    Run Keyword If  ${status} == ${False}
    ...  Shell Cmd  mv validate_errs logs/validate_errs_${url.rsplit("/")[-1]}
