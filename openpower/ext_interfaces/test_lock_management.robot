*** Settings ***

Documentation        Test lock management feature of management console on BMC.

Resource             ../../lib/resource.robot
Resource             ../../lib/openbmc_ffdc.robot
Resource             ../../lib/bmc_redfish_utils.robot
Resource             ../../lib/external_intf/management_console_utils.robot

Suite Setup          Run Keyword And Ignore Error  Delete All Redfish Sessions
Suite Teardown       Redfish.Logout
Test Setup           Printn
Test Teardown        FFDC On Test Case Fail

*** Variables ***

${BAD_REQUEST}       Bad Request

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


Check Lock Persistency On BMC Reboot
    [Documentation]  Acquire lock and check after reboot it remain same.
    [Tags]  Check_Lock_Persistency_On_BMC_Reboot
    [Template]  Acquire Lock On Resource

    # client_id    lock_type     reboot_flag
    HMCID-01       ReadCase1     True
    HMCID-01       ReadCase2     True
    HMCID-01       ReadCase3     True
    HMCID-01       WriteCase1    True
    HMCID-01       WriteCase2    True
    HMCID-01       WriteCase3    True


Acquire Read Lock On Read Lock
    [Documentation]  Acquire read lock on another read lock.
    [Tags]  Acquire_Read_Lock_On_Read_Lock
    [Template]  Acquire Lock On Another Lock

    # client_id
    HMCID-01


Get Lock Records Empty For Invalid Session
    [Documentation]  Record of lock list is empty for invalid session.
    [Tags]  Get_Lock_Records_Empty_For_Invalid_Session
    [Template]  Verify Empty Lock Records For Invalid Session

    # client_id
    HMCID-01


Fail To Acquire Lock On Another Lock
    [Documentation]  Fail to acquire another lock.
    [Tags]  Fail_To_Acquire_Lock_On_Another_Lock
    [Template]  Verify Acquire Lock Fails On Another Lock

    # client_id    lock_type
    HMCID-01       ReadCase2,WriteCase2
    HMCID-01       WriteCase2,WriteCase2
    HMCID-01       WriteCase2,ReadCase2


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


Verify Release Of Valid Locks
    [Documentation]  Release all valid locks.
    [Tags]  Verify_Release_Of_Valid_Locks
    [Template]  Acquire And Release Multiple Locks

    # client_id    lock_type                        release_lock_type
    HMCID-01       ReadCase1,ReadCase1,ReadCase1    Transaction
    HMCID-02       ReadCase1,ReadCase1,ReadCase1    Session


Invalid Locks Fail To Release
    [Documentation]  Release in-valid lock result in fail.
    [Tags]  Invalid_Locks_Fail_To_Release
    [Template]  Verify Invalid Locks Fail To Release

    # client_id    lock_type                        release_lock_type
    HMCID-01       ReadCase1,ReadCase1,ReadCase1    Transaction
    12345          ReadCase2,ReadCase2,ReadCase2    Transaction
    HMCID          ReadCase3,ReadCase3,ReadCase3    Transaction


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


Get Empty Lock Records For Session Where No Locks Acquired
    [Documentation]  If session does not acquire locks then get lock should return
    ...              empty lock records.
    [Tags]  Get_Empty_Lock_Records_For_Session_Where_No_Locks_Acquired
    [Template]  Verify No Locks Records For Session With No Acquired Lock

    # client_id
    HMCID-01

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
    [Documentation]  Create dictionay of lock request.
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


Redfish Post Acquire Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${lock_type}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # status_code    HTTP status code.

    ${lock_dict_param}=  Form Data To Acquire Lock  ${lock_type}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}
    ${resp}=  Return Description Of Response  ${resp.content}

    [Return]  ${resp}


Redfish Post Acquire Invalid Lock
    [Documentation]  Redfish to post request to acquire in-valid lock.
    [Arguments]  ${lock_type}  ${message}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # message        Return message from URI.
    # status_code    HTTP status code.

    ${lock_dict_param}=  Form Data To Acquire Invalid Lock  ${lock_type}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}
    Valid Value  message  ['${resp.content}']

    [Return]  ${resp}


Redfish Post Acquire Invalid Lock With Invalid Data Type Of Resource ID
    [Documentation]  Redfish to post request to acquire in-valid lock with invalid data type of resource id.
    [Arguments]  ${lock_type}  ${status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type      Read lock or Write lock.
    # status_code    HTTP status code.

    ${lock_dict_param}=  Form Data To Acquire Invalid Lock With Invalid Data Type Of Resource ID  ${lock_type}
    ${resp}=  Redfish Post Request  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock  data=${lock_dict_param}
    Should Be Equal As Strings  ${resp.status_code}  ${status_code}

    [Return]  ${resp}


Form Data To Acquire Lock
    [Documentation]  Create a dictionay for lock request.
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


Form Data To Acquire Invalid Lock With Invalid Data Type Of Resource ID
    [Documentation]  Create a dictionay for in-valid lock request.
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
    [Documentation]  Create a dictionay for in-valid lock request.
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


Redfish Delete Session
    [Documentation]  Redfish delete session.
    [Arguments]  ${session_info}

    # Description of argument(s):
    # session_info      Session information in dict.

    Redfish.Delete  /redfish/v1/SessionService/Sessions/${session_info["SessionIDs"]}


Acquire Lock On Resource
    [Documentation]  Acquire lock on resource.
    [Arguments]  ${client_id}  ${lock_type}  ${reboot_flag}=False

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.
    # reboot_flag  Flag is used to run reboot the BMC code.
    #               (e.g. True or False).

    ${trans_id_list}=  Create List
    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}

    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}

    Run Keyword If  '${reboot_flag}' == 'True'
    ...  Run Keywords  Redfish OBMC Reboot (off)  AND
    ...  Redfish Login  AND
    ...  Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}  AND
    ...  Verify Lock On Resource  ${session_info}  ${trans_id_list}  AND
    ...  Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}

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
    [Arguments]  ${session_info}  ${trans_id_list}  ${release_lock_type}=Transaction  ${status_code}=${HTTP_OK}

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
    Release Locks On Resource  ${session_info}  ${trans_id_list}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
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
    ${lock_length2}=  Get Length  ${lock_list1}

    Valid Value  lock_length1  ${lock_list2}

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
    Release Locks On Resource  ${session_info}  ${trans_id_list}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}

    Redfish Delete Session  ${session_info}


Verify Acquire Lock After Reboot
    [Documentation]  Acquire read and write lock after the reboot and release lock.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    ${trans_id_list}=  Create List
    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${before_reboot_xauth_token}=  Set Variable  ${XAUTH_TOKEN}
    Redfish OBMC Reboot (off)
    Redfish Login
    Set Global Variable  ${XAUTH_TOKEN}  ${before_reboot_xauth_token}

    ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
    Append To List  ${trans_id_list}  ${trans_id}
    Verify Lock On Resource  ${session_info}  ${trans_id_list}
    Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}

    ${trans_id_emptylist}=  Create List
    Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    Redfish Delete Session  ${session_info}


Verify Acquire And Release Lock In Loop
    [Documentation]  Acquire lock in loop.
    [Arguments]  ${client_id}  ${lock_type}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.

    FOR  ${count}  IN RANGE  1  11
      ${trans_id_list}=  Create List
      ${session_info}=  Create Redfish Session With ClientID  ${client_id}
      ${trans_id}=  Redfish Post Acquire Lock  ${lock_type}
      Append To List  ${trans_id_list}  ${trans_id}
      Verify Lock On Resource  ${session_info}  ${trans_id_list}
      Release Locks On Resource  ${session_info}  ${trans_id_list}  Transaction  ${HTTP_OK}
      ${trans_id_emptylist}=  Create List
      Verify Lock On Resource  ${session_info}  ${trans_id_emptylist}
    END

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


Verify Invalid Locks Fail To Release
    [Documentation]  Verify invalid locks fails to be released.
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
    [Documentation]  Verify fail to acquired lock with invalid lock types, lock flags, segement flags.
    [Arguments]  ${client_id}  ${lock_type}  ${message}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "HMCID").
    # lock_type    Read lock or Write lock.
    # message      Return message from URI.

    ${session_info}=  Create Redfish Session With ClientID  ${client_id}
    ${trans_id}=  Redfish Post Acquire Invalid Lock  ${lock_type}  message=${message}  status_code=${HTTP_BAD_REQUEST}
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
