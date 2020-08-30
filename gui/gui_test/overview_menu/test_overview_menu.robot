*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot

Library         String

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}  //h1[contains(text(), "Overview")]
${xpath_network_info}          //*[@class='page-section'][contains(.,'eth0')]

*** Test Cases ***

Verify Network Information In Overview Page
    [Documentation]  Verify values under network information section.
    [Tags]  Verify_Network_Information_In_Overview Page

    Page Should Contain Element  ${xpath_network_info}

    Element Should Contain  ${xpath_network_info}  Hostname
    ${hostname}=  Get BMC Hostname
    Element Should Contain  ${xpath_network_info}  ${hostname}

    Element Should Contain  ${xpath_network_info}  IP address
    # Get all IP addresses and prefix lengths on system.

    ${ip_addresses}=  Get BMC IP Info
    FOR  ${ip_address}  IN  @{ip_addresses}
      ${ip}=  Fetch From Left  ${ip_address}  \/
      Element Should Contain  ${xpath_network_info}  ${ip}
      Log To Console  ${ip}
    END

    Element Should Contain  ${xpath_network_info}  MAC address
    ${macaddr}=  Get BMC MAC Address
    Element Should Contain  ${xpath_network_info}  ${macaddr}


Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

