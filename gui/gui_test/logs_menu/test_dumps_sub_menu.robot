*** Settings ***

Documentation   Test OpenBMC GUI "Dumps" sub-menu of "Logs" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_dumps_heading}         //h1[text()="Dumps"]
${xpath_initiate_dump_button}  //button[contains(text(),'Initiate dump')]
${xpath_select_dump_type}      //*[@id="selectDumpType"]
${xpath_dump_from_date}        //*[@id="input-from-date"]
${xpath_dump_to_date}          //*[@id="input-to-date"]
${xpath_dump_search_global}    //*[contains(@id,"searchInput")]


*** Test Cases ***

Verify Navigation To Dumps Page
    [Documentation]  Verify navigation to dumps page.
    [Tags]  Verify_Navigation_To_Dumps_Page

    Page Should Contain Element  ${xpath_dumps_heading}


Verify Existence Of All Sections In Dump Page
    [Documentation]  Verify existence of all sections in dump page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Dump_Page

    Page Should Contain  Initiate dump
    Page Should Contain  Dumps available on BMC


Verify Existence Of All Buttons In Dump Page
    [Documentation]  Verify existence of all buttons in dump page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Dump_Page

    Page Should Contain Element  ${xpath_initiate_dump_button}

Verify Existence Of All Input Boxes In Dump Page
    [Documentation]  Verify existence of all input boxes in dump page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Dump_Page

    Page Should Contain Element  ${xpath_select_dump_type}
    Page Should Contain Element  ${xpath_dump_from_date}
    Page Should Contain Element  ${xpath_dump_to_date}
    Page Should Contain Element  ${xpath_dump_search_global}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_logs_menu}
    Click Element  ${xpath_dumps_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  dumps
