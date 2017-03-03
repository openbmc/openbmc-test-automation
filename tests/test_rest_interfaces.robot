*** Settings ***
Documentation     Verify REST services Get/Put/Post/Delete.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/resource.txt
Library           Collections
Test Teardown     FFDC On Test Case Fail

*** Variables ***

*** Test Cases ***

Get Response Codes
    [Documentation]  REST "Get" response status test.
    #--------------------------------------------------------------------
    # Expect status      URL Path
    #--------------------------------------------------------------------
    ${HTTP_OK}           /
    ${HTTP_OK}           /xyz/
    ${HTTP_OK}           /xyz/openbmc_project/
    ${HTTP_OK}           /xyz/openbmc_project/enumerate
    ${HTTP_NOT_FOUND}    /i/dont/exist/

    [Tags]  Get_Response_Codes
    [Template]  Execute Get And Check Response


Get Data
    [Documentation]  REST "Get" request url and expect the
    ...              response OK and data non empty.
    #--------------------------------------------------------------------
    # URL Path
    #--------------------------------------------------------------------
    /xyz/openbmc_project/
    /xyz/openbmc_project/list
    /xyz/openbmc_project/enumerate

    [Tags]  Get_Data
    [Template]  Execute Get And Check Data


Get Data Validation
    [Documentation]  REST "Get" request url and expect the
    ...              pre-defined string in response data.
    #--------------------------------------------------------------------
    # URL Path                  Expect Data
    #--------------------------------------------------------------------
    /xyz/openbmc_project/       /xyz/openbmc_project/logging
    /i/dont/exist/              path or object not found: /i/dont/exist

    [Tags]  Get_Data_Validation
    [Template]  Execute Get And Verify Data


Put Response Codes
    [Documentation]  REST "Put" request url and expect the REST pre-defined
    ...              codes.
    #--------------------------------------------------------------------
    # Expect status                 URL Path
    #--------------------------------------------------------------------
    ${HTTP_METHOD_NOT_ALLOWED}      /
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/
    ${HTTP_METHOD_NOT_ALLOWED}      /i/dont/exist/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/list
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/enumerate

    [Tags]  Put_Response_Codes
    [Template]  Execute Put And Check Response


Put Data Validation
    [Documentation]  REST "Put" request url and expect success.
    #--------------------------------------------------------------------
    # URL Path                      Parm Data
    #--------------------------------------------------------------------
    /xyz/openbmc_project/state/host0/attr/RequestedHostTransition    xyz.openbmc_project.State.Host.Transition.Off

    [Tags]  Put_Data_Validation
    [Template]  Execute Put And Expect Success


Post Response Code
    [Documentation]  REST Post request url and expect the
    ...              REST response code pre define.
    #--------------------------------------------------------------------
    # Expect status                 URL Path
    #--------------------------------------------------------------------
    ${HTTP_METHOD_NOT_ALLOWED}      /
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/
    ${HTTP_METHOD_NOT_ALLOWED}      /i/dont/exist/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/enumerate

    [Tags]  Post_Response_Codes
    [Template]  Execute Post And Check Response


Delete Response Code
    [Documentation]  REST "Delete" request url and expect the
    ...              REST response code pre define.
    #--------------------------------------------------------------------
    # Expect status                 URL Path
    #--------------------------------------------------------------------
    ${HTTP_METHOD_NOT_ALLOWED}      /
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/nothere/
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/enumerate
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/openbmc_project/list
    ${HTTP_METHOD_NOT_ALLOWED}      /xyz/openbmc_project/enumerate

    [Tags]  Delete_Response_Codes
    [Template]  Execute Delete And Check Response


*** Keywords ***

Execute Get And Check Response
    [Documentation]  Request "Get" url path and expect REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Get Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}

Execute Get And Check Data
    [Documentation]  Request "Get" url path and expect non empty data.
    [Arguments]  ${url_path}
    # Description of arguments:
    # url_path     URL path.
    ${resp}=  Openbmc Get Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}

Execute Get And Verify Data
    [Documentation]  Request "Get" url path and verify data.
    [Arguments]  ${url_path}  ${expected_response_code}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Get Request  ${url_path}
    ${jsondata}=  To JSON  ${resp.content}
    Run Keyword If  '${resp.status_code}' == '${HTTP_OK}'
    ...  Should Contain  ${jsondata["data"]}  ${expected_response_code}
    ...  ELSE
    ...  Should Contain  ${jsondata["data"]["description"]}  ${expected_response_code}

Execute Put And Check Response
    [Documentation]  Request "Put" url path and expect REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Put Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}

Execute Put And Expect Success
    [Documentation]  Request "Put" on url path.
    [Arguments]  ${url_path}  ${parm}
    # Description of arguments:
    # url_path     URL path.
    # parm         Value/string to be set.
    # expected_response_code   Expected REST status codes.
    ${parmDict}=  Create Dictionary  data=${parm}
    ${resp}=  Openbmc Put Request  ${url_path}  data=${parmDict}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Execute Post And Check Response
    [Documentation]  Request Post url path and expect REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.
    ${resp}=  Openbmc Post Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}

Execute Post And Check Data
    [Arguments]  ${url_path}  ${parm}
    [Documentation]  Request Post on url path and expected non empty data.
    # Description of arguments:
    # url_path     URL path.
    ${data}=  Create Dictionary   data=@{data}
    ${resp}=  Openbmc Post Request  ${url_path}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}

Execute Delete And Check Response
    [Documentation]  Request "Delete" url path and expected REST response code.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path     URL path.
    ${resp}=  Openbmc Delete Request  ${url_path}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}
