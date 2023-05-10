*** Settings ***
Documentation   DMTF tools utility keywords.

Resource        resource.robot
Library         gen_cmd.py
Library         utils.py
Variables       ../data/oem_uri_list.py

*** Variables ***

# ignore_err controls Shell Cmd behavior.
${ignore_err}     ${0}

*** Keywords ***

Download DMTF Tool
    [Documentation]  Git clone tool.
    [Arguments]      ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}

    # Description of arguments:
    # rsv_dir_path    Directory path for rsv tool (e.g. "Redfish-Service-Validator").
    # rsv_github_url  Github URL link(e.g "https://github.com/DMTF/Redfish-Service-Validator").

    ${cmd_buf}  Catenate  rm -rf ${rsv_dir_path} ;
    ...  git clone --branch ${branch_name} ${rsv_github_url} ${rsv_dir_path}
    ${rc}  ${output}=  Shell Cmd  ${cmd_buf}


Run DMTF Tool
    [Documentation]  Execution of the command.
    [Arguments]      ${rsv_dir_path}  ${command_string}  ${check_error}=0

    # Description of arguments:
    # rsv_dir_path    Directory path for rsv tool (e.g. "Redfish-Service-Validator").
    # command_string  The complete rsv command string to be run.
    # check_error     It decides if error information is to be checked.

    ${rc}  ${output}=  Shell Cmd  ${command_string}  ignore_err=${check_error}
    Log  ${output}
    [Return]  ${rc}  ${output}


Redfish Service Validator Result
    [Documentation]  Check tool output for errors.
    [Arguments]      ${tool_output}

    # Example:
    # Validation has failed: 9 problems found
    # Service could not be started: RetriesExhaustedError()
    Should Not Contain Any  ${tool_output}  Validation has failed
    ...  Service could not be started: RetriesExhaustedError()


Redfish JsonSchema ResponseValidator Result
    [Documentation]  Check tool output for errors.
    [Arguments]      ${tool_output}

    # Example:
    # 0 errors
    Should Contain  ${tool_output}  0 errors


Get OEM URI List And Non OEM URI List
    [Documentation]  returns oem uri list and non oem uri list.
    [Arguments]  ${urls}

    # Description of arguments:
    # url_list  master url list that has all redfish uri's.

    @{oem_url}=  Create List

    # Get OEM URI's as a list from data/oem_uri_list.py
    ${oem_uris}=  Set Variable  ${URI}

    FOR  ${oem_uri}  IN  @{oem_uris}
      # Get index value for the related oem uri's from master uri list.
      # For example, Consider /redfish/v1/Chassis is an OEM URI
      # All the subsequent uri's index such as /redfish/v1/Chassis/chassis,
      # /redfish/v1/Chassis/chassis/Power and /redfish/v1/Chassis/chassis/Thermal will be returned.
      ${indexes}=  Get Subsequent Value From List  ${urls}  ${oem_uri}
      FOR  ${index}  IN  @{indexes}
        # With that index value all the respective oem uri's will be appended to tmp_list.
        ${uri}=  Get From List  ${urls}  ${index}
        Append To List  ${oem_url}  ${uri}
      END
      FOR  ${uri}  IN  @{oem_url}
        # oem uri's will be removed from master uri list to avoid failures during validation.
        Remove Values From List  ${urls}  ${uri}
      END
    END

    [Return]  ${oem_url}  ${urls}