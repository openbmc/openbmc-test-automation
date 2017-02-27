*** Settings ***
Documentation     This suite will verifiy all OpenBMC rest interfaces
...               Details of valid interfaces can be found here...
...               https://github.com/openbmc/docs/blob/master/rest-api.md

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/resource.txt
Test Teardown     FFDC On Test Case Fail

*** Variables ***

*** Test Cases ***
Good connection for testing
    [Tags]  Good_connection_for_testing
    ${content}=    Read Properties     /
    ${c}=          get from List       ${content}      0
    Should Be Equal    ${c}     /xyz

Get an object with no properties
    ${content}=    Read Properties   ${INVENTORY_URI.rstrip("/")}
    Should Be Empty     ${content}

Get a Property
    [Tags]  Get_a_Property
    ${url_list}=
    ...   Get Endpoint Paths   ${INVENTORY_URI.rstrip("/")}   cpu
    ${url}=   Get From List   ${url_list}   0
    ${resp}=   Read Attribute   ${url}   is_fru
    Should Be Equal   ${resp}   ${1}

Get a null Property
    ${resp}=    OpenBMC Get Request    ${INVENTORY_URI}attr/is_fru
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_NOT_FOUND}
    ${jsondata}=    To Json    ${resp.content}
    Should Be Equal
    ...   ${jsondata['data']['description']}
    ...   The specified property cannot be found: ''is_fru''

get directory listing /
    [Tags]  get_directory_listing
    ${resp}=   openbmc get request     /
    should be equal as strings   ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json     ${resp.content}
    list should contain value    ${json['data']}         /xyz
    should be equal as strings   ${json['status']}       ok

get directory listing /xyz/
    [Tags]  get_directory_listing_xyz
    ${resp}=   openbmc get request     /xyz/
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...    ${json['data']}    /xyz/openbmc_project
    should be equal as strings   ${json['status']}       ok

get invalid directory listing /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc get request     /i/dont/exist/
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

put directory listing /
    [Tags]  CI
    ${resp}=   openbmc put request     /
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

put directory listing /xyz/
    [Tags]  CI
    ${resp}=   openbmc put request     /xyz/
    should be equal as strings
    ...  ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

put invalid directory listing /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc put request     /i/dont/exist/
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

post directory listing /
    [Tags]  CI
    ${resp}=   openbmc post request    /
    should be equal as strings
    ...  ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

post directory listing /xyz/
    [Tags]  CI
    ${resp}=   openbmc post request    /xyz/
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

post invalid directory listing /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc post request    /i/dont/exist/
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

delete directory listing /
    [Tags]  CI
    ${resp}=   openbmc delete request  /
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

delete directory listing /xyz/
    [Tags]  CI
    ${resp}=   openbmc delete request  /
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

delete invalid directory listing /xyz/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /xyz/nothere/
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

get list names /
    ${resp}=   openbmc get request     /list
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}  /xyz/openbmc_project/inventory
    should be equal as strings      ${json['status']}       ok

get list names /xyz/
    ${resp}=   openbmc get request     /xyz/list
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}   /xyz/openbmc_project/inventory
    should be equal as strings      ${json['status']}       ok

get invalid list names /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc get request     /i/dont/exist/list
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put list names /
    [Tags]  CI
    ${resp}=   openbmc put request     /list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put list names /xyz/
    [Tags]  CI
    ${resp}=   openbmc put request     /xyz/list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put invalid list names /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc put request     /i/dont/exist/list
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post list names /
    [Tags]  CI
    ${resp}=   openbmc post request    /list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post list names /xyz/
    [Tags]  CI
    ${resp}=   openbmc post request    /xyz/list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post invalid list names /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc post request    /i/dont/exist/list
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete list names /
    [Tags]  CI
    ${resp}=   openbmc delete request  /list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete list names /xyz/
    [Tags]  CI
    ${resp}=   openbmc delete request  /list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete invalid list names /xyz/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /xyz/nothere/list
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

get names /
    [Tags]  get_names
    ${resp}=   openbmc get request     /enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}  /xyz/openbmc_project/inventory
    should be equal as strings      ${json['status']}       ok

get names /xyz/
    [Tags]  get_names_xyz
    ${resp}=   openbmc get request     /xyz/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}  /xyz/openbmc_project/inventory
    should be equal as strings      ${json['status']}       ok

get invalid names /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc get request     /i/dont/exist/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put names /
    [Tags]  CI
    ${resp}=   openbmc put request     /enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put names /xyz/
    [Tags]  CI
    ${resp}=   openbmc put request     /xyz/enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put invalid names /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc put request     /i/dont/exist/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post names /
    [Tags]  CI
    ${resp}=   openbmc post request    /enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post names /xyz/
    [Tags]  CI
    ${resp}=   openbmc post request    /xyz/enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post invalid names /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc post request    /i/dont/exist/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete names /
    [Tags]  CI
    ${resp}=   openbmc delete request  /enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete names /xyz/
    [Tags]  CI
    ${resp}=   openbmc delete request  /enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete invalid names /xyz/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /xyz/nothere/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

get method xyz/openbmc_project/logging/entry
    [Tags]  CI
    ${resp}=   openbmc get request
    ...  xyz/openbmc_project/logging/entry
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

get invalid method /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc get request     /i/dont/exist/action/foo
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error


put invalid method /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc put request     /i/dont/exist/action/foo
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post method power/getPowerState no args
    ${fan_uri}=     Get Power Control Interface
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=   openbmc post request
    ...   ${fan_uri}/action/getPowerState      data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ok

post method xyz/openbmc_project/sensors/host/BootCount with args
    ${uri}=     Set Variable   ${SENSORS_URI}host/BootCount
    ${COUNT}=   Set Variable    ${3}
    @{count_list}=   Create List     ${COUNT}
    ${data}=   create dictionary   data=@{count_list}
    ${resp}=   openbmc post request    ${uri}/action/setValue      data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ok
    ${content}=     Read Attribute      ${uri}   value
    Should Be Equal     ${content}      ${COUNT}

delete invalid method /xyz/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /xyz/nothere/action/foomethod
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

*** Keywords ***
Get Power Control Interface
    ${resp}=    OpenBMC Get Request    ${CONTROL_URI}
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_OK}
    ...   msg=Unable to get any controls - ${CONTROL_URI}
    ${jsondata}=   To Json    ${resp.content}
    log     ${jsondata}
    : FOR    ${ELEMENT}    IN    @{jsondata["data"]}
    \   log     ${ELEMENT}
    \   ${found}=   Get Lines Matching Pattern    ${ELEMENT}   *control/power*
    \   Return From Keyword If     '${found}' != ''     ${found}
