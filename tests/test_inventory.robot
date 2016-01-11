*** Settings ***
Documentation     This testsuite is for testing inventory
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/resource.txt

Library           String

*** Test Cases ***
List Inventory
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/list
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    ${ret}=    Get Inventory Schema    ${MACHINE_TYPE}
    : FOR    ${ELEMENT}    IN    @{ret}
    \    Should Contain    ${jsondata["data"]}    ${ELEMENT}


Verify dimm vpd
	: FOR 	${INDEX} 	IN RANGE 	0 	4
	\	log 	${INDEX}
	\	${value} =	Read Attribute	/org/openbmc/inventory/system/chassis/motherboard/dimm${INDEX}	fru_type
	\	Should Be Equal	${value}	DIMM


Verify dimm vpd properties
	: FOR 	${INDEX} 	IN RANGE 	0 	4
	\	log 	${INDEX}
	\	${props} =	Read Properties	/org/openbmc/inventory/system/chassis/motherboard/dimm${INDEX}
	\	Should Be Valid Dimm Properties	${props}





*** Keywords ***
Should Be Valid Dimm Properties
	[arguments]	${props}
	${ret}=    Get Inventory Items Schema	DIMM
	: FOR    ${ELEMENT}    IN    @{ret}
	\    Should Contain    ${props}    ${ELEMENT}
