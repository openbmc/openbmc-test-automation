*** Settings ***
Documentation    Verify that firmware update properties.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/gen_robot_valid.py

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Firmware Update ApplyTime Immediate
    [Documentation]  Verify supported apply time "Immediate" property.
    [Tags]  Verify_Firmware_Update_ApplyTime_Immediate

    # Example:
    # /redfish/v1/UpdateService
    # "HttpPushUriOptions": {
    #    "HttpPushUriApplyTime": {
    #        "ApplyTime": "Immediate"
    #    }
    # }

    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService
    ...  body={'HttpPushUriOptions' : {'HttpPushUriApplyTime' : {'ApplyTime' : 'Immediate'}}}

    ${http_push_uri_options}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}UpdateService  HttpPushUriOptions
    Rprint Vars  http_push_uri_options
    Valid Value  http_push_uri_options["HttpPushUriApplyTime"]["ApplyTime"]  ['Immediate']


Verify Firmware Update ApplyTime OnReset
    [Documentation]  Verify supported apply time "OnReset" property.
    [Tags]  Verify_Firmware_Update_ApplyTime_OnReset

    # Example:
    # /redfish/v1/UpdateService
    # "HttpPushUriOptions": {
    #    "HttpPushUriApplyTime": {
    #        "ApplyTime": "OnReset"
    #    }
    # }

    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService
    ...  body={'HttpPushUriOptions' : {'HttpPushUriApplyTime' : {'ApplyTime' : 'OnReset'}}}

    ${http_push_uri_options}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}UpdateService  HttpPushUriOptions
    Rprint Vars  http_push_uri_options
    Valid Value  http_push_uri_options["HttpPushUriApplyTime"]["ApplyTime"]  ['OnReset']


Verify Firmware Update ApplyTime Invalid
    [Documentation]  Verify supported apply time returns error on invalid value.
    [Tags]  Verify_Firmware_Update_ApplyTime_Invalid

    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService
    ...  body={'HttpPushUriOptions' : {'HttpPushUriApplyTime' : {'ApplyTime' : 'Invalid'}}}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]
