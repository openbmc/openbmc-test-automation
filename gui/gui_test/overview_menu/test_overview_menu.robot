*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot
Resource        ../../../lib/list_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}  //h1[contains(text(), "Overview")]
${errolog_table_data}          //div[contains(@class, 'table-responsive-md')]
${CMD_INTERNAL_FAILURE}        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0

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
    Create Test Error Log
    Wait Until Page Contains Element  ${errolog_table_data}  timeout=10
    Table Should Contain  ${errolog_table_data}  xyz.openbmc_project.Common.Error.InternalFailure


*** Keywords ***

Create Test Error Log
    [Documentation]  Generate test PEL log.

    BMC Execute Command  ${CMD_INTERNAL_FAILURE}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

