*** Settings ***

Library  OperatingSystem
Library  Selenium2Library  120  120
# Library  AngularJSLibrary
Library  Screenshot

Resource  resource.txt

*** Keywords ***

Open Browser With URL
    [Documentation]  Open browser with specified URL.
    [Arguments]  ${URL}  ${browser}
    # Description of argument(s):
    # URL  Openbmc GUI URL to be open
    # (e.g. https://openbmc-test.mybluemix.net/#/login )
    # browser  browser used to open above URL
    # (e.g. gc for google chrome, ff for firefox)
    ${browser_ID}=  Open Browser  ${URL}  ${browser}
    [Return]  browser_ID

Model Server Power Click
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${div_element}  ${anchor_element}
    # Description of argument(s):
    # div_element  Server power header divisional element
    # anchor_element  Server power header anchor element
    Wait Until Element Is Visible
    ...  //*[@id='header__wrapper']/div/div[${div_element}]/a[${anchor_element}]/span
    Click Element
    ...  //*[@id='header__wrapper']/div/div[${div_element}]/a[${anchor_element}]/span

Controller Server Power Click
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${controller_element}
    # Description of argument(s):
    # controller_element  Server power controller element
    # (e.g. obmc_warm_boot)  

    Wait Until Element Is Visible  ${controller_element}
    Click Element  ${controller_element}

Controller Power Operations Confirmation Click
    [Documentation]  Common Power Operations  .
    [Arguments]  ${main_element}  ${sub_element}  ${confirm_msg_elt}  ${confirmation}
    # Description of argument(s):
    # main_element  Server power operations element
    # (e.g. power_operations)  
    # sub_element  Server power operations sub element
    # (e.g. warm_boot, shut_down)  
    # confirm_msg_elt  Server power operations confirm message element
    # (e.g. confirm_msg)  
    # confirmation  Server power operations confirmation
    # (e.g. yes)  

    Click Element  
    ...  //*[@id='power-operations']/div[${main_element}]/div[${sub_element}]/confirm/div/div[${confirm_msg_elt}]/button[${confirmation}]

GUI Power On
    [Documentation]  Power on the CEC using GUI.

    Model Server Power Click  ${header_wrapper}  ${header_wrapper_elt} 
    Page Should Contain  Attempts to power on the server
    Controller Server Power Click  ${obmc_power_on}

OpenBMC GUI Login
    [Documentation]  Log into OpenBMC GUI.

    Log  ${obmc_BMC_URL}
    Log To Console  ${obmc_BMC_URL}
    Open Browser With URL  ${obmc_BMC_URL}  gc
    Page Should contain Button  ${obmc_login_button}
    Wait Until Page Contains Element  ${obmc_uname}
    Input Text  ${obmc_uname}  ${obmc_user_name}
    Input Password  ${obmc_passwordelt}  ${obmc_password}
    Click Element  ${obmc_login_button}
    Page Should Contain  System Overview

Model List Click
    [Documentation]  Main List Traversing.
    [Arguments]  ${main_list_element}
    # Description of argument(s):
    # main_list_element  obmcgui extreme left list element
    # (e.g. server_health)
    
    Wait Until Element Is Visible
    ...  //*[@id="nav__top-level"]/li[${main_list_element}]/button/span
    Click Element
    ...  //*[@id="nav__top-level"]/li[${main_list_element}]/button/span

View List Click
    [Documentation]  Sub List Traversing.
    [Arguments]  ${sub_list}  ${sub_list_item}
    # Description of argument(s):
    # sub_list  obmcgui sub list element from the main list
    # (e.g. unit_id of server_health)
    # sub_list_item  obmcgui sub list item from the sub list
    # (e.g. unit_id_control of unit_id)


    Wait Until Element Is Visible
    ...  //html/body/app-navigation/nav/ul[${sub_list}]/li[${sub_list_item}]/a
    Click Element
    ...  //html/body/app-navigation/nav/ul[${sub_list}]/li[${sub_list_item}]/a

Controller Unit_ID Manipulation
    [Documentation]  Controller manipulation.
    [Arguments]  ${object}  ${operation}
    # Description of argument(s):
    # object  object to manipulation
    # (e.g. unit_id_switch)
    # operation  toggle the unit_switch
    # (e.g. unit_id_toggle)

    Wait Until Element Is Visible
    ...  //*[@id="uid-switch"]/div[${object}]/div/div[${operation}]/label
    Click Element
    ...  //*[@id="uid-switch"]/div[${object}]/div/div[${operation}]/label

OpenBMC GUI Logoff
    [Documentation]  Log out from OpenBMC GUI.
    [Tags]  OpenBMC_GUI_Logoff

    Log  ${obmc_BMC_URL}
    Log To Console  ${obmc_BMC_URL}
    Click Element  ${obmc_logout}
    Close Browser

