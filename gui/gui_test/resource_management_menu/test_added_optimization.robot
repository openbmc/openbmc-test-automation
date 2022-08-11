*** Settings ***

Documentation  Test suite for Open BMC GUI "Added optimization" sub-menu of "Resource Management".

Resource        ../../lib/gui_resource.robot
Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_added_optimization_header}      //h1[text()="Added optimization"]
${xpath_added_optimization_sub_menu}    //*[@data-test-id='nav-item-added-optimization']

*** Test Cases ***

Verify Navigate To Added Optimization Page
    [Documentation]  Login to GUI and perform page navigation to
    ...  added optimization page and verify it loads successfully.
    [Tags]  Verify_Navigate_To_Added_Optimization_Page

    Page Should Contain Element  ${xpath_added_optimization_header}


Verify Existence Of All Sections In Added Optimization Page
    [Documentation]  Verify existence of all sections in added optimization page
    [Tags]  Verify_Existence_Of_All_Sections_In_Added_Optimization

    Page Should Contain  Lateral cast out
    Page Should Contain  Frequency cap
    Page Should Contain  Aggressive prefetch


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_resource_management_menu}
    Click Element  ${xpath_added_optimization_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  added-optimization
