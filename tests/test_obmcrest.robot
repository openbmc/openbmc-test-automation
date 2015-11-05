*** Settings ***
Documentation		This suite will verifiy all OpenBMC rest interfaces
...					Details of valid interfaces can be found here...
...					https://github.com/openbmc/docs/blob/master/rest-api.md

Resource		../lib/rest_client.robot


*** Variables ***


*** Test Cases ***
Good connection for testing
	${content} =	Read Properties	/
	${c}= 		get from List 	${content} 	0
	Should Contain		"/org"	${c}


Get an object with no properties 
	${content} =	Read Properties	/org/openbmc/inventory
	Should Be Empty	${content}


Get a Property
	${resp} =	Read Attribute	/org/openbmc/inventory/system/chassis/motherboard/cpu0	is_fru
	Should Contain		1	${resp}	


Get a null Property
	${resp} =	Read Attribute	/org/openbmc/inventory	is_fru
	Should Contain		1	${resp}	


Enumeration object


List object


Invoke a method without properties


Invoke a method with properties


Issue a POST


Issue a PUT





*** Keywords ***
