*** Settings ***
Documentation   Test OpenBMC GUI "Sessions" sub-menu of "Security and access" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close All Browsers

Test Tags       Sessions_Sub_Menu

*** Variables ***

@{webui_sessionTimeout_value}       60  180
${sessions_table_checkbox}          //*[@data-test-id='sessions-checkbox-selectRow-0']
${session_table_popup}              //*[@class='toolbar-content']
${confirm_disconnect_popup}         //*[@data-test-id='table-button-disconnectSelected']
${disconnect_session_page}          //*[text()="Disconnect session"]
${confirm_disconnect_session}       //*[@class='btn btn-md btn-primary']

*** Test Cases ***

Verify Navigation To Sessions Page
    [Documentation]  Verify navigation to sessions page.
    [Tags]  Verify_Navigation_To_Sessions_Page

    Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}  ${xpath_sessions_sub_menu}  sessions

Verify Session Timeout Validation For WebUI Session
    [Documentation]  Verify session timeout validation for WebUI session.
    [Tags]  Verify_Session_Timeout_Validation_For_WebUI_Session
    [Setup]  Run Keywords
    ...  Redfish.Login    AND
    ...  Delete All Redfish Sessions    AND
    ...  Close Browser  AND
    ...  Get Default Session Timeout Via Redfish
    [Teardown]  Delete All Redfish Sessions

    FOR  ${webui_timeout}  IN  @{webui_sessionTimeout_value}

        ${webui_timeout}=  Convert To Integer  ${webui_timeout}
        ${payload}=  Catenate  {"SessionTimeout": ${webui_timeout}}

        # PATCH redfish session timeout value and verify response.
        ${resp}=  Redfish.Patch  ${REDFISH_BASE_URI}SessionService  body=${payload}
         ...  valid_status_codes=[${HTTP_OK}]

        # GET redfish session timeout value.
        ${resp}=  Redfish.Get Properties  ${REDFISH_BASE_URI}SessionService
        ...  valid_status_codes=[${HTTP_OK}]
        Should Be Equal As Integers  ${resp['SessionTimeout']}  ${webui_timeout}

        # GET the session count before login, should be 1.
        Get Session Member And Verify Session Count  valid_status_code=${HTTP_OK}
        ...  expected_count=${1}

        # Launch browser and login GUI, which will create a WebUI session.
        Launch Browser And Login GUI
        Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}
        ...  ${xpath_sessions_sub_menu}  sessions

        # GET the session count after login, should be 2.
        Get Session Member And Verify Session Count  valid_status_code=${HTTP_OK}
        ...  expected_count=${2}

        # Verify WebUI session expired after timeout.
        Sleep  ${webui_timeout+5}s
        Redfish.Login

        # Check WebUI session expired after timeout.
        Check Session Expired After Timeout  session_instance=${session_member}

        # Verify session expired after timeout.
        ${session_error}=  Get Specific Sessions Member Instance Via Redfish
        ...  instance=${session_member}  status_codes=${HTTP_NOT_FOUND}

        # GET the session count after session expired, should be 1.
        Get Session Member And Verify Session Count  valid_status_code=${HTTP_OK}
        ...  expected_count=${1}

    END

    # Restore default session timeout value.
    Set Default Session Timeout Via Redfish

    # Verify session timeout value restored successfully.
    Should Be Equal As Integers  ${restore_session_timeout}  ${DEFAULT_SESSION_TIMEOUT}

Verify Disconnect Session Validation For WebUI Session
    [Documentation]  Verify disconnect session validation for WebUI session.
    [Tags]  Verify_Disconnect_Session_Validation_For_WebUI_Session
    [Setup]  Run Keywords
    ...  Redfish.Login    AND
    ...  Delete All Redfish Sessions    AND
    ...  Close All Browsers
    [Teardown]  Delete All Redfish Sessions

    # GET redfish session timeout value.
    ${resp}=  Redfish.Get Properties  ${REDFISH_BASE_URI}SessionService
    ...  valid_status_codes=[${HTTP_OK}]

    # GET the session count before login, should be 1.
    Get Session Member And Verify Session Count  valid_status_code=${HTTP_OK}
    ...  expected_count=${1}

    # Launch browser and login GUI, which will create a WebUI session.
    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}
    ...  ${xpath_sessions_sub_menu}  sessions

    # GET the session count after login, should be 2.
    Get Session Member And Verify Session Count  valid_status_code=${HTTP_OK}
    ...  expected_count=${2}

    # Select the session checkbox for the first session in the sessions table.
    Click Element At Coordinates  ${sessions_table_checkbox}  0  0

    # Wait until the disconnect session popup is displayed.
    Wait Until Page Contains Element  ${session_table_popup}

    # Click the disconnect session button in the popup.
    Click Element  ${confirm_disconnect_popup}

    # Wait until the disconnect session confirmation page is displayed.
    Page Should Contain Element  ${disconnect_session_page}

    # Click the confirm disconnect session button.
    Click Element  ${confirm_disconnect_session}

    # Wait until the login page is displayed.
    Wait Until Page Contains Element  ${xpath_login_button}

    # GET the session count after login, should be 1.
    Get Session Member And Verify Session Count  valid_status_code=${HTTP_OK}
    ...  expected_count=${1}

Verify Search Sessions On WebUI Session
    [Documentation]  Verify search sessions functionality on WebUI session.
    [Tags]  Verify_Search_Sessions_On_WebUI_Session
    [Setup]  Run Keywords
    ...  Redfish.Login    AND
    ...  Delete All Redfish Sessions    AND
    ...  Close All Browsers

    Create Multiple WebUI Sessions And Navigate To Sessions Page

    ${session_member_list}=  Redfish_Utils.Get Member List  ${REDFISH_SESSION}
    ${session_count}=  Get Length  ${session_member_list}

    FOR  ${i}  IN RANGE  ${session_count}

        ${session_member}=  Set Variable  ${session_member_list}[${i}]
        ${session_memeber_id}=  Fetch From Right  ${session_member}  /

        # Input the session id in the search box and verify the session is displayed.
        Input Text  ${xpath_search_box}  ${session_memeber_id}

        # Page should contain the session id.
        Page Should Contain  ${session_memeber_id}

        # Clear the search box for next search.
        Clear Element Text  ${xpath_search_box}

    END

*** Keywords ***

Get Session Member And Verify Session Count
    [Documentation]  Get And Verify Session Count.
    [Arguments]  ${valid_status_code}=${HTTP_OK}  ${expected_count}=${0}

    # Description of argument(s):
    # valid_status_codes    The valid status codes for the session service response.
    # expected_count        The expected session count.

    ${session_resp}=  Redfish.Get Properties  ${REDFISH_SESSION}
    ...  valid_status_codes=[${valid_status_code}]

    Should Be Equal As Integers  ${session_resp['Members@odata.count']}  ${expected_count}

    ${session_member}=  Set Variable  ${session_resp['Members'][0]['@odata.id']}

    Set Test Variable  ${session_member}

Get Default Session Timeout Via Redfish
    [Documentation]  Get Default Session Timeout Via Redfish.
    [Arguments]  ${default}=${True}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # default               If True, sets the default session timeout value to a suite variable.
    # valid_status_codes    The valid status codes for the session service response.

    ${resp}=  Redfish.Get Properties  ${REDFISH_BASE_URI}SessionService
    ...   valid_status_codes=[${valid_status_code}]

    IF  ${default}
        Set Suite Variable  ${DEFAULT_SESSION_TIMEOUT}  ${resp["SessionTimeout"]}
    END

    RETURN  ${resp["SessionTimeout"]}

Set Default Session Timeout Via Redfish
    [Documentation]  Set Default Session Timeout Via Redfish.
    [Arguments]  ${timeout}=${DEFAULT_SESSION_TIMEOUT}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # timeout               The session timeout value to set.
    # valid_status_codes    The valid status codes for the session service response.

    ${resp}=  Redfish.Patch  ${REDFISH_BASE_URI}SessionService  body={'SessionTimeout': ${timeout}}
    ...  valid_status_codes=[${valid_status_code}]

    ${sessionservice_resp}=  Redfish.Get Properties  ${REDFISH_BASE_URI}SessionService
    ...  valid_status_codes=[${valid_status_code}]

    Set Test Variable  ${restore_session_timeout}  ${sessionservice_resp["SessionTimeout"]}

Get Specific Sessions Member Instance Via Redfish
    [Documentation]  Get Specific Sessions Member Instance Via Redfish.
    [Arguments]  ${instance}  ${status_codes}=${HTTP_OK}

    # Description of argument(s):
    # instance        The session instance to retrieve.
    # status_codes    The status codes for the session member instance response.

    ${resp}=  Redfish.Get Properties  ${instance}
    ...  valid_status_codes=[${status_codes}]

    RETURN  ${resp}

Check Session Expired After Timeout
    [Documentation]  Check Session Expired After Timeout.
    [Arguments]  ${session_instance}

    # Description of argument(s):
    # session_instance      The session instance to check for expiration.

    Redfish.Get Properties  ${session_instance}  valid_status_codes=[${HTTP_NOT_FOUND}]
    Log  Session ${session_instance} correctly expired after timeout.
