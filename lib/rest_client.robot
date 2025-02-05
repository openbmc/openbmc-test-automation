*** Settings ***
Library           Collections
Library           String
Library           RequestsLibrary
Library           OperatingSystem
Resource          resource.robot
Library           disable_warning_urllib.py
Library           utils.py
Library           gen_misc.py
Library           var_funcs.py
Resource          rest_response_code.robot

*** Variables ***
# Assign default value to QUIET for programs which may not define it.
${QUIET}  ${0}

${XAUTH_TOKEN}  ${EMPTY}

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

    Initialize OpenBMC  ${timeout}  quiet=${quiet}

    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}  Accept=application/json
    Set To Dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Get
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${resp}=  GET On Session  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}  expected_status=any
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${resp}
    Delete All Sessions
    RETURN    ${resp}

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
    ${headers}=  Create Dictionary   Content-Type=application/json
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  POST On Session  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Delete All Sessions
    RETURN    ${ret}

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
    ${base_uri}=   Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=  Create Dictionary   Content-Type=application/json
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Log Request  method=Put  base_uri=${base_uri}  args=&{kwargs}
    ${resp}=  PUT On Session  openbmc  ${base_uri}  json=${kwargs["data"]}  headers=${headers}
    Log Response    ${resp}
    Delete All Sessions
    RETURN    ${resp}

OpenBMC Delete Request
    [Documentation]  Do REST request to delete the resource identified by the
    ...  URI.
    [Arguments]    ${uri}    ${timeout}=10   ${quiet}=${QUIET}    &{kwargs}
    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Any additional arguments to be passed directly to the
    #          Delete Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    Initialize OpenBMC    ${timeout}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=  Create Dictionary   Content-Type=application/json
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary   ${kwargs}  headers   ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Delete
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  DELETE On Session  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response    ${ret}
    Delete All Sessions
    RETURN    ${ret}

Initialize OpenBMC
    [Documentation]  Do a REST login connection within specified time.
    [Arguments]  ${timeout}=20  ${quiet}=${1}
    ...  ${rest_username}=${OPENBMC_USERNAME}
    ...  ${rest_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # timeout        REST login attempt time out.
    # quiet          Suppress console log if set.
    # rest_username  The REST username.
    # rest_password  The REST password.

    ${bmcweb_status}=  Run Keyword And Return Status  BMC Web Login Request
    ...  ${timeout}  ${rest_username}  ${rest_password}

    Return From Keyword If  ${bmcweb_status} == ${True}

    # This will retry at 20 second interval.
    Wait Until Keyword Succeeds  40 sec  20 sec
    ...  Post Login Request  ${timeout}  ${quiet}
    ...  ${rest_username}  ${rest_password}


BMC Web Login Request
    [Documentation]  Do BMC web-based login.
    [Arguments]  ${timeout}=20  ${rest_username}=${OPENBMC_USERNAME}
    ...  ${rest_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # timeout        REST login attempt time out.
    # rest_username  The REST username.
    # rest_password  The REST password.

    Create Session  openbmc  ${AUTH_URI}  timeout=${timeout}

    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${rest_username}  ${rest_password}
    ${data}=  Create Dictionary  data=@{credentials}
    ${resp}=  POST On Session  openbmc  /login  json=${data}  headers=${headers}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    ${processed_token_data}=
    ...  Evaluate  re.split(r'[;,]', '${resp.headers["Set-Cookie"]}')  modules=re
    ${result}=  Key Value List To Dict  ${processed_token_data}  delim==

    # Example result data:
    # 'XSRF-TOKEN=hQuOyDJFEIbrN4aOg2CT; Secure,
    # SESSION=c4wloTiETumSxPI9nLeg; Secure; HttpOnly'
    Set Global Variable  ${XAUTH_TOKEN}  ${result['session']}


Post Login Request
    [Documentation]  Do REST login request.
    [Arguments]  ${timeout}=20  ${quiet}=${1}
    ...  ${rest_username}=${OPENBMC_USERNAME}
    ...  ${rest_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # timeout        REST login attempt time out.
    # quiet          Suppress console log if set.
    # rest_username  The REST username.
    # rest_password  The REST password.

    Create Session  openbmc  ${AUTH_URI}  timeout=${timeout}  max_retries=3

    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${rest_username}  ${rest_password}
    ${data}=  Create Dictionary   data=@{credentials}
    ${status}  ${resp}=  Run Keyword And Ignore Error  POST On Session  openbmc
    ...  /login  json=${data}  headers=${headers}

    Should Be Equal  ${status}  PASS  msg=${resp}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Log Out OpenBMC
    [Documentation]  Log out of the openbmc REST session.

    ${headers}=  Create Dictionary  Content-Type=application/json
    ...  X-Auth-Token=${XAUTH_TOKEN}
    ${data}=  Create dictionary  data=@{EMPTY}

    # If there is no active session it will throw the following exception
    # "Non-existing index or alias 'openbmc'"
    ${resp}=  POST On Session  openbmc
    ...  /logout  json=${data}  headers=${headers}

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
    Log  ${msg}  console=True


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

    # Make sure uri ends with slash.
    ${uri}=  Add Trailing Slash  ${uri}

    ${resp}=  OpenBMC Get Request  ${uri}attr/${attr}  timeout=${timeout}
    ...  quiet=${quiet}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Run Keyword If  '${expected_value}' != '${EMPTY}'
    ...  Should Be Equal As Strings  ${expected_value}  ${resp.json()["data"]}
    RETURN    ${resp.json()["data"]}


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

    # Make sure uri ends with slash.
    ${uri}=  Add Trailing Slash  ${uri}

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${resp}=  Openbmc Put Request  ${base_uri}attr/${attr}
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

    RETURN  ${resp.json()["data"]}

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
    ${resp}=  OpenBmc Post Request  ${base_uri}action/${method}
    ...  timeout=${timeout}  quiet=${quiet}  &{kwargs}
    RETURN    ${resp}


Upload Image To BMC
    [Documentation]  Upload image to BMC via REST and return status code.
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${1}
    ...  ${valid_status_codes}=[${HTTP_OK}, ${HTTP_ACCEPTED}]  &{kwargs}

    # Description of argument(s):
    # uri                           URI for uploading image via REST e.g.
    #                               "/upload/image".
    # timeout                       Time allocated for the REST command to
    #                               return status (specified in Robot
    #                               Framework Time Format e.g. "3 mins").
    # quiet                         If enabled, turns off logging to console.
    # valid_status_codes            A list of status codes that are valid for
    #                               the REST post command. This can be
    #                               specified as a string the evaluates to a
    #                               python object (e.g. [${HTTP_OK}]).
    # kwargs                        A dictionary keys/values to be passed
    #                               directly to Post Request.


    # If /redfish/v1/SessionService/Sessions POST fails, fallback to
    # REST /login method.
    ${passed}=  Run Keyword And Return Status   Redfish Login
    Run Keyword If  ${passed} != True   Initialize OpenBMC  ${timeout}  quiet=${quiet}
    ${session_object}=  Set Variable If  ${passed}  redfish  openbmc

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}  Accept=application/json
    Set To Dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  POST On Session  ${session_object}  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Valid Value  ret.status_code  ${valid_status_codes}
    Delete All Sessions

    RETURN  ${ret}


Redfish Login
    [Documentation]  Do BMC web-based login.
    [Arguments]  ${timeout}=20  ${rest_username}=${OPENBMC_USERNAME}
    ...  ${rest_password}=${OPENBMC_PASSWORD}  ${kwargs}=${EMPTY}

    # Description of argument(s):
    # timeout        REST login attempt time out.
    # rest_username  The REST username.
    # rest_password  The REST password.
    # kwargs   Any additional arguments to be passed directly to the
    #          Get Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    Create Session  redfish  ${AUTH_URI}  timeout=${timeout}
    ${headers}=  Create Dictionary  Content-Type=application/json
    ${data}=  Set Variable If  '${kwargs}' == '${EMPTY}'
    ...    {"UserName":"${rest_username}", "Password":"${rest_password}"}
    ...    {"UserName":"${rest_username}", "Password":"${rest_password}", ${kwargs}}

    ${resp}=  POST On Session  redfish  /redfish/v1/SessionService/Sessions
    ...  data=${data}  headers=${headers}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_CREATED}

    Set Global Variable  ${XAUTH_TOKEN}  ${resp.headers["X-Auth-Token"]}

    RETURN  ${resp.json()}


Redfish Get Request
    [Documentation]  Do REST POST request and return the result.
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Any additional arguments to be passed directly to the
    #          Post Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/json  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary   ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post  base_uri=${base_uri}  args=&{kwargs}
    ${resp}=  GET On Session  redfish  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${resp}

    RETURN  ${resp}


Redfish Post Request
    [Documentation]  Do REST POST request and return the result.
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    # Description of argument(s):
    # uri      The URI to establish connection with
    #          (e.g. '/xyz/openbmc_project/software/').
    # timeout  Timeout in seconds to establish connection with URI.
    # quiet    If enabled, turns off logging to console.
    # kwargs   Any additional arguments to be passed directly to the
    #          Post Request call. For example, the caller might
    #          set kwargs as follows:
    #          ${kwargs}=  Create Dictionary  allow_redirect=${True}.

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/json  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary   ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post  base_uri=${base_uri}  args=&{kwargs}
    ${resp}=  POST On Session  redfish  ${base_uri}  &{kwargs}  timeout=${timeout}  expected_status=any
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${resp}

    RETURN  ${resp}
