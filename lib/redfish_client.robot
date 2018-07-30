*** Settings ***
Library           Collections
Library           String
Library           RequestsLibrary.RequestsKeywords
Library           OperatingSystem
Resource          resource.txt
Library           disable_warning_urllib.py
Resource          rest_response_code.robot

*** Variables ***

# Assign default value to QUIET for programs which may not define it.
${QUIET}          ${0}

*** Keywords ***

Redfish Login Request
    [Documentation]  Do REST login and return authorization token.
    [Arguments]  ${timeout}=20

    # Description of argument(s):
    # timeout  REST login attempt time out.

    Create Session  openbmc  ${AUTH_URI}  timeout=${timeout}
    ${headers}=  Create Dictionary  Content-Type=application/json

    ${data}=  Create Dictionary
    ...  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}

    ${resp}=  Post Request  openbmc
    ...  ${REDFISH_SESSION}  data=${data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Log  ${resp.headers["X-Auth-Token"]}

    [Return]  ${resp.headers["X-Auth-Token"]}


Redfish Get Request
    [Documentation]  Do REST GET request and return the result.
    [Arguments]  ${uri_suffix}  ${xauth_token}=None  ${response_type}=json  ${timeout}=30

    # Description of argument(s):
    # uri_suffix      The URI to establish connection with
    #                 (e.g. 'Systems').
    # xauth_token     Authentication token.
    # response_type   Indicates that this keyword should return JSON response.
    # timeout         Timeout in seconds to establish connection with URI.

    ${xauth_token} =  Run Keyword If  ${xauth_token} == ${None}
    ...  Redfish Login Request

    ${base_uri} =  Catenate  SEPARATOR=  ${REDFISH_BASE_URI}  ${uri_suffix}

    # Example: "X-Auth-Token: 3la1JUf1vY4yN2dNOwun"
    ${headers} =  Create Dictionary  Content-Type=application/json
    ...  X-Auth-Token=${xauth_token}
    ${resp}=  Get Request
    ...  openbmc  ${base_uri}  headers=${headers}  timeout=${timeout}

    Return From Keyword If  ${response_type} != "json"  ${resp}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    ${content} =  To JSON  ${resp.content}
    [Return]  ${content}

