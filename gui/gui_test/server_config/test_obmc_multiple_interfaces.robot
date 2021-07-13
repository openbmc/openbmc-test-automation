*** Settings ***
Documentation   Test BMC multiple network interface functionalities via GUI.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/resource.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${bmc_url}             https://${OPENBMC_HOST}
${bmc_url_1}           https://${OPENBMC_HOST_1}

*** Test Cases ***

Verify BMC GUI Is Accessible Via Both Network Interfaces
    [Documentation]  Verify BMC GUI is accessible via both network interfaces.
    [Tags]  Verify_BMC_GUI_Is_Accessible_Via_Both_Network_Interfaces
    [Teardown]  Close All Browsers

    Start Virtual Display
    ${browser_ID}=  Open Browser  ${bmc_url}  alias=tab1
    Set Window Size  1920  1080
    ${browser_ID}=  Open Browser  ${bmc_url_1}  alias=tab2
    Set Window Size  1920  1080
    Switch Browser  tab1
    Run Keywords  Login GUI  AND  Logout GUI
    Switch Browser  tab2
    Run Keywords  Login GUI  AND  Logout GUI

*** keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_1

    # Check both interfaces are configured and reachable.
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}
