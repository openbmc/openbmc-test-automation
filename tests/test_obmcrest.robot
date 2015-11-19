*** Settings ***
Documentation		This suite will verifiy all OpenBMC rest interfaces
...					Details of valid interfaces can be found here...
...					https://github.com/openbmc/docs/blob/master/rest-api.md

Resource		../lib/rest_client.robot


*** Variables ***


*** Test Cases ***
Good connection for testing
    ${content}=    Read Properties     /
    ${c}=          get from List       ${content}      0
    Should Be Equal    ${c}     /org

Get an object with no properties 
    ${content}=    Read Properties     /org/openbmc/inventory
    Should Be Empty     ${content}

Get a Property
    ${resp}=   Read Attribute      /org/openbmc/inventory/system/chassis/motherboard/cpu0      is_fru
    Should Be Equal    ${resp}     ${1}

Get a null Property
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/attr/is_fru
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_NOT_FOUND}
    ${jsondata}=    To Json    ${resp.content}
    Should Be Equal     ${jsondata['data']['description']}      The specified property cannot be found: ''is_fru''
