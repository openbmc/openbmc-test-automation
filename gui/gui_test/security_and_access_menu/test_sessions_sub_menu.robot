*** Settings ***

Documentation   Test OpenBMC GUI "Sessions" sub-menu of "Security and access" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser

Test Tags      Sessions_Sub_Menu


*** Test Cases ***

Verify Navigation To Sessions Page
    [Documentation]  Verify navigation to sessions page.
    [Tags]  Verify_Navigation_To_Sessions_Page

    Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}  ${xpath_sessions_sub_menu}  sessions

Verify Created Redfish Session Reflects On GUI
    [Documentation]  Create session via redfish and verify the session
    ...    reflects on GUI.
    [Tags]  Verify_Created_Redfish_Session_Reflects_On_GUI
    [Teardown]  Delete All Redfish Sessions

    # Navigate to gui sessions page
    Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}  ${xpath_sessions_sub_menu}  sessions

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
