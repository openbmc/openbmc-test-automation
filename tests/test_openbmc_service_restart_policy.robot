*** Settings ***
Documentation        This testsuites tests the autorestart policy for
...                  OpenBMC project

Resource             ../lib/resource.txt
Resource             ../lib/connection_client.robot
Resource             ../lib/openbmc_ffdc.robot

Suite Setup          Open Connection And Log In
Suite Teardown       Close All Connections
Test Teardown        Log FFDC

*** Test Cases ***
Test OpenBMC Services Autorestart Policy
    [Documentation]     This testcases is for checking all the openbmc services
    ...                 restart policy is set to active
    @{services}=    Create List     btbridged.service
    ...                             host-ipmid.service
    ...                             inarp.service
    ...                             network.service
    ...                             network-update-dns.service
    ...                             obmc-console.service
    ...                             obmc-mgr-system.service
    ...                             obmc-phosphor-chassisd.service
    ...                             obmc-phosphor-event.service
    ...                             obmc-phosphor-fand.service
    ...                             obmc-phosphor-flashd.service
    ...                             obmc-phosphor-policyd.service
    ...                             obmc-phosphor-sensord.service
    ...                             obmc-phosphor-sysd.service
    ...                             obmc-phosphor-user.service
    ...                             obmc-rest.service
    ...                             org.openbmc.examples.PythonService.service
    ...                             org.openbmc.examples.SDBusService.service
    ...                             org.openbmc.ObjectMapper.service
    ...                             rest-dbus.service
    ...                             settings.service
    : FOR    ${SERVICE}    IN    @{services}
    \    Check Service Autorestart    ${SERVICE}


Test Restart Policy for openbmc service
    [Documentation]     This testcase will kill the service and make sure it
    ...                 does restart after that

    ${MainPID}=   Execute Restart Policy Command
    ...   systemctl -p MainPID show obmc-rest.service| cut -d = -f2
    Should Not Be Equal     0   ${MainPID}

    Execute Restart Policy Command    kill -9 ${MainPID}
    Sleep   30s   reason=Wait for service to restart properly

    ${ActiveState}=   Execute Restart Policy Command
    ...   systemctl -p ActiveState show obmc-rest.service| cut -d = -f2
    Should Be Equal     active   ${ActiveState}

    ${MainPID}=   Execute Restart Policy Command
    ...  systemctl -p MainPID show obmc-rest.service| cut -d = -f2
    Should Not Be Equal     0   ${MainPID}


*** Keywords ***

Check Service Autorestart
    [arguments]    ${servicename}
    ${restart_policy}=
    ...  Execute Restart Policy Command
    ...  systemctl -p Restart show ${servicename} | cut -d = -f2
    Should Be Equal     always   ${restart_policy}
    ...  msg=restart policy is not always for ${servicename}


Execute Restart Policy Command
    [arguments]    ${command}
    ${stdout}   ${stderr} =   Execute Command   ${command}   return_stderr=True
    Should Be Empty    ${stderr}
    [Return]    ${stdout}
