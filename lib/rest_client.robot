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
${QUIET}  ${0}

*** Keywords ***
OpenBMC Get Request
    [Documentation]  Do REST GET request and return the result.
    # Example result data:
    # Response code:200, Content:{
    #   "data": [
    #     "/xyz/openbmc_project/state/host0",
    #     "/xyz/openbmc_project/state/chassis0",
    #     "/xyz/openbmc_project/state/bmc0"
    #   ],
    #   "message": "200 OK",
    #   "status": "ok"
    # }
    [Arguments]    ${uri}    ${timeout}=30  ${quiet}=${QUIET}  &{kwargs}
    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Any additional arguments to be passed directly to the
    #          Get Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    Initialize OpenBMC    ${timeout}  quiet=${quiet}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Get
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Get Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Delete All Sessions
    [Return]    ${ret}

OpenBMC Post Request
    [Documentation]  Do REST POST request and return the result.
    # Example result data:
    # <Response [200]>
    [Arguments]    ${uri}    ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}
    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Any additional arguments to be passed directly to the
    #          Post Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

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
    [Documentation]  Do REST PUT request on the resource identified by the URI.
    [Arguments]    ${uri}    ${timeout}=10    &{kwargs}
    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # kwargs   Arguments passed to the REST call.
    # kwargs   Any additional arguments to be passed directly to the
    #          Put Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

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
    [Documentation]  Do REST request to delete the resource identified by the
    ...  URI.
    [Arguments]    ${uri}    ${timeout}=10    &{kwargs}
    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # kwargs   Any additional arguments to be passed directly to the
    #          Delete Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    Initialize OpenBMC    ${timeout}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    Log Request    method=Delete    base_uri=${base_uri}    args=&{kwargs}
    ${ret}=  Delete Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Log Response    ${ret}
    Delete All Sessions
    [Return]    ${ret}

Initialize OpenBMC
    [Documentation]  Do a REST login connection within specified time.
    [Arguments]  ${timeout}=20  ${quiet}=${1}
    ...  ${OPENBMC_USERNAME}=${OPENBMC_USERNAME}
    ...  ${OPENBMC_PASSWORD}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # timeout  REST login attempt time out.
    # quiet    Suppress console log if set.

    # TODO : Task to revert this changes openbmc/openbmc-test-automation#532
    # This will retry at 20 second interval.
    Wait Until Keyword Succeeds  40 sec  20 sec
    ...  Post Login Request  ${timeout}  ${quiet}
    ...  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

Post Login Request
    [Documentation]  Do REST login request.
    [Arguments]  ${timeout}=20  ${quiet}=${1}
    ...  ${OPENBMC_USERNAME}=${OPENBMC_USERNAME}
    ...  ${OPENBMC_PASSWORD}=${OPENBMC_PASSWORD}

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
    [Documentation]  Log out of the openbmc REST session.

    ${headers}=  Create Dictionary  Content-Type=application/json
    ${data}=  Create dictionary  data=@{EMPTY}

    # If there is no active sesion it will throw the following exception
    # "Non-existing index or alias 'openbmc'"
    ${resp}=  Post Request  openbmc
    ...  /logout  data=${data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=${resp}

Log Request
    [Documentation]  Log the specific REST URI, method name on the console.
    [Arguments]    &{kwargs}
    ${msg}=  Catenate  SEPARATOR=  URI:  ${AUTH_URI}  ${kwargs["base_uri"]}
    ...  , method:  ${kwargs["method"]}  , args:  ${kwargs["args"]}
    Logging    ${msg}    console=True

Log Response
    [Documentation]  Log the response code on the console.
    [Arguments]    ${resp}
    ${msg}=  Catenate  SEPARATOR=  Response code:  ${resp.status_code}
    ...  , Content:  ${resp.content}
    Logging    ${msg}    console=True

Logging
    [Documentation]  Log the specified message on the console.
    [Arguments]    ${msg}    ${console}=default False
    Log    ${msg}    console=True

Read Attribute
    [Documentation]  Retrieve attribute value from URI and return result.
    # Example result data for the attribute 'FieldModeEnabled' in
    # "/xyz/openbmc_project/software/attr/" :
    # 0
    [Arguments]    ${uri}    ${attr}    ${timeout}=10  ${quiet}=${QUIET}
    ...  ${expected_value}=${EMPTY}
    # Description of argument(s):
    # uri               URI of the object that the attribute lives on
    #                   (e.g. '/xyz/openbmc_project/software/').
    # attr              Name of the attribute (e.g. 'FieldModeEnabled').
    # timeout           Timeout for the REST call.
    # quiet             If enabled, turns off logging to console.
    # expected_value    If this argument is not empty, the retrieved value
    #                   must match this value.

    ${resp}=  OpenBMC Get Request  ${uri}/attr/${attr}  timeout=${timeout}
    ...  quiet=${quiet}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=     To Json    ${resp.content}
    Run Keyword If  '${expected_value}' != '${EMPTY}'
    ...  Should Be Equal As Strings  ${expected_value}  ${content["data"]}
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
    [Documentation]  Read data part of the URI object and return result.
    # Example result data:
    # [u'/xyz/openbmc_project/software/cf7bf9d5',
    #  u'/xyz/openbmc_project/software/5ecb8b2c',
    #  u'/xyz/openbmc_project/software/active',
    #  u'/xyz/openbmc_project/software/functional']
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}
    # Description of argument(s):
    # uri               URI of the object
    #                   (e.g. '/xyz/openbmc_project/software/').
    # timeout           Timeout for the REST call.
    # quiet             If enabled, turns off logging to console.

    ${resp}=  OpenBMC Get Request  ${uri}  timeout=${timeout}  quiet=${quiet}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  To Json  ${resp.content}
    [Return]  ${content["data"]}

Call Method
    [Documentation]  Invoke the specific REST service method.
    [Arguments]  ${uri}  ${method}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}
    # Description of arguments:
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Arguments passed to the REST call.

    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${resp}=  OpenBmc Post Request  ${base_uri}/action/${method}
    ...  timeout=${timeout}  quiet=${quiet}  &{kwargs}
    [Return]     ${resp}

Upload Image To BMC
    [Documentation]  Upload image to BMC device using REST POST operation.
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${1}  &{kwargs}

    # Description of argument(s):
    # uri             URI for uploading image via REST e.g. "/upload/image".
    # timeout         Time allocated for the REST command to return status
    #                 (specified in Robot Framework Time Format e.g. "3 mins").
    # quiet           If enabled, turns off logging to console.
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
