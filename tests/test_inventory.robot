*** Settings ***
Documentation     This testsuite is for testing inventory
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/resource.txt

*** Test Cases ***
List Inventory
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/list
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    ${ret}=    Get Inventory Schema    ${MACHINE_TYPE}
    : FOR    ${ELEMENT}    IN    @{ret}
    \    Should Contain    ${jsondata}    ${ELEMENT}


Verify dimm0 vpd
	${value} =	Read attribute	/org/openbmc/inventory/system/chassis/motherboard/dimm0	fru_type
	Should Be Equal	${value}	"DIMM"


Verify dimm1 vpd
	${value} =	Read attribute	/org/openbmc/inventory/system/chassis/motherboard/dimm1	fru_type
	Should Be Equal	${value}	"DIMM"

Verify dimm0 properties
	${props} =	Read Properties	/org/openbmc/inventory/system/chassis/motherboard/dimm0
	Should Be Valid Dimm Properties	${props}

Verify dimm1 properties
	${props} =	Read Properties	/org/openbmc/inventory/system/chassis/motherboard/dimm1
	Should Be Valid Dimm Properties	${props}



*** Keywords ***
Should Be Valid Dimm Properties
	[arguments]	${props}
	${ret}=    Get Inventory Schema	DIMM
	: FOR    ${ELEMENT}    IN    @{ret}
	\    Should Contain    ${props}    ${ELEMENT}


Read attribute
	[arguments]	${uri}	${attr}
	${resp} =	OpenBMC Get Request	${uri}/attr/${attr}
	[return]	${resp.content}


Read Properties
	[arguments]	${uri}
	${resp} =	OpenBMC Get Request	${uri}
	[return]	${resp.content}
