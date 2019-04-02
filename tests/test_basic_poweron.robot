*** Settings ***
Documentation  Test power on for HW CI.

Resource        ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot

*** Test Cases ***

Test Redfish Function

    Redfish.Login
    ${resp}=  redfish_utils.enumerate_request  /redfish/v1
    Log To Console  \n ${resp}
    #redfish_utils.list_request  /redfish/v1
    Redfish.Logout
