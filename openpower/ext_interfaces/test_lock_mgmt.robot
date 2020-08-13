*** Settings ***

Documentation    Test Lock Management feature of Management Console on BMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource             ../../lib/external_intf/management_console_utils.robot

Suite Setup              Delete All Redfish Sessions
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

*** Variables ***

*** Test Cases ***

Acquire Read Lock
    [Documentation]  Acquire and release different read locks.
    [Tags]  Acquire_Read_Lock
    [Template]  Acquire Lock On Resource

    HMCID-01  Read  1

Acquire Read Lock On Read Lock
    [Documentation]  Acquire and release different read locks.
    [Tags]  Acquire_Read_Lock_On_Read_Lock
    [Template]  Acquire Lock On Another Lock

    HMCID-01  Read  2


*** Keywords ***

Create Redfish Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    Log  ${client_id}
    ${session_info}=  Create Dictionary
    ${session}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client_id}"}}
   
    Set To Dictionary  ${session_info}  SessionIDs  ${session['Id']}
    Set To Dictionary  ${session_info}  ClientID  ${session["Oem"]["OpenBMC"]["ClientID"]}


    [Return]  ${session_info}


RW General Dictionary
    [Documentation]  Acquire and release lock.
    [Arguments]  ${read_case}  ${res_id}

    # Description of argument(s):
    ${request_dict}=  Create Dictionary
    FOR  ${key}  IN  @{read_case.keys()}
      Set To Dictionary  ${request_dict}  LockType  ${key}
      Set To Dictionary  ${request_dict}  SegmentFlags  ${read_case["${key}"]}
    END
    Set To Dictionary  ${request_dict}  ResourceID  ${res_id}

    [Return]  ${request_dict}



Return Description Of Response
    [Documentation]  Return description of REST response.
    [Arguments]  ${resp_text}

    # Description of argument(s):
    # resp_text    REST response body.

    # resp_text after successful partition file upload looks like:
    # {
    #    "Description": "File Created"
    # }

    ${message}=  Evaluate  json.loads('''${resp_text}''')  json

    [Return]  ${message}


Redfish Post Acquire Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${data}

    # Description of argument(s):

    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${data} 
    ${resp}=  Return Description Of Response  ${resp.content}
    [Return]  ${resp}
    
Form Data To Acquire Lock
    [Documentation]  Acquire and release lock.

    ${lock_res_info}=  Get Lock Resource Information
    ${resp}=  RW General Dictionary
    ...    ${lock_res_info["Valid Case"]["ReadCase1"]}
    ...    ${lock_res_info["Valid Case"]["ResourceID"]}
    ${temp_list}=  Create List  ${resp}
    ${lock_request}=  Create Dictionary  Request=${temp_list}
    [Return]  ${lock_request}

Get Locks List On Resource
    [Documentation]  Get locks list.
    [Arguments]  ${session_info}  ${exp_status_code}=${HTTP_OK}

    Log  ${session_info['SessionIDs']}
    ${data}=  Set Variable  {"SessionIDs": ["${session_info['SessionIDs']}"]}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.GetLockList
    ...  data=${data}
    ${locks}=  Evaluate  json.loads('''${resp.text}''')  json
    
    [Return]  ${locks["Records"]}


Verify Lock On Resource
    [Documentation]  Acquire and release lock.
    [Arguments]  ${session_info}  ${transaction_id}

    # Description of argument(s):

    ${lock_list}=  Get Locks List On Resource  ${session_info}
    ${lock_length}=  Get Length  ${lock_list}
    ${tran_id_length}=  Get Length  ${transaction_id}
    Should Be Equal As Integers  ${tran_id_length}  ${lock_length}
    FOR  ${tran_id}  ${lock}  IN ZIP  ${transaction_id}  ${lock_list}
      Valid Value  session_info['ClientID']  ['${lock['HMCID']}']
      Valid Value  session_info['SessionIDs']  ['${lock['SessionID']}']
      Should Be Equal As Integers  ${tran_id['TransactionID']}  ${lock['TransactionID']}
    END


Acquire Lock On Resource
    [Documentation]  Acquire and release lock.
    [Arguments]  ${HH}  ${lock_type}  ${times}

    # Description of argument(s):

    ${trans_id_list}=  Create List
    ${session_info}=  Create Redfish Session With ClientID  ${HH}
    ${resp}=  Form Data To Acquire Lock
    ${trans_id}=  Redfish Post Acquire Lock  ${resp}
    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}
    
    Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}


Form Data To Release Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${trans_id_list}

    # Description of argument(s):

    @{tran_ids}=  Create List
    
    FOR  ${item}  IN  @{trans_id_list}
      Log  ${item}
      Append To List  ${tran_ids}  ${item['TransactionID']}
    END

    [Return]  ${tran_ids}


Release Locks On Resource
    [Documentation]  Acquire and release lock.
    [Arguments]  ${session_info}  ${trans_id_list}  ${release_lock_type}=Transaction  ${status_code}=${HTTP_OK}

    # Description of argument(s):

    ${tran_ids}=  Form Data To Release Lock  ${trans_id_list} 
    ${data}=  Set Variable  {"Type": "${release_lock_type}", "TransactionIDs":${tran_ids}}
    ${data}=  Evaluate  json.dumps(${data})  json
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.ReleaseLock  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code} 


Acquire Lock On Another Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${HH}  ${lock_type}  ${times}
    
    # Description of argument(s):
   
    ${trans_id_list}=  Create List 
    ${session_info}=  Create Redfish Session With ClientID  ${HH}
    ${resp}=  Form Data To Acquire Lock
    Log  ${resp}
    ${trans_id}=  Redfish Post Acquire Lock  ${resp}
    Log  ${trans_id}
    Append To List  ${trans_id_list}  ${trans_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${resp}
    Log  ${trans_id}
    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}
    Release Locks On Resource  ${session_info}  ${trans_id_list}
