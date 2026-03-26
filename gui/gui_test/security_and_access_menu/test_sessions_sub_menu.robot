*** Settings ***

Documentation   Test OpenBMC GUI "Sessions" sub-menu of "Security and access" menu.

Resource        ../../lib/gui_resource.robot

Suite Teardown  Close Browser

Test Tags      Sessions_Sub_Menu


*** Test Cases ***

Verify Navigation To Sessions Page
    [Documentation]  Verify navigation to sessions page.
    [Tags]  Verify_Navigation_To_Sessions_Page

    Navigate To Required Sub Menu  ${xpath_secuity_and_accesss_menu}  ${xpath_sessions_sub_menu}  sessions
