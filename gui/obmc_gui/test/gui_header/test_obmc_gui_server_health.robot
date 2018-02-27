*** Settings ***

Documentation  Test Open BMC GUI server health under GUI Header.

Resource        ../../lib/resource.robot
Resource        ../../../../lib/boot_utils.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Suite Teardown Execution
Test Setup      Click Element  ${xpath_select_server_health}

*** Test Cases ***

Verify Event Log Text Appears By Clicking Server Health
    [Documentation]  Check "Event Log" text appears by clicking server health
    ...  in gui_header.
    [Tags]  Verify_Event_Log_Text_Appears_By_Clicking_Server_Health

    Wait Until Page Contains Element  event-log
    Page should contain  Event log

Verify Filters By Severity Elements Appears
    [Documentation]  Check event log filters appears by clicking server health
    ...  in gui_header.
    [Tags]  Verify_Filters_By_Severity_Elements_Appears

    Page Should Contain Element  ${xpath_event_severity_all}  limit=1
    Page Should Contain Element  ${xpath_event_severity_high}  limit=1
    Page Should Contain Element  ${xpath_event_severity_medium}  limit=1
    Page Should Contain Element  ${xpath_event_severity_low}  limit=1

Verify Drop Down Button User Timezone Appears
    [Documentation]  Check drop down button of user timezone appears by
    ...  clicking server health in gui_header.
    [Tags]  Verify_Drop_Down_Button_User_Timezone_Appears

    Page Should Contain Button  ${xpath_drop_down_timezone_edt}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    # Above line ensure that page is not in refreshing state, Helps to click
    # drop down element.
    Click Element  class:dropdown__button
    Page Should Contain Button  ${xpath_drop_down_timezone_utc}


*** Keywords ***

Suite Setup Execution

    Open Browser With URL  ${obmc_gui_url}
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

Suite Teardown Execution

    Click Element  header
    Close Browser




