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
    Should Be Equal    ${c}     /org

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
    list should contain value    ${json['data']}         /org
    should be equal as strings   ${json['status']}       ok

get directory listing /org/
    [Tags]  CI
    ${resp}=   openbmc get request     /org/
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...    ${json['data']}    ${OPENBMC_BASE_URI.rstrip("/")}
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

put directory listing /org/
    [Tags]  CI
    ${resp}=   openbmc put request     /org/
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

post directory listing /org/
    [Tags]  CI
    ${resp}=   openbmc post request    /org/
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

delete directory listing /org/
    [Tags]  CI
    ${resp}=   openbmc delete request  /
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

delete invalid directory listing /org/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /org/nothere/
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings          ${json['status']}   error

get list names /
    ${resp}=   openbmc get request     /list
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}   ${INVENTORY_URI.rstrip("/")}
    should be equal as strings      ${json['status']}       ok

get list names /org/
    ${resp}=   openbmc get request     /org/list
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}   ${INVENTORY_URI.rstrip("/")}
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

put list names /org/
    [Tags]  CI
    ${resp}=   openbmc put request     /org/list
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

post list names /org/
    [Tags]  CI
    ${resp}=   openbmc post request    /org/list
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

delete list names /org/
    [Tags]  CI
    ${resp}=   openbmc delete request  /list
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete invalid list names /org/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /org/nothere/list
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

get names /
    [Tags]  get_names
    ${resp}=   openbmc get request     /enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}   ${INVENTORY_URI.rstrip("/")}
    should be equal as strings      ${json['status']}       ok

get names /org/
    [Tags]  get_names_org
    ${resp}=   openbmc get request     /org/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    list should contain value
    ...  ${json['data']}   ${INVENTORY_URI.rstrip("/")}
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

put names /org/
    [Tags]  CI
    ${resp}=   openbmc put request     /org/enumerate
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

post names /org/
    [Tags]  CI
    ${resp}=   openbmc post request    /org/enumerate
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

delete names /org/
    [Tags]  CI
    ${resp}=   openbmc delete request  /enumerate
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete invalid names /org/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /org/nothere/enumerate
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

get method org/openbmc/records/events/action/acceptTestMessage
    [Tags]  CI
    ${resp}=   openbmc get request
    ...  org/openbmc/records/events/action/acceptTestMessage
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

get invalid method /i/dont/exist/
    [Tags]  CI
    ${resp}=   openbmc get request     /i/dont/exist/action/foo
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

put method org/openbmc/records/events/action/acceptTestMessage
    [Tags]  CI
    ${resp}=   openbmc put request
    ...  org/openbmc/records/events/action/acceptTestMessage
    should be equal as strings
    ...  ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
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

post method org/openbmc/records/events/action/acceptTestMessage invalid args
    [Tags]  CI
    ${data}=   create dictionary   foo=bar
    ${resp}=   openbmc post request
    ...  org/openbmc/records/events/action/acceptTestMessage      data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_BAD_REQUEST}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post method org/openbmc/sensors/host/BootCount with args
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

delete method org/openbmc/records/events/action/acceptTestMessage
    [Tags]  CI
    ${resp}=   openbmc delete request
    ...  org/openbmc/records/events/action/acceptTestMessage
    should be equal as strings
    ...   ${resp.status_code}     ${HTTP_METHOD_NOT_ALLOWED}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

delete invalid method /org/nothere/
    [Tags]  CI
    ${resp}=   openbmc delete request  /org/nothere/action/foomethod
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       error

post method org/openbmc/records/events/action/acceptTestMessage no args
    [Tags]  CI
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=   openbmc post request
    ...  org/openbmc/records/events/action/acceptTestMessage      data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    should be equal as strings      ${json['status']}       ok

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
