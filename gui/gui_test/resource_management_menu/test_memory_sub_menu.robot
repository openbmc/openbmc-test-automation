*** Settings ***

Documentation  Test OpenBMC GUI "Memory" sub-menu of "Resource Management".

Resource        ../../lib/gui_resource.robot
Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_memory_header}           //h1[text()="Memory"]
${xpath_memory_sub_menu}         //*[@data-test-id='nav-item-memory']

*** Test Cases ***

Verify Navigate To Memory Page
    [Documentation]  Login to GUI and perform page navigation to memory page
    ...  and verify it loads successfully.
    [Tags]  Verify_Navigate_To_Memory_Page

    Page Should Contain Element  ${xpath_memory_header}


Verify Existence Of All Sections In Memory Page
    [Documentation]  Login to GUI and perform page navigation to memory page and
    ...  check if all visible sections is actually loaded successfully.
    [Tags]  Verify_Existence_Of_All_Sections_In_Memory_Page

    Page Should Contain  Quick links
    Page Should Contain  Logical memory block size
    Page Should Contain  System memory page setup
    Page Should Contain  I/O Adapter enlarged capacity
    Page Should Contain  Active memory mirroring


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_resource_management_menu}
    Click Element  ${xpath_memory_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  memory

