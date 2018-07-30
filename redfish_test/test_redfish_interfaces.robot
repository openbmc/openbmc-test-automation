*** Settings ***
Documentation    Test Redfish interfaces supported.

Resource    ../lib/redfish_client.robot

** Test Cases **

Get Redfish Response Codes
    [Documentation]  REST "Get" response status test.
    [Tags]  Get_Redfish_Response_Codes
    [Template]  Execute Get And Check Response

    # Expect status      URL Path
    ${HTTP_OK}           Systems
    ${HTTP_OK}           Systems/motherboard
    ${HTTP_OK}           Chassis/system
    ${HTTP_OK}           Managers/openbmc/EthernetInterfaces/eth0
    ${HTTP_NOT_FOUND}    /i/dont/exist/

*** Keywords ***

Execute Get And Check Response
    [Documentation]  Execute "GET" request and expect status.
    [Arguments]  ${expected_response_code}  ${url_path}
    # Description of arguments:
    # expected_response_code   Expected REST status codes.
    # url_path                 URL path.

    ${resp} =  Redfish Get Request  ${url_path}  json=${0}
    Should Be Equal As Strings  ${resp.status_code}  ${expected_response_code}
