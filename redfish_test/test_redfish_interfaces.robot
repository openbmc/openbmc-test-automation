*** Settings ***
Documentation    Test Redfish interfaces supported.

Resource    ../lib/redfish_client.robot

** Test Cases **

Get Redfish Response Codes
    [Documentation]  Get Redfish response codes and validate them.
    [Tags]  Get_Redfish_Response_Codes
    [Template]  Execute Get And Check Response

    # Expected status    URL Path
    ${HTTP_OK}           Systems
    ${HTTP_OK}           Systems/motherboard
    ${HTTP_OK}           Chassis/system
    ${HTTP_OK}           Managers/openbmc/EthernetInterfaces/eth0
    ${HTTP_NOT_FOUND}    /i/dont/exist/

*** Keywords ***

Execute Get And Check Response
    [Documentation]  Execute "GET" request and check for expected status.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of argument(s):
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.

    ${resp} =  Redfish Get Request  ${url_path}  response_type=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}
