*** Settings ***

Documentation           Test lock management feature of management console on BMC.

Resource                ../../lib/resource.robot
Resource                ../../lib/openbmc_ffdc.robot
Resource                ../../lib/bmc_redfish_utils.robot
Resource                ../../lib/external_intf/management_console_utils.robot
Resource                ../../lib/rest_response_code.robot
Library                 ../../lib/bmc_network_utils.py

Suite Setup              Run Keyword And Ignore Error  Delete All Redfish Sessions
Suite Teardown           Run Keyword And Ignore Error  Delete All Redfish Sessions
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

*** Variables ***

${BAD_REQUEST}           Bad Request
&{default_trans_id}      TransactionID=${1}

*** Test Cases ***

Acquire Read Write Lock
    [Documentation]  Acquire and release different read locks.
    [Tags]  Acquire_Read_Write_Lock
    [Template]  Acquire Lock On Resource

    # client_id    lock_type     reboot_flag
    HMCID-01       ReadCase1     False
    HMCID-01       ReadCase2     False
    HMCID-01       ReadCase3     False
    HMCID-01       WriteCase1    False
    HMCID-01       WriteCase2    False
    HMCID-01       WriteCase3    False


Verify Lock Is Not Persistent On BMC Reboot
    [Documentation]  Acquire lock and after reboot the locks are removed as no persistency
    ...  maintained.
    [Tags]  Verify_Lock_Is_Not_Persistent_On_BMC_Reboot
    [Template]  Acquire Lock On Resource

    # client_id    lock_type     reboot_flag
    HMCID-01       ReadCase1     True
    HMCID-01       ReadCase2     True
    HMCID-01       ReadCase3     True
    HMCID-01       WriteCase1    True
    HMCID-01       WriteCase2    True
    HMCID-01       WriteCase3    True


Check After Reboot Transaction ID Set To Default
    [Documentation]  After reboot, the transaction id starts with default i.e. 1,
    ...  if any lock is acquired.
    [Tags]  Check_After_Reboot_Transaction_ID_Set_To_Default
    [Template]  Verify Acquire And Release Lock In Loop

    # client_id    lock_type     reboot_flag
    HMCID-01       ReadCase1     True
    HMCID-01       WriteCase1    True


Acquire Read Lock On Read Lock
    [Documentation]  Acquire read lock on another read lock.
    [Tags]  Acquire_Read_Lock_On_Read_Lock
    [Template]  Acquire Lock On Another Lock

    # client_id
    HMCID-01


Fail To Acquire Lock On Another Lock
    [Documentation]  Fail to acquire another lock.
    [Tags]  Fail_To_Acquire_Lock_On_Another_Lock
    [Template]  Verify Acquire Lock Fails On Another Lock

    # client_id    lock_type
    HMCID-01       ReadCase7,WriteCase6
    HMCID-01       WriteCase6,WriteCase6
    HMCID-01       WriteCase6,ReadCase7


Acquire Lock After Reboot
    [Documentation]  Acquire and release read and write locks after reboot.
    [Tags]  Acquire_Lock_After_Reboot
    [Template]  Verify Acquire Lock After Reboot

    # client_id    lock_type
    HMCID-01       ReadCase1
    HMCID-01       ReadCase2
    HMCID-01       ReadCase3
    HMCID-01       WriteCase1
    HMCID-01       WriteCase2
    HMCID-01       WriteCase3


Acquire And Release Lock In Loop
    [Documentation]  Acquire and release read, write locks in loop.
    [Tags]  Acquire_And_Release_Lock_In_Loop
    [Template]  Verify Acquire And Release Lock In Loop

    # client_id    lock_type
    HMCID-01       ReadCase1
    HMCID-01       ReadCase2
    HMCID-01       ReadCase3
    HMCID-01       WriteCase1
    HMCID-01       WriteCase2
    HMCID-01       WriteCase3


Fail To Acquire Read And Write In Single Request
    [Documentation]  Fail to acquire read and write lock in single request.
    [Tags]  Fail_To_Acquire_Read_And_Write_In_Single_Request
    [Template]  Verify Fail To Acquire Read And Write In Single Request

    # client_id    lock_type
    HMCID-01       ReadCase1,WriteCase1
    HMCID-01       WriteCase1,ReadCase1


Acquire Multiple Lock Request At CEC Level
    [Documentation]  Acquire write lock on read lock under CEC level.
    [Tags]  Acquire_Multiple_Lock_Request_At_CEC_Level
    [Template]  Verify Acquire Multiple Lock Request At CEC Level

    # client_id    lock_type
    HMCID-01       ReadCase4,WriteCase4
    HMCID-01       WriteCase5,ReadCase5
    HMCID-01       ReadCase6,WriteCase6
    HMCID-01       WriteCase7,ReadCase7


Verify Release Of Valid Locks
    [Documentation]  Release all valid locks.
    [Tags]  Verify_Release_Of_Valid_Locks
    [Template]  Acquire And Release Multiple Locks

    # client_id    lock_type                        release_lock_type
    HMCID-01       ReadCase1,ReadCase1,ReadCase1    Transaction
    HMCID-02       ReadCase1,ReadCase1,ReadCase1    Session


Release Lock When Session Deleted
    [Documentation]  Release lock when session gets deleted.
    [Tags]  Release_Lock_When_Session_Deleted
    [Template]  Verify Release Lock When Session Deleted

    # client_id    lock_type
    HMCID-01       ReadCase1
    HMCID-01       WriteCase1


Fail To Release Lock With Invalid TransactionID
    [Documentation]  Fail to release lock with invalid transaction id.
    [Tags]  Fail_To_Release_Lock_With_Invalid_TransactionID
    [Template]  Verify Fail To Release Lock With Invalid TransactionID

    # client_id    lock_type     release_lock_type
    HMCID-01       ReadCase1     Transaction
    HMCID-01       WriteCase1    Transaction


Fail To Release Multiple Lock With Invalid TransactionID
    [Documentation]  Release in-valid lock result in fail.
    [Tags]  Fail_To_Release_Multiple_Lock_With_Invalid_TransactionID
    [Template]  Verify Fail To Release Multiple Lock With Invalid TransactionID

    # client_id    lock_type                        release_lock_type
    HMCID-01       ReadCase1,ReadCase1,ReadCase1    Transaction
    12345          ReadCase2,ReadCase2,ReadCase2    Transaction
    HMCID          ReadCase3,ReadCase3,ReadCase3    Transaction


Fail To Release Multiple Lock With Valid And Invalid TransactionID
    [Documentation]  Release multiple lock with valid and invalid transaction.
    [Tags]  Fail_To_Release_Multiple_Lock_With_Valid_And_Invalid_TransactionID
    [Template]  Verify Fail To Release Multiple Lock With Valid And Invalid TransactionID

    # client_id    lock_type              release_lock_type
    HMCID-01       ReadCase1,ReadCase1    Transaction


Fail To Release Lock With String As TransactionID Data Type
    [Documentation]  Fail to release lock with string as transaction id data type.
    [Tags]  Fail_To_Release_Lock_With_String_As_TransactionID_Data_Type
    [Template]  Verify Fail To Release Lock With TransactionID As String Type

    # client_id    lock_type     release_lock_type
    HMCID-01       ReadCase1     Transaction
    HMCID-01       WriteCase1    Transaction


Fail To Release Lock For Another Session
    [Documentation]  Failed to release locks from another session.
    [Tags]  Fail_To_Release_Lock_For_Another_Session
    [Template]  Verify Fail To Release Lock For Another Session

    # client_id          lock_type
    HMCID-01,HMCID-02    ReadCase1,ReadCase1


Test Invalid Resource ID Data Type Locking
    [Documentation]  Failed to acquire lock for invalid resource id data type.
    [Tags]  Test_Invalid_Resource_ID_Data_Type_Locking
    [Template]  Verify Fail To Acquire Lock For Invalid Resource ID Data Type

    # client_id    lock_type
    HMCID-01       ReadCase1
    HMCID-01       ReadCase2
    HMCID-01       ReadCase3
    HMCID-01       WriteCase1
    HMCID-01       WriteCase2
    HMCID-01       WriteCase3


Fail To Acquire Lock For Invalid Lock Type
    [Documentation]  Failed to acquire read, write lock for invalid lock data passed.
    [Tags]  Fail_To_Acquire_Lock_For_Invalid_Lock_Type
    [Template]  Verify Fail To Acquire Lock For Invalid Lock Data

    # client_id    lock_type      message
    HMCID-01       ReadCase1      ${BAD_REQUEST}
    HMCID-01       ReadCase2      ${BAD_REQUEST}
    HMCID-01       ReadCase3      ${BAD_REQUEST}
    HMCID-01       ReadCase4      ${BAD_REQUEST}
    HMCID-01       ReadCase5      ${BAD_REQUEST}
    HMCID-01       WriteCase1     ${BAD_REQUEST}
    HMCID-01       WriteCase2     ${BAD_REQUEST}
    HMCID-01       WriteCase3     ${BAD_REQUEST}
    HMCID-01       WriteCase4     ${BAD_REQUEST}
    HMCID-01       WriteCase5     ${BAD_REQUEST}


Fail To Acquire Lock For Invalid Lock Flag
    [Documentation]  Failed to acquire read write lock for invalid lock flag passed.
    [Tags]  Fail_To_Acquire_Lock_For_Invalid_Lock_Flag
    [Template]  Verify Fail To Acquire Lock For Invalid Lock Data

    # client_id    lock_type       message
    HMCID-01       ReadCase6       ${BAD_REQUEST}
    HMCID-01       ReadCase7       ${BAD_REQUEST}
    HMCID-01       ReadCase8       ${BAD_REQUEST}
    HMCID-01       ReadCase9       ${BAD_REQUEST}
    HMCID-01       ReadCase10      ${BAD_REQUEST}
    HMCID-01       ReadCase11      ${BAD_REQUEST}
    HMCID-01       WriteCase6      ${BAD_REQUEST}
    HMCID-01       WriteCase7      ${BAD_REQUEST}
    HMCID-01       WriteCase8      ${BAD_REQUEST}
    HMCID-01       WriteCase9      ${BAD_REQUEST}
    HMCID-01       WriteCase10     ${BAD_REQUEST}
    HMCID-01       WriteCase11     ${BAD_REQUEST}


Fail To Acquire Lock For Invalid Segment Flag
    [Documentation]  Failed to acquire read write lock for invalid segment flag passed.
    [Tags]  Fail_To_Acquire_Lock_For_Invalid_Segment_Flag
    [Template]  Verify Fail To Acquire Lock For Invalid Lock Data

    # client_id    lock_type       message
    HMCID-01       ReadCase12      ${BAD_REQUEST}
    HMCID-01       ReadCase13      ${BAD_REQUEST}
    HMCID-01       ReadCase14      ${BAD_REQUEST}
    HMCID-01       WriteCase12     ${BAD_REQUEST}
    HMCID-01       WriteCase13     ${BAD_REQUEST}
    HMCID-01       WriteCase14     ${BAD_REQUEST}


Fail To Acquire Lock For Invalid Segment Data Type Flag
    [Documentation]  Failed to acquire read write lock for invalid segment flag passed.
    [Tags]  Fail_To_Acquire_Lock_For_Invalid_Segment_Data_Type_Flag
    [Template]  Verify Fail To Acquire Lock For Invalid Lock Data

    # client_id    lock_type       message
    HMCID-01       ReadCase15      ${EMPTY}
    HMCID-01       ReadCase16      ${EMPTY}
    HMCID-01       ReadCase17      ${EMPTY}
    HMCID-01       ReadCase18      ${EMPTY}
    HMCID-01       WriteCase15     ${EMPTY}
    HMCID-01       WriteCase16     ${EMPTY}
    HMCID-01       WriteCase17     ${EMPTY}
    HMCID-01       WriteCase18     ${EMPTY}


Get Empty Lock Records For Session Where No Locks Acquired
    [Documentation]  If session does not acquire locks then get lock should return
    ...              empty lock records.
    [Tags]  Get_Empty_Lock_Records_For_Session_Where_No_Locks_Acquired
    [Template]  Verify No Locks Records For Session With No Acquired Lock

    # client_id
    HMCID-01


Get Lock Records Empty For Invalid Session
    [Documentation]  Record of lock list is empty for invalid session.
    [Tags]  Get_Lock_Records_Empty_For_Invalid_Session
    [Template]  Verify Empty Lock Records For Invalid Session

    # client_id
    HMCID-01


Get Lock Records For Multiple Session
    [Documentation]  Get lock records of multiple session.
    [Tags]  Get_Lock_Records_For_Multiple_Session
    [Template]  Verify Lock Records Of Multiple Session

    # client_ids         lock_type
    HMCID-01,HMCID-02    ReadCase1,ReadCase1


Get Lock Records For Multiple Invalid Session
    [Documentation]  Record of lock list is empty for list of invalid session.
    [Tags]  Get_Lock_Records_For_Multiple_Invalid_Session
    [Template]  Verify Lock Records For Multiple Invalid Session

    # client_id
    HMCID-01


Get Lock Records For Multiple Invalid And Valid Session
    [Documentation]  Get record of lock from invalid and valid session.
    [Tags]  Get_Lock_Records_For_Multiple_Invalid_And_Valid_Session
    [Template]  Verify Lock Records For Multiple Invalid And Valid Session

    # client_id          lock_type
    HMCID-01,HMCID-02    ReadCase1

*** Keywords ***

Create Redfish Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    ${session_info}=  Create Dictionary
    ${session}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client_id}"}}

    Set To Dictionary  ${session_info}  SessionIDs  ${session['Id']}
    Set To Dictionary  ${session_info}  ClientID  ${session["Oem"]["OpenBMC"]["ClientID"]}

    [Return]  ${session_info}


RW General Dictionary
    [Documentation]  Create dictionary of lock request.
    [Arguments]  ${read_case}  ${res_id}

    # Description of argument(s):
    # read_case    Read or Write lock type.
    # res_id       Resource id.

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


Verify Redfish Session Deleted
    [Documentation]  Verify the redfish session is deleted.
    [Arguments]  ${session_info}

    # Description of argument(s):
    # session_info    Session information are stored in dictionary.

    # ${session_info} = {
    #     'SessionIDs': 'XXXXXXXXX',
    #     'ClientID': 'XXXXXX',
    #     'SessionToken': 'XXXXXXXXX',
    #     'SessionResp': session response from redfish login
    # }

    # SessionIDs   : Session IDs
    # ClientID     : Client ID
    # SessionToken : Session token
    # SessionResp  : Response of creating an redfish login session

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions

    FOR  ${session}  IN  @{sessions['Members']}
      Should Not Be Equal As Strings
      ...  session  ['/redfish/v1/SessionService/Sessions/${session_info["SessionIDs"]}']
    END


Verify Redfish List Of Session Deleted
    [Documentation]  Verify all the list of redfish session is deleted.
    [Arguments]  ${session_info_list}

    # Description of argument(s):
    # session_info_list    List contains individual session record are stored in dictionary.

    # ${session_info_list} = [{
    #     'SessionIDs': 'XXXXXXXXX',
    #     'ClientID': 'XXXXXX',
    #     'SessionToken': 'XXXXXXXXX',
    #     'SessionResp': session response from redfish login
    # }]

    # SessionIDs   : Session IDs
    # ClientID     : Client ID
    # SessionToken : Session token
    # SessionResp  : Response of creating an redfish login session

    FOR  ${session_record}  IN  @{session_info_list}
      Verify Redfish Session Deleted  ${session_record}
    END


Redfish Post Acquire Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${lock_type}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # status_code    HTTP status code.

    ${lock_dict_param}=  Form Data To Acquire Lock  ${lock_type}
    ${resp}=  Redfish Post Request
    ...  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}

    Run Keyword If  ${status_code} == ${HTTP_BAD_REQUEST}
    ...    Valid Value  ${BAD_REQUEST}  ['${resp.content}']
    ...  ELSE
    ...    Run Keyword And Return  Return Description Of Response  ${resp.content}

    [Return]  ${resp}


Redfish Post Acquire List Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${lock_type}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # status_code    HTTP status code.

    ${lock_dict_param}=  Create Data To Acquire List Of Lock  ${lock_type}
    ${resp}=  Redfish Post Request
    ...  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}

    [Return]  ${resp}


Redfish Post Acquire Invalid Lock
    [Documentation]  Redfish to post request to acquire in-valid lock.
    [Arguments]  ${lock_type}  ${message}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # message        Return message from URI.
    # status_code    HTTP status code.

    ${lock_dict_param}=  Form Data To Acquire Invalid Lock  ${lock_type}
    ${resp}=  Redfish Post Request
    ...  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}
    Run Keyword If  '${message}' != '${EMPTY}'
    ...  Valid Value  message  ['${resp.content}']

    [Return]  ${resp}


Redfish Post Acquire Invalid Lock With Invalid Data Type Of Resource ID
    [Documentation]  Redfish to post request to acquire in-valid lock with invalid data type of resource id.
    [Arguments]  ${lock_type}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # status_code    HTTP status code.

    ${lock_dict_param}=
    ...  Form Data To Acquire Invalid Lock With Invalid Data Type Of Resource ID  ${lock_type}
    ${resp}=  Redfish Post Request
    ...  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}

    [Return]  ${resp}


Form Data To Acquire Lock
    [Documentation]  Create a dictionary for lock request.
    [Arguments]  ${lock_type}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.

    ${lock_res_info}=  Get Lock Resource Information
    ${resp}=  RW General Dictionary
    ...    ${lock_res_info["Valid Case"]["${lock_type}"]}
    ...    ${lock_res_info["Valid Case"]["ResourceID"]}
    ${temp_list}=  Create List  ${resp}
    ${lock_request_dict}=  Create Dictionary  Request=${temp_list}

    [Return]  ${lock_request_dict}


Create Data To Acquire List Of Lock
    [Documentation]  Create a dictionary for list of lock request.
    [Arguments]  ${lock_type_list}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.

    ${temp_list}=  Create List
    ${lock_res_info}=  Get Lock Resource Information

    FOR  ${lock_type}  IN  @{lock_type_list}
      ${resp}=  RW General Dictionary
      ...    ${lock_res_info["Valid Case"]["${lock_type}"]}
      ...    ${lock_res_info["Valid Case"]["ResourceID"]}
      Append To List  ${temp_list}  ${resp}
    END

    ${lock_request_dict}=  Create Dictionary  Request=${temp_list}

    [Return]  ${lock_request_dict}


Form Data To Acquire Invalid Lock With Invalid Data Type Of Resource ID
    [Documentation]  Create a dictionary for in-valid lock request.
    [Arguments]  ${lock_type}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.

    ${lock_res_info}=  Get Lock Resource Information
    ${resp}=  RW General Dictionary
    ...    ${lock_res_info["Valid Case"]["${lock_type}"]}
    ...    ${lock_res_info["Invalid Case"]["ResourceIDInvalidDataType"]}
    ${temp_list}=  Create List  ${resp}
    ${lock_request_dict}=  Create Dictionary  Request=${temp_list}

    [Return]  ${lock_request_dict}


Form Data To Acquire Invalid Lock
    [Documentation]  Create a dictionary for in-valid lock request.
    [Arguments]  ${lock_type}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.

    ${lock_res_info}=  Get Lock Resource Information
    ${resp}=  RW General Dictionary
    ...    ${lock_res_info["Invalid Case"]["${lock_type}"]}
    ...    ${lock_res_info["Valid Case"]["ResourceID"]}
    ${temp_list}=  Create List  ${resp}
    ${lock_request_dict}=  Create Dictionary  Request=${temp_list}

    [Return]  ${lock_request_dict}


Get Locks List On Resource
    [Documentation]  Get locks list.
    [Arguments]  ${session_info}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # session_info       Session information in dict.
    # exp_status_code    Expected HTTP status code.

    ${data}=  Set Variable  {"SessionIDs": ["${session_info['SessionIDs']}"]}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.GetLockList
    ...  data=${data}
    ${locks}=  Evaluate  json.loads('''${resp.text}''')  json

    [Return]  ${locks["Records"]}


Verify Lock On Resource
    [Documentation]  Verify lock on resource.
    [Arguments]  ${session_info}  ${transaction_id}

    # Description of argument(s):
    # session_info      Session information in dict.
    # transaction_id    Transaction id in list stored in dict.

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_info['SessionIDs']}
    Rprint Vars  sessions
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
    [Documentation]  Acquire lock on resource.
    [Arguments]  ${client_id}  ${lock_type}  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    ${trans_id_emptylist}=  Create List
    ${trans_id_list}=  Create List

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
    Append To List  ${trans_id_list}  ${trans_id}

    Verify Lock On Resource  ${session_info}  ${trans_id_list}

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}

    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Run Keywords  Redfish BMC Reset Operation  AND
    ...  Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}  AND
    ...  Is BMC Standby  AND
    ...  Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}

    Run Keyword If  '${reboot_flag}' == 'False'
    ...  Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Form Data To Release Lock
    [Documentation]  Create a dictonay to release lock.
    [Arguments]  ${trans_id_list}

    # Description of argument(s):
    # trans_id_list

    @{tran_ids}=  Create List

    FOR  ${item}  IN  @{trans_id_list}
      Append To List  ${tran_ids}  ${item['TransactionID']}
    END

    [Return]  ${tran_ids}


Release Locks On Resource
    [Documentation]  Redfish request to release a lock.
    [Arguments]  ${session_info}  ${trans_id_list}  ${release_lock_type}=Transaction
    ...  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # session_info        Session information in dict.
    # trans_id_list       Transaction id list.
    # release_lock_type   Release lock by Transaction, Session.
    # status_code         HTTP status code.

    ${tran_ids}=  Form Data To Release Lock  ${trans_id_list}
    ${data}=  Set Variable  {"Type": "${release_lock_type}", "TransactionIDs":${tran_ids}}
    ${data}=  Evaluate  json.dumps(${data})  json
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.ReleaseLock  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}


Release locks And Delete Session
    [Documentation]  Release locks and delete redfish session.
    [Arguments]  ${session_info}  ${trans_id_list}

    Release Locks On Resource  ${session_info}  ${trans_id_list}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}

    Redfish Delete Session  ${session_info}


Acquire Lock On Another Lock
    [Documentation]  Acquire lock on another lock.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    ${trans_id_list}=  Create List
    ${session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ReadCase1
    Append To List  ${trans_id_list}  ${trans_id}

    ${trans_id}=  Redfish Post Acquire Lock  ReadCase1
    Append To List  ${trans_id_list}  ${trans_id}

    Verify Lock On Resource  ${session_info}  ${trans_id_list}

    Release locks And Delete Session  ${session_info}  ${trans_id_list}


Verify Fail To Acquire Read And Write In Single Request
    [Documentation]  Verify fail to acquire read and write lock passed in single request.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    ${lock_type_list}=  Split String  ${lock_type}  ,

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire List Lock  ${lock_type_list}  status_code=${HTTP_BAD_REQUEST}
    Redfish Delete Session  ${session_info}


Verify Empty Lock Records For Invalid Session
    [Documentation]  Verify no lock record found for invalid session.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    ${session_info1}=  Create Redfish Session With ClientID  ${client_id}

    ${lock_list1}=  Get Locks List On Resource  ${session_info1}
    ${lock_length1}=  Get Length  ${lock_list1}

    ${session_info2}=  Copy Dictionary  ${session_info1}  deepcopy=True
    set to dictionary  ${session_info2}  SessionIDs  xxyXyyYZZz

    ${lock_list2}=  Get Locks List On Resource  ${session_info2}
    ${lock_length2}=  Get Length  ${lock_list2}

    Should Be Equal As Integers  ${lock_length1}  ${lock_length2}

    Redfish Delete Session  ${session_info1}


Verify Acquire Lock Fails On Another Lock
    [Documentation]  Verify acquire lock on another lock fails.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    @{lock_type_list}=  Split String  ${lock_type}  ,
    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]

    ${trans_id_list}=  Create List
    Append To List  ${trans_id_list}  ${trans_id}

    Verify Lock On Resource  ${session_info}  ${trans_id_list}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[1]  status_code=${HTTP_CONFLICT}

    Release locks And Delete Session  ${session_info}  ${trans_id_list}


Verify Acquire Lock After Reboot
    [Documentation]  Acquire read and write lock after the reboot and release lock.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    ${trans_id_list}=  Create List
    ${session_info}=  Create Session With ClientID  ${client_id}

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}
    Redfish BMC Reset Operation
    Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}
    Is BMC Standby

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}

    Release locks And Delete Session  ${session_info}  ${trans_id_list}


Verify Acquire Multiple Lock Request At CEC Level
    [Documentation]  Acquire lock in loop.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    ${trans_id_list}=  Create List
    @{lock_type_list}=  Split String  ${lock_type}  ,
    ${session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    Append To List  ${trans_id_list}  ${trans_id}

    Verify Lock On Resource  ${session_info}  ${trans_id_list}

    Redfish Post Acquire Lock  ${lock_type_list}[1]  status_code=${HTTP_CONFLICT}

    Release locks And Delete Session  ${session_info}  ${trans_id_list}


Post Reboot Acquire Lock
    [Documentation]  Post reboot acquire lock and verify the transaction id is 1.
    [Arguments]  ${session_info}  ${lock_type}

    # Description of argument(s):
    # session_info     Session information.
    # lock_type        Read lock or Write lock.

    ${trans_id_list}=  Create List
    ${trans_id_list_var}=  Create List
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
    Append To List  ${trans_id_list}  ${trans_id}
    Append To List  ${trans_id_list_var}  ${default_trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}
    Verify Lock On Resource  ${session_info}  ${trans_id_list_var}
    Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}
    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}


Verify Acquire And Release Lock In Loop
    [Documentation]  Acquire lock in loop.
    [Arguments]  ${client_id}  ${lock_type}  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    FOR  ${count}  IN RANGE  1  11
      ${trans_id_list}=  Create List
      ${session_info}=  Create Redfish Session With ClientID  ${client_id}
      ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
      Append To List  ${trans_id_list}  ${trans_id}
      Verify Lock On Resource  ${session_info}  ${trans_id_list}
      Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}
      ${trans_id_emptylist}=  Create List
      Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
      Redfish Delete Session  ${session_info}
    END

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}

    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Run Keywords  Redfish BMC Reset Operation  AND
    ...  Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}  AND
    ...  Is BMC Standby  AND
    ...  Post Reboot Acquire Lock  ${session_info}  ${lock_type}
    Redfish Delete Session  ${session_info}


Acquire And Release Multiple Locks
    [Documentation]  Acquire mutilple locks on resource.
    [Arguments]  ${client_id}  ${lock_type}  ${release_lock_type}

    # Description of argument(s):
    # client_id          This client id can contain string value
    #                    (e.g. 12345, "HMCID").
    # lock_type          Read lock or Write lock.
    # release_lock_type  The value can be Transaction or Session.

    @{lock_type_list}=  Split String  ${lock_type}  ,
    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]

    ${trans_id_list}=  Create List

    Append To List  ${trans_id_list}  ${trans_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[1]

    Append To List  ${trans_id_list}  ${trans_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[2]

    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}
    Release Locks On Resource  ${session_info}  ${trans_id_list}  release_lock_type=${release_lock_type}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Verify Release Lock When Session Deleted
    [Documentation]  Verify lock get released when session are deleted.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_ids    This client id can contain string value
    #               (e.g. 12345, "HMCID").
    # lock_type     Read lock or Write lock.

    ${trans_id_list}=  Create List
    @{lock_type_list}=  Split String  ${lock_type}  ,

    ${pre_session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${pre_session_info}  ${trans_id_list}

    Redfish Delete Session  ${pre_session_info}
    ${post_session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${resp}=  Get Locks List On Resource With Session List  ${pre_session_info}  ${HTTP_BAD_REQUEST}

    Redfish Delete Session  ${post_session_info}



Verify Fail To Release Lock With Invalid TransactionID
    [Documentation]  Verify fail to be release lock with invalid transaction ID.
    [Arguments]  ${client_id}  ${lock_type}  ${release_lock_type}

    # Description of argument(s):
    # client_id          This client id can contain string value
    #                    (e.g. 12345, "HMCID").
    # lock_type          Read lock or Write lock.
    # release_lock_type  The value can be Transaction or Session.

    ${trans_id_list}=  Create List
    @{lock_type_list}=  Split String  ${lock_type}  ,

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    ${value}=  Get From Dictionary  ${trans_id}  TransactionID
    ${value}=  Evaluate  ${value} + 10
    Set To Dictionary  ${trans_id}  TransactionID  ${value}
    Append To List  ${trans_id_list}  ${trans_id}

    Release Locks On Resource
    ...  ${session_info}  ${trans_id_list}
    ...  release_lock_type=${release_lock_type}  status_code=${HTTP_BAD_REQUEST}
    Release Locks On Resource  ${session_info}  ${trans_id_list}  release_lock_type=Session

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Verify Fail To Release Multiple Lock With Invalid TransactionID
    [Documentation]  Verify release multiple locks with invalid transaction ID fails.
    [Arguments]  ${client_id}  ${lock_type}  ${release_lock_type}

    # Description of argument(s):
    # client_id          This client id can contain string value
    #                    (e.g. 12345, "HMCID").
    # lock_type          Read lock or Write lock.
    # release_lock_type  The value can be Transaction or Session.

    ${trans_id_list}=  Create List
    @{lock_type_list}=  Split String  ${lock_type}  ,

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    ${value}=  Get From Dictionary  ${trans_id}  TransactionID
    ${value}=  Evaluate  ${value} + 10
    Set To Dictionary  ${trans_id}  TransactionID  ${value}
    Append To List  ${trans_id_list}  ${trans_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[1]
    ${value}=  Get From Dictionary  ${trans_id}  TransactionID
    ${value}=  Evaluate  ${value} + 10
    Set To Dictionary  ${trans_id}  TransactionID  ${value}
    Append To List  ${trans_id_list}  ${trans_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[2]
    ${value}=  Get From Dictionary  ${trans_id}  TransactionID
    ${value}=  Evaluate  ${value} + 10
    Set To Dictionary  ${trans_id}  TransactionID  ${value}
    Append To List  ${trans_id_list}  ${trans_id}

    Release Locks On Resource
    ...  ${session_info}  ${trans_id_list}
    ...  release_lock_type=${release_lock_type}  status_code=${HTTP_BAD_REQUEST}
    Release Locks On Resource  ${session_info}  ${trans_id_list}  release_lock_type=Session

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Verify Fail To Release Multiple Lock With Valid And Invalid TransactionID
    [Documentation]  Verify fail to be release multiple lock with valid and invalid transaction ID.
    [Arguments]  ${client_id}  ${lock_type}  ${release_lock_type}

    # Description of argument(s):
    # client_id          This client id can contain string value
    #                    (e.g. 12345, "HMCID").
    # lock_type          Read lock or Write lock.
    # release_lock_type  The value can be Transaction or Session.

    ${trans_id_list}=  Create List
    @{lock_type_list}=  Split String  ${lock_type}  ,

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    Append To List  ${trans_id_list}  ${trans_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[1]
    ${value}=  Get From Dictionary  ${trans_id}  TransactionID
    ${value}=  Evaluate  ${value} + 10
    Set To Dictionary  ${trans_id}  TransactionID  ${value}
    Append To List  ${trans_id_list}  ${trans_id}

    Release Locks On Resource
    ...  ${session_info}  ${trans_id_list}
    ...  release_lock_type=${release_lock_type}  status_code=${HTTP_BAD_REQUEST}
    Release Locks On Resource  ${session_info}  ${trans_id_list}  release_lock_type=Session

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Verify Fail To Release Lock With TransactionID As String Type
    [Documentation]  Verify fail to be release lock with transaction ID as string data type.
    [Arguments]  ${client_id}  ${lock_type}  ${release_lock_type}

    # Description of argument(s):
    # client_id          This client id can contain string value
    #                    (e.g. 12345, "HMCID").
    # lock_type          Read lock or Write lock.
    # release_lock_type  The value can be Transaction or Session.

    ${trans_id_list}=  Create List
    @{lock_type_list}=  Split String  ${lock_type}  ,

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]

    Append To List  ${trans_id_list}  ${trans_id}

    ${temp_trans_id_list}=  Copy Dictionary  ${trans_id_list}  deepcopy=True

    ${value}=  Get From Dictionary  ${trans_id_list}[0]  TransactionID
    ${value}=  Set Variable  \'${value}\'
    Set To Dictionary  ${temp_trans_id_list}[0]  TransactionID  ${value}

    Release Locks On Resource
    ...  ${session_info}  ${temp_trans_id_list}
    ...  release_lock_type=${release_lock_type}  status_code=${HTTP_BAD_REQUEST}

    Release Locks On Resource  ${session_info}  ${trans_id_list}  release_lock_type=${release_lock_type}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Verify Fail To Release Lock For Another Session
    [Documentation]  Verify failed to release the lock form another session.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    ${client_ids}=  Split String  ${client_id}  ,
    ${lock_type_list}=  Split String  ${lock_type}  ,
    ${trans_id_list1}=  Create List
    ${trans_id_list2}=  Create List

    ${session_info1}=  Create Redfish Session With ClientID  ${client_ids}[0]

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    Append To List  ${trans_id_list1}  ${trans_id}
    Verify Lock On Resource  ${session_info1}  ${trans_id_list1}

    ${session_info2}=  Create Redfish Session With ClientID  ${client_ids}[1]
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[1]
    Append To List  ${trans_id_list2}  ${trans_id}
    Verify Lock On Resource  ${session_info2}  ${trans_id_list2}

    Release Locks On Resource
    ...  ${session_info1}  ${trans_id_list1}  Transaction  status_code=${HTTP_UNAUTHORIZED}
    Verify Lock On Resource  ${session_info1}  ${trans_id_list1}
    Release Locks On Resource  ${session_info1}  ${trans_id_list1}  release_lock_type=Session
    Release Locks On Resource  ${session_info2}  ${trans_id_list2}  release_lock_type=Session
    Redfish Delete Session  ${session_info1}
    Redfish Delete Session  ${session_info2}


Verify Fail To Acquire Lock For Invalid Resource ID Data Type
    [Documentation]  Verify fail to acquire the lock with invalid resource id data type.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    Redfish Post Acquire Invalid Lock With Invalid Data Type Of Resource ID
    ...  ${lock_type}  status_code=${HTTP_BAD_REQUEST}
    Redfish Delete Session  ${session_info}


Verify Fail To Acquire Lock For Invalid Lock Data
    [Documentation]  Verify fail to acquired lock with invalid lock types, lock flags, segment flags.
    [Arguments]  ${client_id}  ${lock_type}  ${message}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.
    # message      Return message from URI.

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire Invalid Lock
    ...  ${lock_type}  message=${message}  status_code=${HTTP_BAD_REQUEST}
    Redfish Delete Session  ${session_info}


Verify No Locks Records For Session With No Acquired Lock
    [Documentation]  Verify no records found for a session where no lock is acquired.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Create List Of Session ID
    [Documentation]  Create session id list from session dict info.
    [Arguments]  ${session_dict_info}

    # Description of argument(s):
    # session_dict_info      Session information in dict.

    @{session_id_list}=  Create List

    FOR  ${session}  IN  @{session_dict_info}
      Append To List  ${session_id_list}  ${session["SessionIDs"]}
    END

    ${num_id}=  Get Length  ${session_id_list}
    Should Not Be Equal As Integers  ${num_id}  ${0}

    ${session_id_list}=  Evaluate  json.dumps(${session_id_list})  json

    [Return]  ${session_id_list}


Get Locks List On Resource With Session List
    [Documentation]  Get locks list from session of list.
    [Arguments]  ${session_id_list}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # session_id_list    Session ids list.
    # exp_status_code    Expected HTTP status code.

    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.GetLockList
    ...  data={"SessionIDs": ${session_id_list}}
    Should Be Equal As Strings  ${resp.status_code}  ${exp_status_code}
    ${locks}=  Evaluate  json.loads('''${resp.text}''')  json

    [Return]  ${locks}


Verify List Of Session Lock On Resource
    [Documentation]  Verify list of lock record from list of sessions.
    [Arguments]  ${session_dict_info}  ${transaction_id_list}

    # Description of argument(s):
    # session_dict_info      Session information in dict.
    # transaction_id_list    Transaction id in list stored in dict.

    ${session_id_list}=  Create List Of Session ID  ${session_dict_info}
    ${lock_list_resp}=  Get Locks List On Resource With Session List  ${session_id_list}
    ${lock_list}=  Set Variable  ${lock_list_resp['Records']}

    FOR  ${session_id}  ${tran_id}  ${lock_record}  IN ZIP
    ...  ${session_dict_info}  ${transaction_id_list}  ${lock_list}
      Valid Value  session_id['SessionIDs']  ['${lock_record['SessionID']}']
      Should Be Equal As Integers  ${tran_id['TransactionID']}  ${lock_record['TransactionID']}
    END


Verify Lock Records Of Multiple Session
    [Documentation]  Verify all records found for a multiple sessions.
    [Arguments]  ${client_ids}  ${lock_type}

    # Description of argument(s):
    # client_ids    This client id can contain string value
    #               (e.g. 12345, "HMCID").
    # lock_type     Read lock or Write lock.

    ${client_id_list}=  Split String  ${client_ids}  ,
    ${lock_type_list}=  Split String  ${lock_type}  ,
    ${trans_id_list1}=  Create List
    ${trans_id_list2}=  Create List

    ${session_dict_list}=  Create List
    ${lock_list}=  Create List

    ${client_id1}=  Create List
    Append To List  ${client_id1}  ${client_id_list}[0]
    ${session_info1}=  Create Session With List Of ClientID  ${client_id1}
    Append To List  ${session_dict_list}  ${session_info1}[0]
    Verify A Session Created With ClientID  ${client_id1}  ${session_info1}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    Append To List  ${trans_id_list1}  ${trans_id}
    Append To List  ${lock_list}  ${trans_id}
    Verify Lock On Resource  ${session_info1}[0]  ${trans_id_list1}


    ${client_id2}=  Create List
    Append To List  ${client_id2}  ${client_id_list}[1]
    ${session_info2}=  Create Session With List Of ClientID  ${client_id2}
    Append To List  ${session_dict_list}  ${session_info2}[0]
    Verify A Session Created With ClientID  ${client_id2}  ${session_info2}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[1]
    Append To List  ${trans_id_list2}  ${trans_id}
    Append To List  ${lock_list}  ${trans_id}
    Verify Lock On Resource  ${session_info2}[0]  ${trans_id_list2}

    Verify List Of Session Lock On Resource  ${session_dict_list}  ${lock_list}

    ${session_token}=  Get From Dictionary  ${session_info1}[0]  SessionToken
    Set Global Variable  ${XAUTH_TOKEN}  ${session_token}

    Release Locks On Resource  ${session_info1}  ${trans_id_list1}  release_lock_type=Transaction

    ${session_token}=  Get From Dictionary  ${session_info2}[0]  SessionToken
    Set Global Variable  ${XAUTH_TOKEN}  ${session_token}

    Release Locks On Resource  ${session_info2}  ${trans_id_list2}  release_lock_type=Transaction

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info1}[0]  ${trans_id_emptylist}
    Verify Lock On Resource  ${session_info2}[0]  ${trans_id_emptylist}

    Redfish Delete List Of Session  ${session_dict_list}


Verify Lock Records For Multiple Invalid Session
    [Documentation]  Verify no lock record found for multiple invalid session.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").

    ${session_dict_list}=  Create List
    ${invalid_session_ids}=  Create List  xxyXyyYZZz  xXyXYyYZzz

    ${session_info1}=  Create Session With ClientID  ${client_id}

    ${session_info2}=  Copy Dictionary  ${session_info1}  deepcopy=True
    set to dictionary  ${session_info2}  SessionIDs  ${invalid_session_ids}[0]
    Append To List  ${session_dict_list}  ${session_info2}

    ${session_info3}=  Copy Dictionary  ${session_info1}  deepcopy=True
    set to dictionary  ${session_info3}  SessionIDs  ${invalid_session_ids}[0]
    Append To List  ${session_dict_list}  ${session_info3}

    ${lock_list1}=  Get Locks List On Resource  ${session_info1}
    ${lock_length1}=  Get Length  ${lock_list1}

    ${session_id_list}=  Create List Of Session ID  ${session_dict_list}
    ${lock_list_resp}=  Get Locks List On Resource With Session List  ${session_id_list}
    ${lock_length2}=  Get Length  ${lock_list_resp['Records']}

    Should Be Equal As Integers  ${lock_length1}  ${lock_length2}

    Redfish Delete Session  ${session_info1}


Verify Lock Records For Multiple Invalid And Valid Session
    [Documentation]  Verify all records found for a valid and invalid sessions.
    [Arguments]  ${client_ids}  ${lock_type}

    # Description of argument(s):
    # client_ids    This client id can contain string value
    #               (e.g. 12345, "HMCID").
    # lock_type     Read lock or Write lock.

    ${client_id_list}=  Split String  ${client_ids}  ,
    ${lock_type_list}=  Split String  ${lock_type}  ,
    ${trans_id_list1}=  Create List
    ${invalid_session_ids}=  Create List  xxyXyyYZZz

    ${session_dict_list}=  Create List
    ${lock_list}=  Create List

    ${client_id1}=  Create List
    Append To List  ${client_id1}  ${client_id_list}[0]
    ${session_info1}=  Create Session With List Of ClientID  ${client_id1}
    Append To List  ${session_dict_list}  ${session_info1}[0]
    Verify A Session Created With ClientID  ${client_id1}  ${session_info1}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type_list}[0]
    Append To List  ${trans_id_list1}  ${trans_id}
    Append To List  ${lock_list}  ${trans_id}
    Verify Lock On Resource  ${session_info1}[0]  ${trans_id_list1}

    ${session_info2}=  Copy Dictionary  ${session_info1}  deepcopy=True
    set to dictionary  ${session_info2}[0]  SessionIDs  ${invalid_session_ids}[0]
    Append To List  ${session_dict_list}  ${session_info2}[0]

    Verify List Of Session Lock On Resource  ${session_dict_list}  ${lock_list}

    ${session_token}=  Get From Dictionary  ${session_info1}[0]  SessionToken
    Set Global Variable  ${XAUTH_TOKEN}  ${session_token}

    Release Locks On Resource  ${session_info1}  ${trans_id_list1}  release_lock_type=Transaction

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info1}[0]  ${trans_id_emptylist}

    Redfish Delete Session  ${session_info1}[0]
