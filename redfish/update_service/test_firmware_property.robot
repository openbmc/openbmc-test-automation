*** Settings ***
Documentation    Verify that firmware update properties.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Firmware Update ApplyTime Immediate
    [Documentation]  Verify supported apply time "Immediate" property.
    [Tags]  Verify_Firmware_Update_ApplyTime_Immediate

    # Example:
    # /xyz/openbmc_project/software/apply_time
    # {
    #   "data": {
    #       "RequestedApplyTime": "xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.Immediate"
    #   },
    #   "message": "200 OK",
    #   "status": "ok"
    # }

    ${payload}=  Create Dictionary  ApplyTime=Immediate
    Redfish.Patch  /redfish/v1/UpdateService  body=&{payload}

    # TODO: Move to redfish when avialable.
    ${apply_time}=  Read Attribute  /xyz/openbmc_project/software/apply_time  RequestedApplyTime
    Rprint Vars  apply_time  fmt=terse
    Should Be Equal   ${apply_time}  xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.Immediate


Verify Firmware Update ApplyTime OnReset
    [Documentation]  Verify supported apply time "OnReset" property.
    [Tags]  Verify_Firmware_Update_ApplyTime_OnReset

    # Example:
    # /xyz/openbmc_project/software/apply_time
    # {
    #   "data": {
    #       "RequestedApplyTime": "xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.OnReset"
    #   },
    #   "message": "200 OK",
    #   "status": "ok"
    # }

    ${payload}=  Create Dictionary  ApplyTime=OnReset
    Redfish.Patch  /redfish/v1/UpdateService  body=&{payload}

    # TODO: Move to redfish when avialable.
    ${apply_time}=  Read Attribute  /xyz/openbmc_project/software/apply_time  RequestedApplyTime
    Rprint Vars  apply_time  fmt=terse
    Should Be Equal   ${apply_time}  xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.OnReset


Verify Firmware Update ApplyTime Invalid
    [Documentation]  Verify supported apply time returns error on invalid value.
    [Tags]  Verify_Firmware_Update_ApplyTime_Invalid

    ${payload}=  Create Dictionary  ApplyTime=Invalid
    Redfish.Patch  /redfish/v1/UpdateService  body=&{payload}  valid_status_codes=[${HTTP_BAD_REQUEST}]
