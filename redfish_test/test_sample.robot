*** Settings ***
Resource    ../lib/resource.txt
Library     ../lib_redfish/bmcweb_client.py
...         ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

Suite Teardown   Logout Session

*** Variables ***

${POWER_ON}              On
${POWER_GRACEFULL_OFF}   GracefulShutdown
${POWER_FORCE_OFF}       ForceOff

${REDFISH_POWER_URI}     Systems/1/Actions/ComputerSystem.Reset

*** Test Cases ***

Test Power On
    [Documentation]  Host boot to power on, off.

    ${resp}=  Get Method  Systems/1
    Log To Console  \n ${resp}

    Boot Action  GracefulShutdown

*** Keywords ***

Boot Action
    [Documentation]  Host boot to power on, off or reboot.
    [Arguments]  ${boot_option}

    # Description of argument(s):
    # boot_option   Type of allowed boot
    #              (e.g. "On", "ForceOff", "GracefulShutdown", "GracefulRestart").

    ${resp}=  Post Method  ${REDFISH_POWER_URI}  ${boot_option}
    Log To Console  \n ${resp}
