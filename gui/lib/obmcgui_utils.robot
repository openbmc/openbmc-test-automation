*** Settings ***

Library  OperatingSystem
Library  Selenium2Library  120  120
Library  Screenshot

Resource  resource.txt

*** Keywords ***

Open Browser With URL
    [Documentation]  Open browser with specified URL and returns browser id.
    [Arguments]  ${URL}  ${browser}=gc
    # Description of argument(s):
    # URL      Openbmc GUI URL to be open
    #          (e.g. https://openbmc-test.mybluemix.net/#/login )
    # browser  browser used to open above URL
    #          (e.g. gc for google chrome, ff for firefox)
    ${browser_ID}=  Open Browser  ${URL}  ${browser}
    [Return]  browser_ID

Model Server Power Click
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${div_element}  ${anchor_element}
    # Description of argument(s):
    # div_element     Server power header divisional element
    #                 (e.g. header_wrapper)
    # anchor_element  Server power header anchor element
    #                 (e.g. header_wrapper_elt)
    Wait Until Element Is Visible
    ...  //*[@id='header__wrapper']/div/div[${div_element}]/a[${anchor_element}]/span
    Click Element
    ...  //*[@id='header__wrapper']/div/div[${div_element}]/a[${anchor_element}]/span

Controller Server Power Click
    [Documentation]  Click main server power in the header section.
    [Arguments]  ${controller_element}
    # Description of argument(s):
    # controller_element  Server power controller element
    #                     (e.g. power__power-on)

    Wait Until Element Is Visible  ${controller_element}
    Click Element  ${controller_element}

Controller Power Operations Confirmation Click
    [Documentation]  Click Common Power Operations Confirmation.
    [Arguments]  ${main_element}  ${sub_element}  ${confirm_msg_elt}  ${confirmation}
    # Description of argument(s):
    # main_element     Server power operations element
    #                  (e.g. power_operations)
    # sub_element      Server power operations sub element
    #                  (e.g. warm_boot, shut_down)
    # confirm_msg_elt  Server power operations confirm message element
    #                  (e.g. confirm_msg)
    # confirmation     Server power operations confirmation
    #                  (e.g. yes)

    Click Element
    ...  //*[@id='power-operations']/div[${main_element}]/div[${sub_element}]/confirm/div/div[${confirm_msg_elt}]/button[${confirmation}]

GUI Power On
    [Documentation]  Power on the CEC using GUI.

    Model Server Power Click  ${header_wrapper}  ${header_wrapper_elt}
    Page Should Contain  Attempts to power on the server
    Controller Server Power Click  power__power-on
    Page Should Contain  Running

OpenBMC GUI Login
    [Documentation]  Log into OpenBMC GUI.

    Register Keyword To Run On Failure  Reload Page
    Log  ${obmc_BMC_URL}
    Open Browser With URL  ${obmc_BMC_URL}  gc
    Page Should Contain Button  login__submit
    Wait Until Page Contains Element  ${obmc_uname}
    Input Text  ${obmc_bmc_ip}  ${OPENBMC_HOST}
    Input Text  ${obmc_uname}  ${obmc_user_name}
    Input Password  password  ${obmc_password}
    Click Element  login__submit
    Page Should Contain  Server information

