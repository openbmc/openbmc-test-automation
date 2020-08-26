*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}  //h1[contains(text(), "Overview")]
${xpath_server_info}           //*[@class='page-section'][contains(.,'Model') and contains(.,'Manufacturer') and contains(.,'Serial number')]

*** Test Cases ***

Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


Verify Server Information Section
    [Documentation]  Verify values under server information section in overview page.
    [Tags]  Verify_Server_Information_Section

    ${redfish_machine_model}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  Model
    Page Should Contain  ${redfish_machine_model}

    ${redfish_serial_number}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  SerialNumber
    Page Should Contain  ${redfish_serial_number}

    ${redfish_motherboard_manufacturer}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_URI}motherboard  Manufacturer

    Page Should Contain  ${redfish_motherboard_manufacturer}


Verify BMC Information Section
    [Documentation]  Verify BMC information section in overview page.
    [Tags]  Verify_BMC_Information_Section

    ${firmware_version}=  Redfish Get BMC Version
    Page Should Contain  ${firmware_version}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

