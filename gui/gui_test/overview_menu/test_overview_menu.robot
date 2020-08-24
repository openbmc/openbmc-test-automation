*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}  //h1[contains(text(), "Overview")]
${xpath_LED_button}           //*[@class='custom-control-label']

*** Test Cases ***


Verify Turn On server LED button
    [Documentation]  Verify server turn on led button. 
    [Tags]  Verify_Turn_On_server_LED_button 

    ${expected_LED_TEXT}=  Set Variable  On
    ${LED_TEXT}=  Get Text  ${xpath_LED_button}
 
    # If not equal led is in Off state, so togle and check if the label is On 
    Run Keyword If  '${expected_LED_TEXT}' != '${LED_TEXT}'  Toggle And Confirm Expected Led  ${expected_LED_TEXT}
 
 
*** comment ***


Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


*** Keywords ***

Toggle And Confirm Expected Led
    [Arguments]   ${LED_text_expected}

    Click Element  ${xpath_LED_button}
    Wait Until Keyword Succeeds  10 min  60 sec  Is ServerLed Text Expected  ${LED_text_expected} 


Is ServerLed Text Expected
    [Arguments]   ${expected_LED_text}

    ${Text_LED}=  Get Text  ${xpath_LED_button}
    ${matched}=  Run Keyword If  '${Text_LED}' == '${expected_LED_text}'
    ...    Set Variable  True
    ...  ELSE
    ...    Set Variable  False
 
    [return]  ${matched}

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

