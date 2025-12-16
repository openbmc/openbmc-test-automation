*** Settings ***

Documentation  Test OpenBMC GUI "Reboot BMC" sub-menu of "Operation" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/common_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

Test Tags      Reboot_BMC_Sub_Menu

*** Variables ***

${xpath_reboot_bmc_heading}      //h1[text()="Reboot BMC"]
${xpath_reboot_bmc_button}       //button[contains(text(),'Reboot BMC')]
${xpath_reboot_cancel_button}    //button[contains(text(),'Cancel')]


*** Test Cases ***

Verify Navigation To Reboot BMC Page
    [Documentation]  Verify navigation to reboot BMC page.
    [Tags]  Verify_Navigation_To_Reboot_BMC_Page

    Page Should Contain Element  ${xpath_reboot_bmc_heading}


Verify Existence Of All Buttons In Reboot BMC Page
    [Documentation]  Verify existence of all buttons in reboot BMC page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Reboot_BMC_Page

    Page Should Contain Element  ${xpath_reboot_bmc_button}


Verify Existence Of All Sections In Reboot BMC Page
    [Documentation]  Verify Existence Of All Sections In Reboot BMC Page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Reboot_BMC_Page

    Page Should Contain  Last BMC reboot


Verify Canceling Operation On BMC Reboot Operation
    [Documentation]  Verify Canceling Operation On BMC Reboot operation
    [Tags]  Verify_Canceling_Operation_On_BMC_Reboot_Operation

    Click Element  ${xpath_reboot_bmc_button}

    # Delay added for cancel button to appear.
    Sleep  5s

    Click Element At Coordinates  ${xpath_reboot_cancel_button}  0  0
    Wait Until Element Is Not Visible  ${xpath_reboot_cancel_button}  timeout=15


Verify BMC Reboot Operation
    [Documentation]  Verify BMC Reboot operation
    [Tags]  Verify_BMC_Reboot_Operation

    Click Element  ${xpath_reboot_bmc_button}

    # Delay added for confirm button to appear.
    Sleep  5s
    Click Element At Coordinates  ${xpath_confirm_button}  0  0

    # Checks BMC gets into Unpingable state and later becomes Pingable.
    Wait Until Keyword Succeeds  1 min  5 sec  Is BMC Unpingable
    Wait For Host To Ping  ${OPENBMC_HOST}  1 min

    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational
    Click Element  ${xpath_refresh_button}
    Wait Until Element Is Visible  ${xpath_reboot_bmc_button}  timeout=10


###  Power On Test Cases  ###

Verify Reboot BMC Page With Readonly User When Host On State
    [Documentation]  Verify Reboot BMC page with readonly user when Host On state.
    [Tags]  Verify_Reboot_BMC_Page_With_Readonly_User_When_Host_On_State
    [Setup]  Run Keywords  Power On Server  AND  Logout GUI  AND
    ...      Create Readonly User And Login To GUI  AND  Test Setup Execution
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    # Click on Rebbot BMC button.
    Click Element  ${xpath_reboot_bmc_button}

    # Delay added for confirm button to appear.
    Sleep  5s
    Click Element At Coordinates  ${xpath_confirm_button}  0  0
    Verify Error And Unauthorized Message On GUI


###  Power Off Test Cases  ###

Verify Reboot BMC Page With Readonly User When Host Off State
    [Documentation]  Verify Reboot BMC page with readonly user when Host Off state.
    [Tags]  Verify_Reboot_BMC_Page_With_Readonly_User_When_Host_Off_State
    [Setup]   Run Keywords  Power Off Server  AND  Logout GUI  AND
    ...       Create Readonly User And Login To GUI  AND  Test Setup Execution
    [Teardown]  Delete Readonly User And Logout Current GUI Session

    # Click on Rebbot BMC button.
    Click Element  ${xpath_reboot_bmc_button}

    # Delay added for confirm button to appear.
    Sleep  5s
    Click Element At Coordinates  ${xpath_confirm_button}  0  0
    Verify Error And Unauthorized Message On GUI


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_reboot_bmc_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  reboot-bmc
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
