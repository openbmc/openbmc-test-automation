*** Settings ***
Documentation   Test OpenBMC "KVM" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_redfish_resource.robot
Resource        ../../../lib/bmc_redfish_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers

Test Tags       KVM_Sub_Menu

*** Variables ***

${xpath_kvm_ctl_alt_delete_button}       //button[contains(normalize-space(), 'Send Ctrl+Alt+Delete')]
${xpath_kvm_new_tab_button}              //button[contains(normalize-space(), 'Open in new tab')]
${xpath_kvm_canvas}                      //div[@id='terminal-kvm']//canvas
${xpath_kvm_status_connected}            //*[contains(normalize-space(), 'Connected')]
${xpath_kvm_status_disconnected}         //*[contains(normalize-space(), 'Disconnected')]
${element_wait_timeout}                  45s
# Password used by KVM Roll-Based Access Control test users.
${TEST_USER_PASSWORD}                    0penBmc123!

*** Test Cases ***

Verify Navigation To KVM Page
    [Documentation]  Verify navigation to KVM page.
    [Tags]  Verify_Navigation_To_KVM_Page

    Page Should Contain    KVM


Verify Existence Of All Sections And Buttons In KVM Page
    [Documentation]  Verify existence of all sections and buttons in KVM page.
    [Tags]  Verify_Existence_Of_All_Sections_And_Buttons_In_KVM_Page

    Verify KVM Is Connected And Elements Are Visible


Verify Navigation To Open New Tab In KVM Page
    [Documentation]  Verify navigation to open new tab in KVM page.
    [Tags]  Verify_Navigation_To_Open_New_Tab_In_KVM_Page
    [Teardown]  Run Keywords  Close Window
    ...    AND  Switch Window  MAIN

    Click Element  ${xpath_kvm_new_tab_button}
    Wait Until Keyword Succeeds  30 sec  5 sec  Switch Window  NEW

    # Maximize the new window.
    Maximize Browser Window
    Wait Until Page Contains  Status  timeout=30s
    Wait Until Element Is Visible  ${xpath_kvm_ctl_alt_delete_button}  timeout=${element_wait_timeout}

    # Open new tab button should not be present in the sub kvm page.
    Page Should Not Contain Element  ${xpath_kvm_new_tab_button}


Verify KVM WebSocket Unauthorized Access Is Rejected
    [Documentation]  Verify if unauthorized web socket access is rejected.
    ...  Attempt connection to KVM WebSocket endpoint without authentication.
    ...  Two approaches are used:
    ...  1. Direct HTTP request via Python requests (no auth headers) - expects HTTP 401.
    ...  2. Browser fetch with credentials:omit (no session cookie) - expects HTTP 401.
    [Tags]  Verify_KVM_WebSocket_Unauthorized_Access_Is_Rejected

    # --- Approach 1: Direct HTTP request without authentication ---
    VAR  ${kvm_endpoint}  ${OPENBMC_GUI_URL}/kvm/0

    # Attempt HTTP GET without any authentication headers - simulates unauthenticated client.
    ${response}=  Evaluate  requests.get('${kvm_endpoint}', verify=False, allow_redirects=False)  modules=requests

    # Verify the BMC rejects the unauthenticated request with HTTP 401.
    Should Be Equal As Integers  ${response.status_code}  401
    ...  KVM WebSocket endpoint should reject unauthenticated HTTP request with 401

    # --- Approach 2: Browser fetch without session cookie ---
    # credentials:'omit' ensures the browser sends no cookies - simulates no active session.
    Execute Javascript
    ...  window._kvmUnauthStatus = null;
    ...  fetch('/kvm/0', {credentials: 'omit'})
    ...      .then(function(r) { window._kvmUnauthStatus = r.status; })
    ...      .catch(function(e) { window._kvmUnauthStatus = 0; });

    # Wait for the async fetch to complete.
    Sleep  3s

    # Verify the BMC also rejects the cookie-less browser request with HTTP 401.
    ${browser_status}=  Execute Javascript  return window._kvmUnauthStatus;
    Should Be Equal As Integers  ${browser_status}  401
    ...  KVM WebSocket endpoint should reject browser request without session cookie with 401


Verify KVM Role Based Access Control
    [Documentation]  Verify KVM access control for all user roles via Web UI only.
    ...  Logs in as each role through the browser and checks the KVM page state:
    ...  - Administrator : Connected status, canvas rendered, Ctrl+Alt+Delete visible
    ...  - Operator      : Disconnected status, Open-in-new-tab visible,
    ...                    Ctrl+Alt+Delete absent, canvas absent
    ...  - ReadOnly      : Disconnected status, Ctrl+Alt+Delete absent, canvas absent.
    [Tags]  Verify_KVM_Role_Based_Access_Control_Via_Web_UI
    [Teardown]  KVM Role-Based Access Control Test Teardown  ${operator_user}  ${readonly_user}

    VAR  ${operator_user}  kvm_op_ui_test
    VAR  ${readonly_user}  kvm_ro_ui_test
    VAR  ${test_pass}  ${TEST_USER_PASSWORD}

    # --- Setup: create test users via Redfish Create User keyword ---
    Redfish Create User  ${operator_user}  ${test_pass}  Operator  ${True}  force=${True}
    Redfish Create User  ${readonly_user}  ${test_pass}  ReadOnly  ${True}  force=${True}

    # ---------------------------------------------------------------
    # Web UI check 1: Administrator
    # Already logged in as admin from suite setup - navigate to KVM.
    # ---------------------------------------------------------------
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm
    Verify KVM Is Connected And Elements Are Visible

    # ---------------------------------------------------------------
    # Web UI check 2: Operator
    # KVM page loads but WebSocket is rejected → Disconnected.
    # ---------------------------------------------------------------
    Logout GUI
    Login And Navigate To KVM  ${operator_user}  ${test_pass}
    Page Should Contain  KVM
    # Status must be Disconnected.
    Wait Until Element Is Visible  ${xpath_kvm_status_disconnected}  timeout=${element_wait_timeout}
    # "Open in new tab" button must be present (page loaded successfully).
    Page Should Contain Element  ${xpath_kvm_new_tab_button}
    ...  Operator should see Open in new tab button
    # "Send Ctrl+Alt+Delete" must be absent (only shown when Connected).
    Page Should Not Contain Element  ${xpath_kvm_ctl_alt_delete_button}
    ...  Operator should NOT see Ctrl+Alt+Delete button (Disconnected)
    # KVM canvas must be absent (WebSocket rejected).
    Page Should Not Contain Element  ${xpath_kvm_canvas}
    ...  Operator should NOT see KVM canvas (Disconnected)

    # ---------------------------------------------------------------
    # Web UI check 3: ReadOnly
    # KVM page loads but WebSocket is rejected → Disconnected.
    # ---------------------------------------------------------------
    Logout GUI
    Login And Navigate To KVM  ${readonly_user}  ${test_pass}
    Page Should Contain  KVM
    # Status must be Disconnected.
    Wait Until Element Is Visible  ${xpath_kvm_status_disconnected}  timeout=${element_wait_timeout}
    # "Send Ctrl+Alt+Delete" must be absent.
    Page Should Not Contain Element  ${xpath_kvm_ctl_alt_delete_button}
    ...  ReadOnly should NOT see Ctrl+Alt+Delete button (Disconnected)
    # KVM canvas must be absent.
    Page Should Not Contain Element  ${xpath_kvm_canvas}
    ...  ReadOnly should NOT see KVM canvas (Disconnected)


Verify KVM Session Expiry Handling
    [Documentation]  Allow Web UI session to expire with KVM active and check if
    ...  KVM disconnects and prompts re-login.
    ...  Approach: clear all browser cookies while KVM is connected, reload the
    ...  page, and verify the login page appears (session expired / re-login prompt).
    [Tags]  Verify_KVM_Session_Expiry_Handling

    # Ensure KVM is connected and all elements visible before expiring the session.
    Verify KVM Is Connected And Elements Are Visible

    # Expire the session by clearing all cookies (simulates session timeout).
    Delete All Cookies
    Reload Page

    # Verify the browser redirects to the login page (session expired).
    Wait Until Element Is Visible  ${xpath_login_username_input}
    ...  timeout=${element_wait_timeout}
    ...  error=KVM should disconnect and prompt re-login when session expires

    # Restore the session for subsequent tests.
    Login And Navigate To KVM


Verify KVM Connect Disconnect Loop
    [Documentation]  Repeatedly connect and disconnect KVM 10 times and verify
    ...  KVM connects successfully each time.
    [Tags]  Verify_KVM_Connect_Disconnect_Loop

    FOR  ${index}  IN RANGE  10
        # Navigate to KVM page (connect - new WebSocket session).
        Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm
        # Verify KVM connects on each iteration.
        Verify KVM Is Connected And Elements Are Visible
        # Navigate away (disconnect - WebSocket closed).
        Go To  ${OPENBMC_GUI_URL}
        Wait Until Page Contains  Overview  timeout=10s
    END

    # Final verification: KVM still connects after 10 cycles (no bmcweb crash).
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm
    Verify KVM Is Connected And Elements Are Visible
    Page Should Not Contain  Error


Verify KVM Multiple Sessions
    [Documentation]  Attempt Multiple KVM session from another browser and verify
    ...  at a time maximum 4 sessions are able to connect.
    [Tags]  Verify_KVM_Multiple_Sessions
    [Teardown]  Close Sessions  ${session_num}

    VAR  ${session_num}  1
    # First session is already active from suite setup.
    Verify KVM Is Connected And Elements Are Visible

    # Session 1 is already established in setup.
    # Open sessions 2-5 (2-4 → Connected and 5 → Disconnected/rejected).
    FOR  ${session_num}  IN RANGE  2  6
        IF  ${session_num} < 5
            Create KVM Session  status=${xpath_kvm_status_connected}
        ELSE
            Create KVM Session  status=${xpath_kvm_status_disconnected}
        END
    END

    # Switch back to the first browser and verify it's still working.
    Switch Browser  1
    Verify KVM Is Connected And Elements Are Visible


Verify KVM Session Drops And Reconnects After BMC Reboot
    [Documentation]  Reboot BMC while KVM is active and check if session drops
    ...  and reconnect works after BMC is up.
    [Tags]  Verify_KVM_Session_Drops_And_Reconnects_After_BMC_Reboot

    # Ensure KVM is active before rebooting BMC.
    Verify KVM Is Connected And Elements Are Visible

    # Reboot BMC via Redfish while KVM is active.
    Redfish.Post  /redfish/v1/Managers/bmc/Actions/Manager.Reset
    ...  body={'ResetType': 'GracefulRestart'}
    ...  valid_status_codes=[200]

    # Verify KVM session drops (Disconnected status) during BMC reboot.
    Wait Until Keyword Succeeds  60 sec  5 sec  Page Should Contain Element
    ...  ${xpath_kvm_status_disconnected}
    ...  KVM session should drop when BMC reboots

    # Wait for BMC to come back up.
    Wait For Host To Ping  ${OPENBMC_HOST}  5 min

    # Reload the page and log in again after BMC reboot.
    Reload Page
    Sleep  30s
    Login And Navigate To KVM

    # Verify KVM reconnects successfully after BMC is up.
    Verify KVM Is Connected And Elements Are Visible


Verify KVM Backend Service Unavailable
    [Documentation]  Stop KVM backend service and check if user friendly error
    ...  messages are displayed in the Web UI (negative test).
    [Tags]  Verify_KVM_Backend_Service_Unavailable
    [Teardown]  BMC Execute Command  systemctl start obmc-ikvm.service

    # Ensure KVM is active.
    Verify KVM Is Connected And Elements Are Visible

    # Stop KVM backend service via SSH.
    BMC Execute Command  systemctl stop obmc-ikvm.service

    # Reload the page to trigger reconnection attempt.
    Reload Page
    Sleep  5s
    # Verify KVM shows Disconnected status after service stopped.
    Wait Until Element Is Visible  ${xpath_kvm_status_disconnected}
    ...  timeout=${element_wait_timeout}
    ...  error=KVM should show Disconnected when backend service is stopped

    # Restart KVM service to restore functionality.
    BMC Execute Command  systemctl start obmc-ikvm.service
    Reload Page
    Sleep  5s
    # Verify KVM shows Connected status after service restart.
    Wait Until Element Is Visible  ${xpath_kvm_status_connected}
    ...  timeout=${element_wait_timeout}
    ...  error=KVM should show Connected when backend service is restarted


Verify KVM Session Cleanup After Browser Forced Close
    [Documentation]  Close browser tab abruptly and check if a session cleanup
    ...  is performed to allow reconnection.
    [Tags]  Verify_KVM_Session_Cleanup_After_Browser_Forced_Close

    # Ensure KVM is active.
    Verify KVM Is Connected And Elements Are Visible

    # Close browser abruptly (without proper logout - simulates forced close).
    Close Browser
    Sleep  1s
    # Open a new browser and navigate to KVM.
    Open Browser With URL  ${OPENBMC_GUI_URL}
    Login And Navigate To KVM

    # Verify KVM connects (session cleanup was performed, reconnection allowed).
    Verify KVM Is Connected And Elements Are Visible


Verify KVM Backend Logging
    [Documentation]  Trigger KVM scenarios and verify meaningful
    ...              obmc-ikvm backend logs are generated in BMC journal.
    [Tags]  Verify_KVM_Backend_Logging

    ${start_time}  ${stderr}  ${rc}=  BMC Execute Command
    ...  date "+%Y-%m-%d %H:%M:%S"
    Should Be Empty  ${stderr}
    Should Be Equal As Integers  ${rc}  0

    ${restart_count_before}  ${stderr}  ${rc}=  Bmc Execute Command
    ...  systemctl show obmc-ikvm.service -p NRestarts --value
    Should Be Empty  ${stderr}
    Should Be Equal As Integers  ${rc}  0

    # Open authenticated KVM session.
    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm
    Sleep  10s
    Close Browser
    Sleep  2s

    # Attempt unauthenticated KVM access.
    ${response}=  Evaluate
    ...  requests.get('${OPENBMC_GUI_URL}/kvm/0', verify=False, allow_redirects=False)
    ...  modules=requests
    Should Be Equal As Integers
    ...  ${response.status_code}
    ...  401
    ...  Unauthorized KVM access should return HTTP 401

    ${logs}  ${stderr}  ${rc}=  Bmc Execute Command
    ...  journalctl -u obmc-ikvm.service --since "${start_time}" --no-pager
    Should Be Empty  ${stderr}
    Should Be Equal As Integers  ${rc}  0
    # Ensure journal collection succeeded.
    Should Not Be Empty  ${logs}
    Log  KVM Backend Logs:\n${logs}
    # Meaningful logs should exist.
    Should Not Contain  ${logs}  -- No entries --  msg=obmc-ikvm did not generate any backend logs
    # Verify at least one KVM-related log entry exists.
    Should Contain Any  ${logs}  Got connection from client  Client disconnected
    ...  Session closed
    ...  WebSocket connection established

    ${state}  ${stderr}  ${rc}=  Bmc Execute Command
    ...  systemctl is-active obmc-ikvm.service
    Should Be Equal  ${state}  active
    Should Be Empty  ${stderr}
    Should Be Equal As Integers  ${rc}  0

    ${restart_count_after}  ${stderr}  ${rc}=  Bmc Execute Command
    ...  systemctl show obmc-ikvm.service -p NRestarts --value
    Should Be Empty  ${stderr}
    Should Be Equal As Integers  ${rc}  0
    Should Be Equal As Integers
    ...  ${restart_count_after}
    ...  ${restart_count_before}
    ...  obmc-ikvm service restarted unexpectedly


*** Keywords ***

Suite Setup Execution
    [Documentation]  Perform suite setup operation.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm


Verify KVM Is Connected And Elements Are Visible
    [Documentation]  Verify KVM page is loaded and KVM is connected with all
    ...  expected UI elements visible.
    ...  Checks: page title "KVM", Connected status (with retry), Ctrl+Alt+Delete
    ...  button, Open in new tab button, and KVM canvas.

    Page Should Contain  KVM
    Wait Until Page Contains  Status  timeout=30s
    Wait Until Element Is Visible  ${xpath_kvm_status_connected}
    ...  timeout=${element_wait_timeout}
    Page Should Contain Element  ${xpath_kvm_ctl_alt_delete_button}
    Page Should Contain Element  ${xpath_kvm_new_tab_button}
    Page Should Contain Element  ${xpath_kvm_canvas}


KVM Role-Based Access Control Test Teardown
    [Documentation]  Restore the admin GUI session and delete Role Base Access
    ...  Control test users.
    [Arguments]  ${operator_user}  ${readonly_user}

    # Description of argument(s):
    # operator_user   Username of the Operator role test user to be deleted.
    # readonly_user   Username of the ReadOnly role test user to be deleted.

    # Restore admin session in the browser.
    Logout GUI
    Login And Navigate To KVM
    # Delete test users via Redfish API.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${operator_user}
    ...  valid_status_codes=[200, 404]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${readonly_user}
    ...  valid_status_codes=[200, 404]


Create KVM Session
    [Documentation]  Open a browser session and attempt to establish a
    ...  KVM connection using the same user credentials. Verify the KVM session
    ...  is handled gracefully by confirming the session state is either
    ...  Connected or Disconnected, with no UI errors, crashes, or unexpected
    ...  behavior.
    [Arguments]  ${status}=${xpath_kvm_status_connected}

    # Description of argument(s):
    # status    XPath of the expected KVM session status indicator. Valid values
    #           include ${xpath_kvm_status_connected} and
    #           ${xpath_kvm_status_disconnected}.
    # Open a browser instance and log in as the same admin user.
    Open Browser With URL  ${OPENBMC_GUI_URL}
    Login And Navigate To KVM

    # Verify the session is Connected/Disconnected.
    Wait Until Element Is Visible  ${status}  timeout=${element_wait_timeout}
    Page Should Not Contain  Error


Login And Navigate To KVM
    [Documentation]  Log in to the WebUI using the specified credentials and
    ...  navigate to the KVM page.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # username    username used to log in to the WebUI.
    # password    password associated with the specified user account.
    Login GUI  ${username}  ${password}
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_kvm_sub_menu}  kvm


Close Sessions
    [Documentation]  Close all secondary browser sessions opened during the test,
    ...  iterating from the highest session number down to session 2, then switch
    ...  back to the primary browser (session 1).
    [Arguments]  ${sessions}

    # Description of argument(s):
    # sessions    Total number of browser sessions currently open (including the
    #             primary session). Secondary sessions from 2 to ${sessions} will
    #             be closed.

    FOR  ${session_num}  IN RANGE  ${sessions}  1  -1
        Switch Browser  ${session_num}
        Close Browser
    END
    Switch Browser  1
