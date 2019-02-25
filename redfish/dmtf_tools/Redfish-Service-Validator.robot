*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Service-Validator.
...                DMTF tool.

Library            OperatingSystem
Library            ../../lib/gen_cmd.py
Resource           ../../lib/resource.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-Service-Validator
${rsv_github_url}  https://github.com/DMTF/Redfish-Service-Validator.git
${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py --ip ${OPENBMC_HOST}
    ...  --nochkcert --forceauth -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD}
    ...  --logdir ${EXECDIR}${/}logs${/}  --debug_logging
# ignore_err controls Shell Cmd behavior.
${ignore_err}     ${0}

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    Run DMTF Tool  ${rsv_dir_path}  ${command_string}

*** Keywords ***

Download DMTF Tool
    [Documentation]  Git clone tool.
    [Arguments]      ${rsv_dir_path}  ${rsv_github_url}

    # Description of arguments:
    # rsv_dir_path    Directory path for rsv tool (e.g. "Redfish-Service-Validator").
    # rsv_github_url  Github URL link(e.g "https://github.com/DMTF/Redfish-Service-Validator").

    ${rc}  ${output}=   Shell Cmd  rm -rf ${rsv_dir_path} ; git clone ${rsv_github_url} ${rsv_dir_path}
    Log  ${output}
    Should Be Equal As Integers  ${rc}  0

Run DMTF Tool
    [Documentation]  Execution of the command.
    [Arguments]      ${rsv_dir_path}  ${command_string}

    # Description of arguments:
    # rsv_dir_path    Directory path for rsv tool (e.g. "Redfish-Service-Validator").
    # command_string  The complete rsv command string to be run.

    ${rc}  ${output}=  Shell Cmd  ${command_string}
    Log  ${output}

    # Example:
    # Validation has failed: 9 problems found
    Should Not Contain  ${output}  Validation has failed
