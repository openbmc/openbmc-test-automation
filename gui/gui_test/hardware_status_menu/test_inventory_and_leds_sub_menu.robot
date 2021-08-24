*** Settings ***

Documentation   Test OpenBMC GUI "Inventory and LEDs" sub-menu of "Hardware status" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_inventory_and_leds_heading}  //h1[text()="Inventory and LEDs"]

*** Test Cases ***

Verify Navigation To Inventory And LEDs Page
    [Documentation]  Verify navigation to inventory page.
    [Tags]  Verify_Navigation_To_Inventory_And_LEDs_Page

    Page Should Contain Element  ${xpath_inventory_and_leds_heading}


Verify Components On Inventory And LEDs Page
    [Documentation]  Verify whether required components are displayed under inventory and LEDs page.
    [Tags]  Verify_Components_On_Inventory_And_LEDs_Page

    Page Should Contain  System
    Page Should Contain  BMC manager
    Page Should Contain  Chassis
    Page Should Contain  DIMM slot
    Page Should Contain  Fans
    Page Should Contain  Power supplies
    Page Should Contain  Processors


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_hardware_status_menu}
    Click Element  ${xpath_inventory_and_leds_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  inventory
