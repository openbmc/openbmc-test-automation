*** Settings ***

Documentation   Test OpenBMC GUI "Sessions" sub-menu of "Security and access" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

Test Tags      Sessions_Sub_Menu

*** Variables ***

${xpath_sessions_heading}  //h1[contains(text(),'sessions')]


*** Test Cases ***

Verify Navigation To Sessions Page
    [Documentation]  Verify navigation to sessions page.
    [Tags]  Verify_Navigation_To_Sessions_Page

    Page Should Contain Element  ${xpath_sessions_heading}

Verify Created Redfish Session Reflects On GUI
    [Documentation]  Create session via redfish and verify the session
    ...    reflects on GUI.
    [Tags]  Verify_Created_Redfish_Session_Reflects_On_GUI
    [Teardown]  Delete All Redfish Sessions

    # Create a new user session.
    ${resp}=  Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body={'UserName':'${OPENBMC_USERNAME}', 'Password': '${OPENBMC_PASSWORD}'}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Extract the session ID.
    ${session_id}=  Set Variable  ${resp.dict['@odata.id'].split('/')[-1]}

    # Refresh the sessions page.
    Click Element  ${xpath_refresh_button}

    # Verify the session exists.
    Page Should Contain    ${session_id}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_sessions_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  sessions
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
