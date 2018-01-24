*** Settings ***
Library           Collections
Library           String
Library           RequestsLibrary.RequestsKeywords
Library           OperatingSystem
Resource          ../lib/resource.txt
Library           ../lib/disable_warning_urllib.py

*** Variables ***
# Response codes
${HTTP_CONTINUE}    100
${HTTP_SWITCHING_PROTOCOLS}    101
${HTTP_PROCESSING}    102
${HTTP_OK}        200
${HTTP_CREATED}    201
${HTTP_ACCEPTED}    202
${HTTP_NON_AUTHORITATIVE_INFORMATION}    203
${HTTP_NO_CONTENT}    204
${HTTP_RESET_CONTENT}    205
${HTTP_PARTIAL_CONTENT}    206
${HTTP_MULTI_STATUS}    207
${HTTP_IM_USED}    226
${HTTP_MULTIPLE_CHOICES}    300
${HTTP_MOVED_PERMANENTLY}    301
${HTTP_FOUND}     302
${HTTP_SEE_OTHER}    303
${HTTP_NOT_MODIFIED}    304
${HTTP_USE_PROXY}    305
${HTTP_TEMPORARY_REDIRECT}    307
${HTTP_BAD_REQUEST}    400
${HTTP_UNAUTHORIZED}    401
${HTTP_PAYMENT_REQUIRED}    402
${HTTP_FORBIDDEN}    403
${HTTP_NOT_FOUND}    404
${HTTP_METHOD_NOT_ALLOWED}    405
${HTTP_NOT_ACCEPTABLE}    406
${HTTP_PROXY_AUTHENTICATION_REQUIRED}    407
${HTTP_REQUEST_TIMEOUT}    408
${HTTP_CONFLICT}    409
${HTTP_GONE}      410
${HTTP_LENGTH_REQUIRED}    411
${HTTP_PRECONDITION_FAILED}    412
${HTTP_REQUEST_ENTITY_TOO_LARGE}    413
${HTTP_REQUEST_URI_TOO_LONG}    414
${HTTP_UNSUPPORTED_MEDIA_TYPE}    415
${HTTP_REQUESTED_RANGE_NOT_SATISFIABLE}    416
${HTTP_EXPECTATION_FAILED}    417
${HTTP_UNPROCESSABLE_ENTITY}    422
${HTTP_LOCKED}    423
${HTTP_FAILED_DEPENDENCY}    424
${HTTP_UPGRADE_REQUIRED}    426
${HTTP_INTERNAL_SERVER_ERROR}    500
${HTTP_NOT_IMPLEMENTED}    501
${HTTP_BAD_GATEWAY}    502
${HTTP_SERVICE_UNAVAILABLE}    503
${HTTP_GATEWAY_TIMEOUT}    504
${HTTP_HTTP_VERSION_NOT_SUPPORTED}    505
${HTTP_INSUFFICIENT_STORAGE}    507
${HTTP_NOT_EXTENDED}    510
# Assign default value to QUIET for programs which may not define it.
${QUIET}  ${0}

*** Keywords ***
OpenBMC Get Request
    [Documentation]  Does initial connection for subsequent REST "GET" calls.
    [Arguments]    ${uri}    ${timeout}=30  ${quiet}=${QUIET}  &{kwargs}
    # Description of arguments:
    # uri      The URI to establish connection with.
    # timeout  Timeout in seconds to establih connection with URI.
    # quiet    If enabled turns off logging to console.
    # kwargs   Arguments passed to the REST call.
 
    Initialize OpenBMC    ${timeout}  quiet=${quiet}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Get
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Get Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Delete All Sessions
    [Return]    ${ret}

OpenBMC Post Request
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    ${uri}    ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    Initialize OpenBMC    ${timeout}  quiet=${quiet}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=     Create Dictionary   Content-Type=application/json
    set to dictionary   ${kwargs}       headers     ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Post Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Delete All Sessions
    [Return]    ${ret}

OpenBMC Put Request
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    ${uri}    ${timeout}=10    &{kwargs}

    Initialize OpenBMC    ${timeout}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=     Create Dictionary   Content-Type=application/json
    set to dictionary   ${kwargs}       headers     ${headers}
    Log Request    method=Put    base_uri=${base_uri}    args=&{kwargs}
    ${ret}=  Put Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Log Response    ${ret}
    Delete All Sessions
    [Return]    ${ret}

OpenBMC Delete Request
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    ${uri}    ${timeout}=10    &{kwargs}

    Initialize OpenBMC    ${timeout}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    Log Request    method=Delete    base_uri=${base_uri}    args=&{kwargs}
    ${ret}=  Delete Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Log Response    ${ret}
    Delete All Sessions
    [Return]    ${ret}

Initialize OpenBMC
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]  ${timeout}=20  ${quiet}=${1}

    # Description of argument(s):
    # timeout  REST login attempt time out.
    # quiet    Suppress console log if set.

    # TODO : Task to revert this changes openbmc/openbmc-test-automation#532
    # This will retry at 20 second interval.
    Wait Until Keyword Succeeds  40 sec  20 sec
    ...  Post Login Request  ${timeout}  ${quiet}

Post Login Request
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]  ${timeout}=20  ${quiet}=${1}

    # Description of argument(s):
    # timeout  REST login attempt time out.
    # quiet    Suppress console log if set.

    Create Session  openbmc  ${AUTH_URI}  timeout=${timeout}  max_retries=3
    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${data}=  create dictionary   data=@{credentials}
    ${status}  ${resp}=  Run Keyword And Ignore Error  Post Request  openbmc
    ...  /login  data=${data}  headers=${headers}

    Should Be Equal  ${status}  PASS  msg=${resp}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Log Out OpenBMC
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Documentation]  Log out REST connection with active session "openbmc".

    ${headers}=  Create Dictionary  Content-Type=application/json
    ${data}=  Create dictionary  data=@{EMPTY}

    # If there is no active sesion it will throw the following exception
    # "Non-existing index or alias 'openbmc'"
    ${resp}=  Post Request  openbmc
    ...  /logout  data=${data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=${resp}

Log Request
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    &{kwargs}
    ${msg}=  Catenate  SEPARATOR=  URI:  ${AUTH_URI}  ${kwargs["base_uri"]}
    ...  , method:  ${kwargs["method"]}  , args:  ${kwargs["args"]}
    Logging    ${msg}    console=True

Log Response
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    ${resp}
    ${msg}=  Catenate  SEPARATOR=  Response code:  ${resp.status_code}
    ...  , Content:  ${resp.content}
    Logging    ${msg}    console=True

Logging
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    ${msg}    ${console}=default False
    Log    ${msg}    console=True

Read Attribute
    [Documentation]  Verify all the REST objects are accessible using "GET".
    [Arguments]    ${uri}    ${attr}    ${timeout}=10  ${quiet}=${QUIET}
    ${resp}=  OpenBMC Get Request  ${uri}/attr/${attr}  timeout=${timeout}
    ...  quiet=${quiet}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=     To Json    ${resp.content}
    [Return]    ${content["data"]}


Write Attribute
    [Documentation]  Write a D-Bus attribute with REST.
    [Arguments]  ${uri}  ${attr}  ${timeout}=10  ${verify}=${FALSE}
    ...  ${expected_value}=${EMPTY}  &{kwargs}

    # Description of argument(s):
    # uri               URI of the object that the attribute lives on
    #                   (e.g. '/xyz/openbmc_project/software/').
    # attr              Name of the attribute (e.g. 'FieldModeEnabled').
    # timeout           Timeout for the REST call.
    # verify            If set to ${TRUE}, the attribute will be read back to
    #                   ensure that its value is set to ${verify_attr}.
    # expected_value    Only used if verify is set to ${TRUE}. The value that
    #                   ${attr} should be set to. This defaults to
    #                   ${kwargs['data']. There are cases where the caller
    #                   expects some other value in which case this value can
    #                   be explicitly specified.
    # kwargs            Arguments passed to the REST call. This should always
    #                   contain the value to set the property to at the 'data'
    #                   key (e.g. data={"data": 1}).

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${resp}=  Openbmc Put Request  ${base_uri}/attr/${attr}
    ...  timeout=${timeout}  &{kwargs}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Verify the attribute was set correctly if the caller requested it.
    Return From Keyword If  ${verify} == ${FALSE}

    ${expected_value}=  Set Variable If  '${expected_value}' == '${EMPTY}'
    ...  ${kwargs['data']['data']}  ${expected_value}
    ${value}=  Read Attribute  ${uri}  ${attr}
    Should Be Equal  ${value}  ${expected_value}


Read Properties
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}
    ${resp}=  OpenBMC Get Request  ${uri}  timeout=${timeout}  quiet=${quiet}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  To Json  ${resp.content}
    [Return]  ${content["data"]}

Call Method
    [Arguments]  ${uri}  ${method}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${resp}=  OpenBmc Post Request  ${base_uri}/action/${method}
    ...  timeout=${timeout}  quiet=${quiet}  &{kwargs}
    [Return]     ${resp}

Upload Image To BMC
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${1}  &{kwargs}

    # Description of argument(s):
    # uri             URI for uploading image via REST e.g. "/upload/image".
    # timeout         Time allocated for the REST command to return status
    #                 (specified in Robot Framework Time Format e.g. "3 mins").
    # quiet           If enabled turns off logging to console.
    # kwargs          A dictionary keys/values to be passed directly to
    #                 Post Request.

    Initialize OpenBMC  ${timeout}  quiet=${quiet}
    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  Accept=application/octet-stream
    Set To Dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Post Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}
    Delete All Sessions
