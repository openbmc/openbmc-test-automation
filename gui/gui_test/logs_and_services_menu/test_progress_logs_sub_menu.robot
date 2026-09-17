*** Settings ***

Documentation   Test OpenBMC GUI "Progress logs" sub-menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

Test Tags      Progress_Logs_Sub_Menu

*** Variables ***

${xpath_progress_logs_heading}           //h1[text()="Progress logs"]
${xpath_search_logs_input}               //*[contains(@id,"searchInput")]
${xpath_from_date_input}                 (//input[@class='dp-input'])[1]
${xpath_to_date_input}                   (//input[@class='dp-input'])[2]
${xpath_view_realtime_button}            //button[contains(normalize-space(.),"View progress codes in real time")]


*** Test Cases ***

Verify Navigation To Progress Logs Page
    [Documentation]  Verify navigation to progress logs page.
    [Tags]  Verify_Navigation_To_Progress_Logs_Page

    Page Should Contain Element  ${xpath_progress_logs_heading}


Verify Existence Of All Input Boxes In Progress Logs Page
    [Documentation]  Verify existence of all input boxes in progress logs page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Progress_Logs_Page

    # Search logs.
    Page Should Contain Element   ${xpath_search_logs_input}

    # Date From and To filter.
    Page Should Contain Element   ${xpath_from_date_input}  limit=1
    Page Should Contain Element   ${xpath_to_date_input}  limit=1


Verify Existence Of All Sections In Progress Logs Page
    [Documentation]  Verify existence of all sections in Progress Logs page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Progress_Logs_Page

    Page Should Contain  Progress logs


Verify Existence Of All Fields In Progress Logs Page
    [Documentation]  Verify existence of all fields in progress Logs page.
    [Tags]  Verify_Existence_Of_All_Fields_In_Progress_Logs_Page
    [Template]  Page Should Contain

    # Expected column headers visible in the progress code table.
    Created
    Time stamp offset
    Boot count
    Code


Verify View Progress Codes In Real Time Button Exists
    [Documentation]  Verify that the "View progress codes in real time" button
    ...  is present on the Progress Logs page.
    [Tags]  Verify_View_Progress_Codes_In_Real_Time_Button_Exists

    Page Should Contain Element  ${xpath_view_realtime_button}  limit=1


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_logs_menu}  ${xpath_progress_logs_sub_menu}  post-code-logs
