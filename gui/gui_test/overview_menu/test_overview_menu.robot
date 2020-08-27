*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot
Resource        ../../../lib/list_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}  //h1[contains(text(), "Overview")]

*** Test Cases ***

Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


Verify event under high priority events section in case of any event
    [Documentation]  Verify event under high priority events section in case of any event.

    Redfish Purge Event Log
    Click Element  ${xpath_refresh_button} 
    Create Test Error Log
    Wait Until Page Contains  xyz.openbmc_project.Common.Error.InternalFailure  timeout=30s


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

