*** Settings ***
Documentation            To test Redfish firmware update access key is gets updated.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/bmc_redfish_utils.robot
Resource                 ../../lib/openbmc_ffdc.robot
Library                  ../../lib/gen_robot_valid.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail


*** Variables ***

&{status}  Health=OK  State=Enabled
&{fw_access_key_attr}  AuthorizationScope=Service  ExpirationDate=None  Id=UAK
...                    LicenseType=Production  MaxAuthorizedDevices=${0}
...                    Name=Firmware Update Access Key  Status=&{status}

*** Test Cases ***

Verify Redfish Firmware Update Access Key Attributes
    [Documentation]  Check the firmware update access key URI is acccessible and verify
    ...  firmware update access key attributes.
    [Tags]  Verify_Redfish_Firmware_Update_Access_Key_Attributes

    ${resp}=  Redfish.Get  /redfish/v1/LicenseService/Licenses/UAK  valid_status_codes=[${HTTP_OK}]
    ${resp}=  Evaluate  json.loads(r'''${resp.text}''')  json
    Verify Redfish Firmware Update Access Key Inventory  ${resp}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Redfish Power On  stack_mode=skip


Get Firmware Update Access Keys Attribute
    [Documentation]  Get all the keys of firmware update access key attribute.

    ${fw_attr_keys}=  Create List
    ${fw_attr_keys}=  Get Dictionary Keys  ${fw_access_key_attr}

    [Return]  ${fw_attr_keys}


Verify Redfish Firmware Update Access Key Inventory
    [Documentation]  Verify all the Redfish firmware update access key URI attribute.
    [Arguments]  ${attribute_resp}

    ${date}=  Get From Dictionary  ${attribute_resp}  ExpirationDate
    @{date}=  Split String  ${date}  T

    ${fw_attr_keys}=  Get Firmware Update Access Keys Attribute

    FOR  ${attr}  IN  @{fw_attr_keys}
      Run Keyword If  '${attr}' == 'ExpirationDate'
      ...  Run Keywords  Should Be Equal As Strings  ${FIRMWARE_KEY}  ${date}[0]  AND
      ...  Continue For Loop
      ${value}=  Get From Dictionary  ${attribute_resp}  ${attr}
      Should Be Equal  ${fw_access_key_attr['${attr}']}  ${value}
    END

