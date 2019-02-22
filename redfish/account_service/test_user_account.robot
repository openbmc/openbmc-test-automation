*** Settings ***
Documentation    Test Redfish user account.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


** Test Cases **

Verify AccountService Available
    [Documentation]  Verify Redfish account service is available.
    [Tags]  Verify_AccountService_Available

    ${resp} =  redfish.Get  /redfish/v1/AccountService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Be Equal As Strings  ${resp.dict["ServiceEnabled"]}  ${True}


*** Keywords ***
