*** Settings ***

Documentation  Test OpenBMC GUI "Dump logs" sub-menu of "Logs" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers

Test Tags      Dump_Logs_Sub_Menu

*** Variables ***
${xpath_dump_button}             //*[contains(text(),"Initiate dump")]
${xpath_dump_data}               //*[contains(text(),"Dumps available on BMC")]
${xpath_filter_button}           //*[@class='btn btn-md btn-link dropdown-toggle dropdown-toggle-no-caret']
${xpath_dump_bmc_entry}          //*[contains(text(),"BMC Dump Entry")]
${xpath_dump_hostboot_entry}     //*[contains(text(),"Hostboot Dump Entry")]
${xpath_dump_resource_entry}     //*[contains(text(),"Resource Dump Entry")]
${xpath_dump_system_entry}       //*[contains(text(),"System Dump Entry")]
${xpath_dump_clear_all}          //*[@data-test-id="tableFilter-button-clearAll"]

*** Test Cases ***

Verify Existence Of All Buttons In Dump Logs Page
    [Documentation]  Verify existence of all buttons in Dump Logs page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Dump_Logs_Page

    # Verify the header in the Dump Logs page.
    Page Should Contain Element  ${xpath_dumps_header}  limit=1

    # Verify the initiate dump button in the Dump Logs page.
    Page Should Contain Element  ${xpath_dump_button}  limit=1

    # Verify the dump data section in the Dump Logs page.
    Page Should Contain Element  ${xpath_dump_data}  limit=1

    # Click on filter button to show the filter options.
    Click Element  ${xpath_filter_button}

    # Verify types of dumps: BMC Dump Entry, Hostboot Dump Entry, Resource Dump Entry, System Dump Entry.
    # Select each type of dump entry to verify the selection.
    Page Should Contain Element  ${xpath_dump_bmc_entry}  limit=1
    Click Element At Coordinates  ${xpath_dump_bmc_entry}  0  0

    Page Should Contain Element  ${xpath_dump_hostboot_entry}  limit=1
    Click Element At Coordinates  ${xpath_dump_hostboot_entry}  0  0

    Page Should Contain Element  ${xpath_dump_resource_entry}  limit=1
    Click Element At Coordinates  ${xpath_dump_resource_entry}  0  0

    Page Should Contain Element  ${xpath_dump_system_entry}  limit=1
    Click Element At Coordinates  ${xpath_dump_system_entry}  0  0

    # Verify the clear all button and click to clear all the selected sections.
    Page Should Contain Element  ${xpath_dump_clear_all}  limit=1
    Click Element  ${xpath_dump_clear_all}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Login bmc gui.
    Launch Browser And Login GUI

    # Navigate to gui sessions page.
    Navigate To Required Sub Menu  ${xpath_logs_menu}  ${xpath_dumps_sub_menu}  dumps