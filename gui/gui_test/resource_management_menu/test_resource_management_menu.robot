
*** Settings ***

Documentation  Test suite for Open BMC GUI "Resource Management" menu.

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

Test Tags      Resource_Management_Menu

*** Variables ***

${xpath_resource_management_menu}              //*[@data-test-id='nav-button-resource-management']
${xpath_resource_management_power_menu}        //*[@data-test-id='nav-item-power']
${xpath_resource_management_header}            //h1[contains(normalize-space(.), "Power")]
${xpath_power_tab_power_consumption}           //*[contains(normalize-space(.),'Current power consumption')]
${xpath_power_cap_setting}                     //*[contains(normalize-space(.),'Power cap setting')]
${xpath_power_cap_apply}                       //label[contains(normalize-space(.),'Apply power cap')]
${xpath_power_cap_checkbox}                    //*[@data-test-id='power-checkbox-togglePowerCapField']
${xpath_asset_tag_save_button}                 //button[normalize-space()="Save"]
${xpath_power_cap_value}                       //*[@data-test-id='power-input-powerCapValue']


*** Test Cases ***

Verify Navigate To Resource Management Page
    [Documentation]  Login to GUI and perform page navigation to
    ...  Resource Management page and verify it loads successfully.
    [Tags]  Verify_Navigate_To_Resource_Management_Page

    Page Should Contain Element  ${xpath_resource_management_header}


Verify Able To Set Power Cap Value
    [Documentation]  Verify that the power cap value can be set successfully.
    [Tags]  Verify_Able_To_Set_Power_Cap_Value

    Page Should Contain Element  ${xpath_power_tab_power_consumption}
    Page Should Contain Element  ${xpath_power_cap_setting}
    Page Should Contain Element  ${xpath_power_cap_apply}
    Page Should Contain Checkbox  ${xpath_power_cap_checkbox}
    Click Element  ${xpath_power_cap_checkbox}
    Input Text  ${xpath_power_cap_value}  100
    Page Should Contain Element  ${xpath_asset_tag_save_button}
    Click Element  ${xpath_asset_tag_save_button}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Perform suite setup operation.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_resource_management_menu}  ${xpath_resource_management_power_menu}  power
