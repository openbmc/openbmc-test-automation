*** Settings ***
Resource         ../../lib/resource.txt
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/bmc_redfish_utils.py  WITH NAME  rfutils

#Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Redfish Login And Logout
    [Documentation]  Login to BMCweb and then logout.
    [Tags]  Redfish_Login_And_Logout

    redfish.Login

    ${resp}=  rfutils.get_attribute  /redfish/v1/Systems/motherboard  PowerState
    Log To Console  \n ${resp}


