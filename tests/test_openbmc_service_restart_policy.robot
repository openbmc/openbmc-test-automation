*** Settings ***
Documentation        This testsuites tests the autorestart policy for
...                  OpenBMC project

Resource             ../lib/resource.txt
Resource             ../lib/connection_client.robot

Suite Setup          Open Connection And Log In
Suite Teardown       Close All Connections
Test Teardown        Log FFDC

*** Test Cases ***
Test OpenBMC Services Autorestart Policy
    [Documentation]     This testcases is for checking all the openbmc services
    ...                 restart policy is set to active
    @{services}=    Create List     obmc-mapper.service
    ...                             obmc-rest.service
    ...                             btbridged.service
    ...                             host-ipmi-bt.service
    ...                             host-ipmi-hw-example.service
    ...                             host-ipmid.service
    ...                             obmc-phosphor-chassisd.service
    ...                             obmc-phosphor-event.service
    ...                             obmc-phosphor-example-pydbus.service
    ...                             obmc-phosphor-example-sdbus.service
    ...                             obmc-phosphor-fand.service
    ...                             obmc-phosphor-flashd.service
    ...                             obmc-phosphor-policyd.service
    ...                             obmc-phosphor-sensord.service
    ...                             obmc-phosphor-sysd.service
    ...                             rest-dbus.service
    ...                             skeleton.service
    : FOR    ${SERVICE}    IN    @{services}
    \    Check Service Autorestart    ${SERVICE}

Test Restart Policy for openbmc service
    [Documentation]     This testcase will kill the service and make sure it
    ...                 does restart after that
    ${MainPID}   ${stderr}   ${rc}=  Execute new Command    systemctl -p MainPID show skeleton.service| cut -d = -f2
    Should Not Be Equal     0   ${MainPID}
    ${stdout}   ${stderr}   ${rc}=  Execute new Command     kill -9 ${MainPID}
    Sleep   30s     Wait for service to restart properly
    ${ActiveState}   ${stderr}   ${rc}=  Execute new Command    systemctl -p ActiveState show skeleton.service| cut -d = -f2
    Should Be Equal     active   ${ActiveState}
    ${MainPID}   ${stderr}   ${rc}=  Execute new Command    systemctl -p MainPID show skeleton.service| cut -d = -f2
    Should Not Be Equal     0   ${MainPID}

*** Keywords ***
Check Service Autorestart
    [arguments]    ${servicename}
    ${restart_policy}   ${stderr}   ${rc}=  Execute new command     systemctl -p Restart show ${servicename} | cut -d = -f2
    Should Be Equal     always   ${restart_policy}   restart policy is npt always for ${servicename}

Execute new Command
    [arguments]    ${command}
    ${stdout}   ${stderr}   ${rc}=  Execute Command    ${command}    return_stderr=True     return_rc=True
    [Return]    ${stdout}   ${stderr}   ${rc}
