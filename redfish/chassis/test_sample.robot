*** Settings ***
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

*** Test Cases ***

Redfish Util Sample Test
    redfish.Login

    ${resp}=  redfish_utils.get_attribute  /redfish/v1/Systems/motherboard  PowerState
    Log To Console  \n ${resp}
    redfish.Logout


