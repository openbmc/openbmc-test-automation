*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource          ../lib/rest_client.robot


Library                SSHLibrary
Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections

*** Variables ***
${HOST}                9.3.164.147
${USERNAME}            root
${PASSWORD}            0penBmc

*** Test Cases ***
Execute Command And Verify Output
	[Documentation]    Execute Command on the remote machine.
	${output}=    Execute Command    echo Hello
	Should Be Equal    ${output}    Hello

Execute Sending a file
	put file    ./tfile /home/root

Execute ipmi BT capabilities command
	${output}=    Execute Command    /home/root/ipmitool -I dbus raw 0x06 0x36
	Should Be Equal    "${output}"    " 01 3f 3f 0a 01"

Execute Boot Sensoripmi BT capabilities command
	${output}=    Execute Command    /home/root/ipmitool -I dbus raw 0x06 0x36
	Should Be Equal    "${output}"    " 01 3f 3f 0a 01"

Execute Set Sensor boot count
	Run IPMI command  0x04 0x30 0x09 0x01 0x00 0x35 0x00 0x00 0x00 0x00 0x00 0x00
	${value} =  Read attribute	/org/openbmc/sensor/virtual/BootCount	value
	Should Be Equal ${value}    "53"



*** Keywords ***
Open Connection And Log In
   Open Connection    ${HOST}
   Login    ${USERNAME}    ${PASSWORD}

Run IPMI Command
	[arguments]     ${args}
	${output}=      Execute Command    /home/root/ipmitool -I dbus raw ${args}

Read attribute
	[arguments]	${uri}	${attr}
	${resp} =	OpenBMC Get Request	${uri}/attr/${attr}
	[return]	${resp.content}