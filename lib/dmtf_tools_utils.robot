*** Settings ***
Documentation   DMTF tools utility keywords.

Resource        resource.robot
Library         gen_cmd.py

*** Variables ***

# ignore_err controls Shell Cmd behavior.
${ignore_err}     ${0}

*** Keywords ***

Download DMTF Tool
    [Documentation]  Git clone tool.
    [Arguments]      ${rsv_dir_path}  ${rsv_github_url}

    # Description of arguments:
    # rsv_dir_path    Directory path for rsv tool (e.g. "Redfish_Service_Validator").
    # rsv_github_url  Github URL link(e.g "https://github.com/DMTF/Redfish_Service_Validator").

    ${rc}  ${output}=  Shell Cmd  rm -rf ${rsv_dir_path} ; git clone ${rsv_github_url} ${rsv_dir_path}


Run DMTF Tool
    [Documentation]  Execution of the command.
    [Arguments]      ${rsv_dir_path}  ${command_string}

    # Description of arguments:
    # rsv_dir_path    Directory path for rsv tool (e.g. "Redfish_Service_Validator").
    # command_string  The complete rsv command string to be run.

    ${rc}  ${output}=  Shell Cmd  ${command_string}
    Log  ${output}
    [Return]  ${output}


Redfish Service Validator Result
    [Documentation]  Check tool output for errors.
    [Arguments]      ${tool_output}

    # Example:
    # Validation has failed: 9 problems found
    Should Not Contain  ${tool_output}  Validation has failed


Redfish JsonSchema ResponseValidator Result
    [Documentation]  Check tool output for errors.
    [Arguments]      ${tool_output}

    # Example:
    # 0 errors
    Should Contain  ${tool_output}  0 errors

