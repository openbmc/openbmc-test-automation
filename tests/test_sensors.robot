*** Settings ***
Documentation          This file demonstrates executing REST way and dbus-send 
...                    commands on a remote machine to test its sensors and 
...                    getting their output and the return code.
...
...                    Notice how connections are handled as part of the
...                    suite setup and teardown.
...                    This saves some time when executing several test cases.

Resource        ../lib/rest_client.robot
Library         SSHLibrary
Library         ../data/model.py
Library 	OperatingSystem

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections


*** Variables ***
${model} =    ${OPENBMC_MODEL}
${interface} =    org.openbmc.SensorValue.
${method} =    getValue
${dbuspart1cmd} =   dbus-send --system --print-reply=literal --dest=org.openbmc.Sensors

*** Test Cases ***
Dbusway Execute Set Sensor boot count
    ${obj} =  Set Variable  /org/openbmc/sensors/host/BootCount
    ${valuetoset} =   Set Variable    int32:${5}
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${prevaluetocompare}   ${postvaluetocompare} =   Split String   ${valuetoset}  :
    ${listtocompare} =   Catenate  ${prevaluetocompare}   ${postvaluetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    ${output} =    Remove String     ${output}  variant
    Log to Console   \n ${output}
    Should Be String   ${output}
    Should Contain  ${output}  ${listtocompare}

Dbusway Set Sensor Boot progress
    ${obj} =  Set Variable  /org/openbmc/sensors/host/BootProgress
    ${valuetoset} =   Set Variable    string:"FW Progress, Baseboard Init"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  34
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway Set Sensor Boot progress Longest string
    ${obj} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${valuetoset} =   Set Variable    string:"FW Progress, Docking station attachment"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  42
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway Bootprogress Sensor FW Hang Unspecified Error
    ${obj} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${valuetoset} =   Set Variable    string:"FW Hang, Unspecified"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  27
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway Bootprogress FW Hang State
    ${obj} =    Set Variable    /org/openbmc/sensors/host/BootProgress
    ${valuetoset} =   Set Variable    string:"POST Error, unknown"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  27
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway OperatingSystemStatus Sensor boot completed progress
    ${obj} =    Set Variable    /org/openbmc/sensors/host/OperatingSystemStatus
    ${valuetoset} =   Set Variable    string:"Boot completed (00)"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  27
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway OperatingSystemStatus Sensor progress
    ${obj} =    Set Variable    /org/openbmc/sensors/host/OperatingSystemStatus
    ${valuetoset} =   Set Variable    string:"PXE boot completed"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  26
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway OCC Active Sensor on Disabled
    ${obj} =    Set Variable    /org/openbmc/sensors/host/cpu0/OccStatus
    ${valuetoset} =   Set Variable    string:"Disabled"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  16
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}


Dbusway OCC Active Sensor on Enabled
    ${obj} =    Set Variable    /org/openbmc/sensors/host/cpu0/OccStatus
    ${valuetoset} =   Set Variable    string:"Enabled"
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  16
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}

Dbusway Powercap Set Value
    ${obj} =    Set Variable    /org/openbmc/sensors/host/cpu0/OccStatus
    ${valuetoset} =   Set Variable    int32:5
    ${method} =   Set Variable  setValue
    ${output} =   Dbus Send Set Command  ${obj}  ${method}   ${valuetoset}
    Log to Console   \n ${output}
    ${valuetocompare} =  Get Substring   ${valuetoset}  8  16
    Log to Console   \n   ${valuetocompare}
    ${method} =   Set Variable   getValue
    ${output} =   Dbus Send Get Command  ${obj}  ${method}
    Should Be String   ${output}
    Should Contain  ${output}  ${valuetocompare}


*** Keywords ***
Dbus Send Set Command
   [Arguments]   ${l_obj}  ${l_method}  ${l_valuetoset}
   Log to Console   \n ValuetoSet:
   Log to Console   \n ${l_valuetoset}
   ${dbuspart2cmd} =   Catenate  SEPARATOR=   ${interface}${l_method}
   ${dbuspart3cmd} =  Catenate  ${l_obj}  ${SPACE}  ${dbuspart2cmd}
   ${dbuspart4cmd} =  Catenate  ${dbuspart3cmd}  ${SPACE}${l_valuetoset}
   Log to Console   \n ${dbuspart1cmd}
   Log to Console   \n ${dbuspart4cmd}
   ${output} =    Execute Command    ${dbuspart1cmd} ${dbuspart4cmd}
   [return]   ${output}


Dbus Send Get Command
   [Arguments]   ${l_obj}   ${l_method}
   ${dbuspart2cmd} =   Catenate  SEPARATOR=   ${interface}${l_method}
   ${output} =    Execute Command    ${dbuspart1cmd} ${l_obj} ${dbuspart2cmd}
   ${output} =    Remove String     ${output}  variant
   [return]   ${output}

Open Connection And Log In
    Open connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}

