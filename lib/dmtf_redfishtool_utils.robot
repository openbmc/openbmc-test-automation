*** Settings ***


Documentation   Utilities for Redfishtool testing.

Resource        resource.robot
Resource        bmc_redfish_resource.robot
Library         OperatingSystem
Library         String
Library         Collections


*** Keywords ***

Redfishtool Get
    [Documentation]  Execute redfishtool for GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=200

    # Description of argument(s):
    # uri             URI for GET operation (e.g. /redfish/v1/AccountService/Accounts/).
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${cmd}=  Catenate  ${cmd_args} GET ${uri}
    Log  ${cmd}
    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Redfishtool Patch
    [Documentation]  Execute redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=200

    # Description of argument(s):
    # payload         Payload with POST operation (e.g. data for user name, role, etc. ).
    # uri             URI for PATCH operation (e.g. /redfish/v1/AccountService/Accounts/ ).
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${cmd}=  Catenate  ${cmd_args} PATCH ${uri} --data=${payload}
    Log  ${cmd}
    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Redfishtool Post
    [Documentation]  Execute redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=200

    # Description of argument(s):
    # payload         Payload with POST operation (e.g. data for user name, password, role,
    #                 enabled attribute)
    # uri             URI for POST operation (e.g. /redfish/v1/AccountService/Accounts/).
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${cmd}=  Catenate  ${cmd_args} POST ${uri} --data=${payload}
    Log  ${cmd}
    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Redfishtool Delete
    [Documentation]  Execute redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=200

    # Description of argument(s):
    # uri             URI for DELETE operation.
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${cmd}=  Catenate  ${cmd_args} DELETE ${uri}
    Log  ${cmd}
    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Is HTTP error Expected
    [Documentation]  Check if the HTTP error is expected.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    ${cmd_rsp}=  Get Regexp Matches  ${cmd_output}  200|204
    ${cmd_rsp_status}=  Run Keyword And Return Status  Should Not Be Empty  ${cmd_rsp}
    Return From Keyword IF  ${cmd_rsp_status} == True
    ${matches}=  Get Regexp Matches  ${error_expected}  200|204
    ${rsp_status}=  Run Keyword And Return Status  Should Be Empty  ${matches}
    Run Keyword If  ${rsp_status} == False
    ...  Fail  msg=${cmd_output}
    @{words} =  Split String  ${error_expected}  ,
    @{errorString}=  Split String  ${cmd_output}  ${SPACE}
    FOR  ${error}  IN  @{words}
      ${status}=  Run Keyword And Return Status  Should Contain Any  ${errorString}  ${error}
      Return From Keyword If  ${status} == True
    END
    ${rsp_code}=  Run Keyword If  ${status} == False  Get Regexp Matches  ${cmd_output}  [0-9][0-9][0-9]
    ${rsp_code_status}=  Run Keyword And Return Status  Should Not Be Empty  ${rsp_code}
    Run Keyword If  ${rsp_code_status} == True
    ...    Fail  msg=Getting status code as ${rsp_code[0]} instead of ${error_expected}, status code mismatch.
    ...  ELSE
    ...    Fail  msg=${cmd_output}

