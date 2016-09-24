*** Settings ***
Documentation     This testsuite is for testing inventory
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot/boot_resource_master.robot
Library           ../lib/utilities.py
Library           String
Library           Collections
Test Teardown     Log FFDC

Variables         ../data/variables.py


Suite setup		setup the suite

Force Tags  chassisboot

*** Test Cases ***

minimal cpu inventory
	${count} = 	Get Total Present 	cpu
	Should Be True 	${count}>${0}

minimal dimm inventory
	${count} = 	Get Total Present 	dimm
	Should Be True 	${count}>=${2}

minimal core inventory
	${count} = 	Get Total Present 	core
	Should Be True 	${count}>${0}

minimal memory buffer inventory
	${count} = 	Get Total Present 	membuf
	Should Be True 	${count}>${0}

minimal fan inventory
	${count} = 	Get Total Present 	fan
	Should Be True 	${count}>${2}

minimal main planar inventory
	${count} = 	Get Total Present 	motherboard
	Should Be True 	${count}>${0}

minimal system inventory
	${count} = 	Get Total Present 	system
	Should Be True 	${count}>${0}

Verify CPU VPD Properties
	Verify Properties 	CPU

Verify DIMM VPD Properties
	Verify Properties 	DIMM

Verify Memory Buffer VPD Properties
	Verify Properties 	MEMORY_BUFFER

Verify Fan VPD Properties
	Verify Properties 	FAN

Verify System VPD Properties
	Verify Properties 	SYSTEM


*** Keywords ***


Setup The Suite
	BMC Power On

	@{ret} = 	Get Inventory List 	${OPENBMC_MODEL}
	Set Suite Variable 	@{sys_inv} 	@{ret}
	${resp} = 	Read Properties 	/org/openbmc/inventory/enumerate
	Set Suite Variable 	${SYSTEM_INFO}  	${resp}
	log Dictionary  	${resp}

Get Total Present
        [Arguments]    ${type}
        ${list} =    Get Dictionary Keys    ${SYSTEM_INFO}
        ${resp} =    Get Matches    ${list}    regexp=^.*[0-9a-z_].${type}[0-9]*$
        ${sum} =        Get Length    ${resp}
        [return]    ${sum}

Verify Properties
	[arguments] 	${type}

	${list} = 	Get VPD Inventory List 	${OPENBMC_MODEL} 	${type}
	: FOR 	${element} 	IN  	@{list}
	\ 	${d} = 	Get From Dictionary 	${SYSTEM_INFO} 	${element}
	\ 	Run Keyword If 	${d['present']} == True		Verify Present Properties 	${d} 	${type}

Verify Present Properties
	[arguments]	 ${d} 	${type}
	${keys} = 	Get Dictionary Keys 	${d}
	Log List 	${keys}
	Log List 	${INVENTORY_ITEMS['${type}']}
	Lists Should Be Equal  ${INVENTORY_ITEMS['${type}']} 	${keys}
