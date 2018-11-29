*** Settings ***

Documentation  Utilities keywords for BMC redfish.

Resource      resource.txt
Resource      redfish_client.robot

*** Keywords ***

Boot Action
    [Documentation]  Host boot to power on,off or reboot.
    [Arguments]  ${boot_option}

    # Description of argument(s):
    # boot_option   On/GracefulShutdown/ForceOff

    ${args}=  Create Dictionary  ResetType=${boot_option}
    ${resp}=  Redfish Post Request  ${REDFISH_POWER_URI}  data=${args}



