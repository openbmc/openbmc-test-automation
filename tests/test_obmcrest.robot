*** Settings ***
Documentation		This suite will verifiy all OpenBMC rest interfaces
...					Details of valid interfaces can be found here...
...					https://github.com/openbmc/docs/blob/master/rest-api.md

Resource		../lib/rest_client.robot


*** Variables ***


*** Test Cases ***
Good connection for testing
	${resp} =	Read Properties	/
	${jdata}=	To Json 	${resp.content}
	${c}= 		get from List 	${jdata} 	0
	Should Contain		"/org"	${c}	


Get an object with no properties 
	${resp} =	Read Properties	/org/openbmc/inventory
	Should Be Empty	${resp.content}


Get a Property
	${resp} =	Read attribute	/org/openbmc/inventory/system/chassis/motherboard/cpu0	is_fru
	Should Contain		1	${resp}	


Get a null Property
	${resp} =	Read attribute	/org/openbmc/inventory	is_fru
	Should Contain		1	${resp}	


Enumeration object


List object


Invoke a method without properties


Invoke a method with properties


Issue a POST


Issue a PUT





*** Keywords ***
Read Properties
	[arguments]	${uri}
	${resp} =	OpenBMC Get Request	${uri}
	[return]	${resp}

Read attribute
	[arguments]	${uri}	${attr}
	${resp} =	OpenBMC Get Request	${uri}/attr/${attr}
	[return]	${resp.content}