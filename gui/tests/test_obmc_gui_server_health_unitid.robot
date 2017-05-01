*** Settings ***

Documentation  Test OBMC GUI Server Health Unit ID toggle.

Resource  ../lib/obmcgui_utils.robot

Suite Setup  OpenBMC GUI Login
Suite Teardown  OpenBMC GUI Logoff

*** Test Cases ***

Unit ID Indicator on
    [Documentation]  Unit ID LED toggle on.
    [Tags]  Unit_ID_Indicator_on

    Model List Click  ${server_health}
    View List Click  ${unit_id}  ${unit_id_control}
    Controller Unit_ID Manipulation  ${unit_id_switch}  ${unit_id_toggle_switch}

Unit ID Indicator off
    [Documentation]  Unit ID LED toggle off.
    [Tags]  Unit_ID_Indicator_off

    Model List Click  ${server_health}
    View List Click  ${unit_id}  ${unit_id_control}
    Controller Unit_ID Manipulation  ${unit_id_switch}  ${unit_id_toggle_switch}
