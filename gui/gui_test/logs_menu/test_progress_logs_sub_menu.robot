*** Settings ***

Documentation   Test OpenBMC GUI "Progress logs" sub-menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_progress_logs_heading}   //h1[text()="Progress logs"]
${xpath_search_logs_input}       //*[contains(@id,"searchInput")]
${xpath_from_date_input}         //*[@id="input-from-date"]
${xpath_to_date_input}           //*[@id="input-to-date"]
${xpath_select_all_checkbox}     //*[@data-test-id="postCode-checkbox-selectAll"]
${xpath_progress_action_export}  //*[contains(text(),"Export all")]


*** Test Cases ***

Verify Navigation To Progress Logs Page
    [Documentation]  Verify navigation to progress logs page.
    [Tags]  Verify_Navigation_To_Progress_Logs_Page

    Page Should Contain Element  ${xpath_progress_logs_heading}


Verify Existence Of All Buttons In Progress Logs Page
    [Documentation]  Verify existence of all buttons in progress logs page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Progress_Logs_Page

    Page Should Contain Element  ${xpath_select_all_checkbox}  limit=1
    Page Should Contain Element  ${xpath_progress_action_export}  limit=1


Verify Existence Of All Input Boxes In Progress Logs Page
    [Documentation]  Verify existence of all input boxes in progress logs page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Progress_Logs_Page

    # Search logs.
    Page Should Contain Element  ${xpath_search_logs_input}

    # Date filter.
    Page Should Contain Element  ${xpath_from_date_input}  limit=1
    Page Should Contain Element  ${xpath_to_date_input}  limit=1


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_logs_menu}
    Click Element  ${xpath_progress_logs_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  post-code-logs
