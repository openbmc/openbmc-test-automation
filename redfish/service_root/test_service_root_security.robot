*** Settings ***
Documentation    Test Redfish service root login security.

Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail
Test Setup       Printn

*** Variables ***

${LOGIN_SESSION_COUNT}   ${50}

&{header_requirements}  Strict-Transport-Security=max-age=31536000; includeSubdomains
...                     X-Frame-Options=DENY
...                     Pragma=no-cache
...                     Cache-Control=no-store, max-age=0
...                     Referrer-Policy=no-referrer
...                     X-Content-Type-Options=nosniff
...                     X-Permitted-Cross-Domain-Policies=none
...                     Cross-Origin-Embedder-Policy=require-corp
...                     Cross-Origin-Opener-Policy=same-origin
...                     Cross-Origin-Resource-Policy=same-origin
...                     Content-Security-Policy=default-src 'none'; img-src 'self' data:; font-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self' wss:; form-action 'none'; frame-ancestors 'none'; object-src 'none'; base-uri 'none'

${ERROR_RESPONSE_MSG}  *Connection refused*

*** Test Cases ***

Redfish Login With Invalid Credentials
    [Documentation]  Login to BMC web using invalid credential.
    [Tags]  Redfish_Login_With_Invalid_Credentials
    [Template]  Login And Verify Redfish Response

    # Username                Password               Expect status
    ${OPENBMC_USERNAME}       deadpassword           InvalidCredentialsError
    groot                     ${OPENBMC_PASSWORD}    InvalidCredentialsError
    ${EMPTY}                  ${OPENBMC_PASSWORD}    SessionCreationError
    ${OPENBMC_USERNAME}       ${EMPTY}               SessionCreationError
    ${EMPTY}                  ${EMPTY}               SessionCreationError


Redfish Login Using Unsecured HTTP
    [Documentation]  Login to BMC web through http unsecured.
    [Tags]  Redfish_Login_Using_Unsecured_HTTP

    Create Session  openbmc  http://${OPENBMC_HOST}
    ${data}=  Create Dictionary
    ...  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}

    ${headers}=  Create Dictionary  Content-Type=application/json

    Run Keyword And Expect Error  *Connection refused*
    ...  POST On Session  openbmc  /redfish/v1/SessionService/Sessions
    ...  data=${data}  headers=${headers}


Redfish Login Using HTTPS Wrong Port 80 Protocol
    [Documentation]  Login to BMC web through wrong protocol port 80.
    [Tags]  Redfish_Login_Using_HTTPS_Wrong_Port_80_Protocol

    Create Session  openbmc  https://${OPENBMC_HOST}:80
    ${data}=  Create Dictionary
    ...  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}

    ${headers}=  Create Dictionary  Content-Type=application/json

    Run Keyword And Expect Error  ${ERROR_RESPONSE_MSG}
    ...  POST On Session  openbmc  /redfish/v1/SessionService/Sessions
    ...  data=${data}  headers=${headers}


Create Multiple Login Sessions And Verify
    [Documentation]  Create 50 login instances and verify.
    [Tags]  Create_Multiple_Login_Sessions_And_Verify
    [Teardown]  Run Keyword And Ignore Error  Multiple Session Cleanup

    Redfish.Login
    # Example:
    #    {
    #      'key': 'L0XEsZAXpNdF147jJaOD',
    #      'location': '/redfish/v1/SessionService/Sessions/qWn2JOJSOs'
    #    }
    ${saved_session_info}=  Get Redfish Session Info

    # Sessions book keeping for cleanup once done.
    ${session_list}=  Create List
    Set Test Variable  ${session_list}

    Repeat Keyword  ${LOGIN_SESSION_COUNT} times  Create New Login Session

    # Update the redfish session object with the first login key and location
    # and verify if it is still working.
    Redfish.Set Session Key  ${saved_session_info["key"]}
    Redfish.Set Session Location  ${saved_session_info["location"]}
    Redfish.Get  ${saved_session_info["location"]}


Attempt Login With Expired Session
    [Documentation]  Authenticate to redfish, then log out and attempt to
    ...   use the session.
    [Tags]  Attempt_Login_With_Expired_Session

    Redfish.Login
    ${saved_session_info}=  Get Redfish Session Info
    Redfish.Logout

    # Attempt login with expired session.
    # By default 60 minutes of inactivity closes the session.
    Redfish.Set Session Key  ${saved_session_info["key"]}
    Redfish.Set Session Location  ${saved_session_info["location"]}

    Redfish.Get  ${saved_session_info["location"]}  valid_status_codes=[${HTTP_UNAUTHORIZED}]


Login And Verify HTTP Response Header
    [Documentation]  Login and verify redfish HTTP response header.
    [Tags]  Login_And_Verify_HTTP_Response_Header

    # Example of HTTP redfish response header.
    # Strict-Transport-Security: max-age=31536000; includeSubdomains
    # X-Frame-Options: DENY
    # Pragma: no-cache
    # Cache-Control: no-store, max-age=0
    # X-Content-Type-Options: nosniff
    # Referrer-Policy: no-referrer
    # X-Permitted-Cross-Domain-Policies: none
    # Cross-Origin-Embedder-Policy: require-corp
    # Cross-Origin-Opener-Policy: same-origin
    # Cross-Origin-Resource-Policy: same-origin
    # Content-Security-Policy: default-src 'none'; img-src 'self' data:; font-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self' wss:; form-action 'none'; frame-ancestors 'none'; object-src 'none'; base-uri 'none'


    Rprint Vars  header_requirements  fmt=1

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/SessionService/Sessions

    # The getheaders() method returns the headers as a list of tuples:
    # headers:

    # [Strict-Transport-Security]:             max-age=31536000; includeSubdomains
    # [X-Frame-Options]:                       DENY
    # [Pragma]:                                no-cache
    # [Cache-Control]:                         no-store, max-age=0
    # [X-Content-Type-Options]:                nosniff
    # [Referrer-Policy]:                       no-referrer
    # [X-Permitted-Cross-Domain-Policies]:     none
    # [Cross-Origin-Embedder-Policy]:          require-corp
    # [Cross-Origin-Opener-Policy]:            same-origin
    # [Cross-Origin-Resource-Policy]:          same-origin
    # [Content-Security-Policy]:               default-src 'none'; img-src 'self' data:; font-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self' wss:; form-action 'none'; frame-ancestors 'none'; object-src 'none'; base-uri 'none'
    # [Content-Type]:                          application/json
    # [Content-Length]:                        394

    ${headers}=  Key Value List To Dict  ${resp.getheaders()}
    Rprint Vars  headers  fmt=1

    Dictionary Should Contain Sub Dictionary   ${headers}  ${header_requirements}


*** Keywords ***

Login And Verify Redfish Response
    [Documentation]  Login and verify redfish response.
    [Arguments]   ${username}  ${password}  ${expected_response}

    # Description of arguments:
    # expected_response    Expected REST status.
    # username             The username to be used to connect to the server.
    # password             The password to be used to connect to the server.

    # The redfish object may preserve a valid username or password from the
    # last failed login attempt.  If we then try to login with a null username
    # or password value, the redfish object may prefer the preserved value.
    # Since we're testing bad path, we wish to avoid this scenario so we will
    # clear these values.

    Redfish.Set Username  ${EMPTY}
    Redfish.Set Password  ${EMPTY}

    ${msg}=  Run Keyword And Expect Error  *  Redfish.Login  ${username}  ${password}

    # redfish package version <=3.1.6 default response is InvalidCredentialsError.
    Should Contain Any   ${msg}  InvalidCredentialsError  ${expected_response}


Create New Login Session
    [Documentation]  Multiple login session keys.

    Redfish.Login
    ${session_info}=  Get Redfish Session Info

    # Append the session location to the list.
    # ['/redfish/v1/SessionService/Sessions/uDzihgDecs',
    #  '/redfish/v1/SessionService/Sessions/PaHF5brPPd']
    Append To List  ${session_list}  ${session_info["location"]}


Multiple Session Cleanup
    [Documentation]  Do the teardown for multiple sessions.

    FFDC On Test Case Fail

    FOR  ${item}  IN  @{session_list}
      Redfish.Delete  ${item}
    END
