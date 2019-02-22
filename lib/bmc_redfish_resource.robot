*** Settings ***
Documentation   BMC redfish resource keyword.

Resource        resource.robot
Resource        rest_response_code.robot
Library         bmc_redfish.py
...             ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
...             WITH NAME  redfish
Library         bmc_redfish_utils.py  WITH NAME  redfish_utils
Library         disable_warning_urllib.py

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


Check Redfish URL Exist
    [Documentation]  Verify given redfish URL exist.
    [Arguments]   ${redfish_url}

    # Description of argument(s):
    # redfish_url redfish url.

    ${resp} =  redfish.Get  ${redfish_url}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Not Be Empty  ${resp}
