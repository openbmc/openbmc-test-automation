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
    ...                 Disabling this test as use case is not well define and
    ...                 developement point of view this may keep changing. So
    ...                 untill then, this remains commented piece of test.
    [Tags]  Test_OpenBMC_Services_Autorestart_Policy
    @{services}=    Create List     btbridged.service
    ...                             host-ipmid.service
    ...                             inarp.service
    ...                             network.service
    ...                             network-update-dns.service
    ...                             obmc-console.service
    ...                             obmc-hwmon.service
    ...                             obmc-phosphor-chassisd.service
    ...                             obmc-phosphor-event.service
    ...                             obmc-phosphor-fand.service
    ...                             obmc-phosphor-flashd.service
    ...                             obmc-phosphor-policyd.service
    ...                             obmc-phosphor-sensord.service
    ...                             obmc-phosphor-sysd.service
    ...                             obmc-phosphor-user.service
    ...                             org.openbmc.buttons.Power.service
    ...                             org.openbmc.buttons.reset.service
    ...                             org.openbmc.control.BmcFlash.service
    ...                             org.openbmc.control.Bmc.service
    ...                             org.openbmc.control.Chassis.service
    ...                             org.openbmc.control.Checkstop.service
    ...                             org.openbmc.control.Fans.service
    ...                             org.openbmc.control.Flash.service
    ...                             org.openbmc.control.Host.service
    ...                             org.openbmc.control.led.service
    ...                             org.openbmc.control.Power.service
    ...                             org.openbmc.examples.PythonService.service
    ...                             org.openbmc.examples.SDBusService.service
    ...                             org.openbmc.Inventory.service
    ...                             org.openbmc.managers.Download.service
    ...                             org.openbmc.managers.System.service
    ...                             org.openbmc.ObjectMapper.service
    ...                             org.openbmc.Sensors.service
    ...                             org.openbmc.watchdog.Host.service
    ...                             phosphor-rest.service
    ...                             rest-dbus.service
    ...                             settings.service
    : FOR    ${SERVICE}    IN    @{services}
    \    Check Service Autorestart    ${SERVICE}


Test Restart Policy for openbmc service
    [Documentation]     This testcase will kill the service and make sure it
    ...                 does restart after that

    ${MainPID}=   Execute Restart Policy Command
    ...   systemctl -p MainPID show settings.service| cut -d = -f2
    Should Not Be Equal     0   ${MainPID}

    Execute Restart Policy Command    kill -9 ${MainPID}
    Sleep   30s   reason=Wait for service to restart properly

    ${ActiveState}=   Execute Restart Policy Command
    ...   systemctl -p ActiveState show settings.service| cut -d = -f2
    Should Be Equal     active   ${ActiveState}

    ${MainPID}=   Execute Restart Policy Command
    ...  systemctl -p MainPID show settings.service| cut -d = -f2
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
