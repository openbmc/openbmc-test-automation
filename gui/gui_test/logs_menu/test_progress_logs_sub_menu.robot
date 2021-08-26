*** Settings ***

Documentation   Test OpenBMC GUI "Progress logs" sub-menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_progress_logs_heading}   //h1[text()="Progress logs"]
${xpath_progress_search}         //*[contains(@id,"searchInput")]
${xpath_progress_from_date}      //*[@id="input-from-date"]
${xpath_progress_to_date}        //*[@id="input-to-date"]
${xpath_select_all_progress}     //*[@data-test-id="postCode-checkbox-selectAll"]
${xpath_progress_action_export}  //*[contains(text(),"Export all")]


*** Test Cases ***

Verify Navigation To Progress Logs Page
    [Documentation]  Verify navigation to Progress Logs page.
    [Tags]  Verify_Navigation_To_Progress_Logs_Page

    Page Should Contain Element  ${xpath_progress_logs_heading}


Verify Existence Of All Buttons In Progress Logs Page
    [Documentation]  Verify existence of all buttons in Progress Logs page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Progress_Logs_Page

    Page Should Contain Element  ${xpath_select_all_progress}  limit=1
    Page Should Contain Element  ${xpath_progress_action_export}  limit=1


Verify Existence Of All Input boxes In Progress Logs Page
    [Documentation]  Verify existence of all input boxes in Progress Logs page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Progress_Logs_Page

    # Search logs.
    Page Should Contain Element  ${xpath_progress_search}

    # Date filter.
    Page Should Contain Element  ${xpath_progress_from_date}  limit=1
    Page Should Contain Element  ${xpath_progress_to_date}  limit=1


*** Keywords ***

Test Setup Execution
    [Documentation]  Navigate to the progress logs page from main menu.

    Click Element  ${xpath_logs_menu}
    Click Element  ${xpath_progress_logs_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  post-code-logs
