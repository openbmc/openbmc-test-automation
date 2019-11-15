*** Settings ***

Documentation  Test OpenBMC GUI "Event Log" sub-menu of "Server health".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution

*** Variables ***

${xpath_delete_remote_server}  //*[@class="remote-logging-server"]/div/child::button[2]
${xpath_add_server}            //*[@class="remote-logging-server"]/div/child::button[1]
${xpath_remote_server_ip}      //input[@id="remoteServerIP"]
${xpath_remote_server_port}    //input[@id="remoteServerPort"]

*** Test Cases ***

Verify Existence Of All Buttons In Remote Logging Server Page
    [Documentation]  Verify existence of all buttons in remote logging server
    ...              page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Remote_Logging_Server_Page
    [Setup]  Setup For Remote Logging Server
    [Teardown]  Click Button  ${xpath_cancel_button}

    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Input Boxes In Remote Logging Server Page
    [Documentation]  Verify existence of all input boxes in remote logging server
    ...              page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Remote_Logging_Server_Page
    [Setup]  Setup For Remote Logging Server
    [Teardown]  Click Button  ${xpath_cancel_button}

    Page Should Contain Textfield  ${xpath_remote_server_ip}
    Page Should Contain Textfield  ${xpath_remote_server_port}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_server_health}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Wait Until Page Contains  Event Log

Delete Remote Logging Server
    [Documentation]  Delete remote logging server entry.

    Click Button  ${xpath_delete_remote_server}
    Click Button  ${xpath_remove_button}

Setup For Remote Logging Server
    [Documentation]  Test setup for remote logging server page

    Test Setup Execution
    # Ignore if deleting remote logging server fails
    Run Keyword And Return Status  Delete Remote Logging Server
    Run Keyword And Ignore Error  Delete Remote Logging Server
    Click Button  ${xpath_add_server}
    Page Should Contain  Add remote logging server



