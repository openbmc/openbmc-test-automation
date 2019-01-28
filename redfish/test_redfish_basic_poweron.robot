*** Settings ***

Documentation    Test power on and off.

Resource         ../lib/redfish_utility.robot

** Test Cases **

Redfish Power On Test
    [Documentation]  Power off and on.
    [Tags]  Redfish_Power_On_Test

    Boot Action  ${POWER_GRACEFULL_OFF}

*** Keywords ***
