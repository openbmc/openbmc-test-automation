*** Settings ***
Documentation     This testsuite is for testing inventory
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Library           ../lib/utilities.py
Library           String
Library           Collections

Variables         ../data/variables.py


Suite setup		setup the suite


*** Test Cases ***

minimal cpu inventory
	${count} = 	Get Total Present 	CPU
	Should Be True 	${count}>${0}

minimal dimm inventory
	${count} = 	Get Total Present 	DIMM
	Should Be True 	${count}>=${2}

minimal core inventory
	${count} = 	Get Total Present 	CORE
	Should Be True 	${count}>${0}

minimal memory buffer inventory
	${count} = 	Get Total Present 	MEMORY_BUFFER
	Should Be True 	${count}>${0}

minimal fan inventory
	${count} = 	Get Total Present 	FAN
	Should Be True 	${count}>${2}

minimal main planar inventory
	${count} = 	Get Total Present 	MAIN_PLANAR
	Should Be True 	${count}>${0}

minimal system inventory
	${count} = 	Get Total Present 	SYSTEM
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
	Power On Host

	@{ret} = 	Get Inventory List 	${OPENBMC_MODEL}
	Set Suite Variable 	@{sys_inv} 	@{ret}
	${resp} = 	Read Properties 	/org/openbmc/inventory/enumerate
	Set Suite Variable 	${SYSTEM_INFO}  	${resp}
	log Dictionary  	${resp}

Get Total Present
	[arguments] 	${type}

	${l} =    	Create List  	[]
	${list} = 	Get Inventory Fru Type List 	${OPENBMC_MODEL} 	${type}
	: FOR 	${element} 	IN  	@{list}
	\ 	Append To List 	 ${l}  	${SYSTEM_INFO['${element}']['present']}

	${sum} = 	Get Count 	${l} 	True
	[return] 	${sum}

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
