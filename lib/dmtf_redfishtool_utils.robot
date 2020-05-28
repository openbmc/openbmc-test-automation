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

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} GET ${uri}
    Run Keyword If  ${rc} == 0
    ...    Should Be True  ${expected_error} == 200
    ...  ELSE
    ...    Is HTTP error Expected  ${cmd_output}  ${expected_error}

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

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} PATCH ${uri} --data=${payload}
    Run Keyword If  ${rc} == 0
    ...    Should Be True  ${expected_error} == 200
    ...  ELSE
    ...    Is HTTP error Expected  ${cmd_output}  ${expected_error}

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

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} POST ${uri} --data=${payload}
    Run Keyword If  ${rc} == 0
    ...    Should Be True  ${expected_error} == 200
    ...  ELSE
    ...    Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Redfishtool Delete
    [Documentation]  Execute redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=200

    # Description of argument(s):
    # uri             URI for DELETE operation.
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} DELETE ${uri}
    Run Keyword If  ${rc} == 0
    ...    Should Be True  ${expected_error} == 200
    ...  ELSE
    ...    Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Is HTTP error Expected
    [Documentation]  Check if the HTTP error is expected.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    Should Be True  ${error_expected} != 200
    @{words} =  Split String  ${error_expected}  ,
    @{errorString}=  Split String  ${cmd_output}  ${SPACE}
    Should Contain Any  ${errorString}  @{words}
