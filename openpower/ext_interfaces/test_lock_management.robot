*** Settings ***

Documentation    Test Lock Management feature of Management Console on BMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot


Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Teardown    Test Teardown Execution


*** Variables ***

# Data-sets for testing different test cases.
&{LOCKALL_LEN1}                 LockFlag=LockAll  SegmentLength=${1}
&{LOCKALL_LEN2}                 LockFlag=LockAll  SegmentLength=${2}
&{LOCKALL_LEN3}                 LockFlag=LockAll  SegmentLength=${3}
&{LOCKALL_LEN4}                 LockFlag=LockAll  SegmentLength=${4}
&{LOCKALL_LEN5}                 LockFlag=LockAll  SegmentLength=${5}
&{LOCKALL_INVALID_LEN1}         LockFlag=LOCKALL  SegmentLength=${1}
&{LOCKALL_INVALID_LEN2}         LockFlag=LOCKAL   SegmentLength=${2}
&{LOCKALL_INVALID_LEN3}         LockFla=LockAll   SegmentLength=${3}
&{LOCKALL_INVALID_LEN2}         LOCKFLAG=LockAll  SegmentLength=${4}

&{LOCKSAME_LEN1}                LockFlag=LockSame  SegmentLength=${1}
&{LOCKSAME_LEN2}                LockFlag=LockSame  SegmentLength=${2}
&{LOCKSAME_LEN3}                LockFlag=LockSame  SegmentLength=${3}
&{LOCKSAME_LEN4}                LockFlag=LockSame  SegmentLength=${4}
&{LOCKSAME_LEN5}                LockFlag=LockSame  SegmentLength=${5}
&{LOCKSAME_INVALID_LEN1}        LockFlag=LockSame  SegmentLength=${1}
&{LOCKSAME_INVALID_LEN_STR}     LockFlag=LockSame  SegmentLength=2
&{LOCKSAME_INVALID_LEN_NEG}     LockFlag=LockSame  SegmentLength=${-3}
&{LOCKSAME_INVALID_LEN_BOOL}    LockFlag=LockSame  SegmentLength=${True}

&{DONTLOCK_LEN1}                LockFlag=DontLock  SegmentLength=${1}
&{DONTLOCK_LEN2}                LockFlag=DontLock  SegmentLength=${2}
&{DONTLOCK_LEN3}                LockFlag=DontLock  SegmentLength=${3}
&{DONTLOCK_LEN4}                LockFlag=DontLock  SegmentLength=${4}
&{DONTLOCK_LEN5}                LockFlag=DontLock  SegmentLength=${5}
&{DONTLOCK_LEN5}                LockFlag=DontLock  SegmentLength=${5}
&{DONTLOCK_INVALID_LEN_BOOL}    LockFlag=DONTLOCK  SegmentLength=${False}

@{ONE_SEG_FLAG_ALL}             ${LOCKALL_LEN1}
@{ONE_SEG_FLAG_SAME}            ${LOCKSAME_LEN3}
@{ONE_SEG_FLAG_DONT}            ${DONTLOCK_LEN4}

@{TWO_SEG_FLAG_1}               ${LOCKALL_LEN1}   ${LOCKSAME_LEN2}
@{TWO_SEG_FLAG_2}               ${DONTLOCK_LEN3}  ${LOCKALL_LEN1}
@{TWO_SEG_FLAG_3}               ${DONTLOCK_LEN4}  ${LOCKSAME_LEN3}

@{TWO_SEG_FLAG_INVALID1}        ${LOCKSAME_INVALID_LEN1}  ${DONTLOCK_LEN4}
@{TWO_SEG_FLAG_INVALID2}        ${LOCKSAME_INVALID_LEN_STR}  ${LOCKALL_LEN1}

@{THREE_SEG_FLAG_1}             ${LOCKALL_LEN1}   @{TWO_SEG_FLAG_3}
@{THREE_SEG_FLAG_2}             ${LOCKSAME_LEN4}  @{TWO_SEG_FLAG_2}
@{THREE_SEG_FLAG_3}             ${DONTLOCK_LEN3}  @{TWO_SEG_FLAG_1}

@{FOUR_SEG_FLAG_1}              ${LOCKALL_LEN1}   @{THREE_SEG_FLAG_2}
@{FOUR_SEG_FLAG_2}              ${LOCKSAME_LEN4}  @{THREE_SEG_FLAG_3}
@{FOUR_SEG_FLAG_3}              ${DONTLOCK_LEN3}  @{THREE_SEG_FLAG_1}

@{FOUR_SEG_FLAG_INVALID1}       ${LOCKALL_LEN1}  ${LOCKSAME_INVALID_LEN_NEG}
@{FOUR_SEG_FLAG_INVALID2}       ${LOCKSAME_LEN4}  ${DONTLOCK_INVALID_LEN_BOOL}

@{FIVE_SEG_FLAG_1}              ${LOCKALL_LEN1}   @{FOUR_SEG_FLAG_2}
@{FIVE_SEG_FLAG_2}              ${LOCKSAME_LEN4}  @{FOUR_SEG_FLAG_3}
@{FIVE_SEG_FLAG_3}              ${DONTLOCK_LEN3}  @{FOUR_SEG_FLAG_1}

@{SIX_SEG_FLAG_1}               ${LOCKALL_LEN1}   @{FIVE_SEG_FLAG_2}
@{SIX_SEG_FLAG_2}               ${LOCKSAME_LEN4}  @{FIVE_SEG_FLAG_3}
@{SIX_SEG_FLAG_3}               ${DONTLOCK_LEN3}  @{FIVE_SEG_FLAG_1}

@{SEVEN_SEG_FLAG_1}             ${LOCKALL_LEN1}   @{SIX_SEG_FLAG_2}
@{SEVEN_SEG_FLAG_2}             ${LOCKSAME_LEN4}  @{SIX_SEG_FLAG_3}
@{SEVEN_SEG_FLAG_3}             ${DONTLOCK_LEN3}  @{SIX_SEG_FLAG_1}


# Different messages to be verified
${LOCKFLAG_REQUIRED_MSG}  The property LockFlag is a required property and must be included in the request.
${LOCKFLAG_INVALID_MSG}   The property LockFla is not in the list of valid properties for the resource.
${INVALID_SEG_LEN_MSG}    for the property SegmentLength is of a different type than the property can accept.


# Dictionary of Locks with Transaction ID as key and Session ID as a value.
&{LOCKS}


*** Test Cases ***

Acquire And Release Different Read Locks
    [Documentation]  Acquire and release different read locks.
    [Tags]  Acquire_And_Release_Different_Read_Locks
    [Template]  Acquire And Release Lock

    # lock_type  seg_flags                     resource_id             hmc_id   exp_status_code
    Read         ${ONE_SEG_FLAG_ALL}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${ONE_SEG_FLAG_SAME}          ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${ONE_SEG_FLAG_DONT}          ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${TWO_SEG_FLAG_1}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${TWO_SEG_FLAG_2}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${TWO_SEG_FLAG_3}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${THREE_SEG_FLAG_1}           ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${THREE_SEG_FLAG_2}           ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${THREE_SEG_FLAG_3}           ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${FOUR_SEG_FLAG_1}            ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${FOUR_SEG_FLAG_2}            ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${FOUR_SEG_FLAG_3}            ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${FIVE_SEG_FLAG_1}            ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${FIVE_SEG_FLAG_2}            ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${FIVE_SEG_FLAG_3}            ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${SIX_SEG_FLAG_1}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${SIX_SEG_FLAG_2}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${SIX_SEG_FLAG_3}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Read         ${SEVEN_SEG_FLAG_1}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${SEVEN_SEG_FLAG_2}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${SEVEN_SEG_FLAG_3}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${LOCKSAME_INVALID_LEN1}      ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${LOCKSAME_INVALID_LEN_STR}   ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${LOCKSAME_INVALID_LEN_NEG}   ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${LOCKSAME_INVALID_LEN_BOOL}  ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${DONTLOCK_INVALID_LEN_BOOL}  ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${TWO_SEG_FLAG_INVALID1}      ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${TWO_SEG_FLAG_INVALID2}      ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${FOUR_SEG_FLAG_INVALID1}     ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Read         ${FOUR_SEG_FLAG_INVALID2}     ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}    


Acquire And Release Different Write Locks
    [Documentation]  Acquire and release different write locks.
    [Tags]  Acquire_And_Release_Different_Write_Locks
    [Template]  Acquire And Release Lock

    # lock_type   seg_flags                     resource_id             hmc_id   exp_status_code
    Write         ${ONE_SEG_FLAG_ALL}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${ONE_SEG_FLAG_SAME}          ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${ONE_SEG_FLAG_DONT}          ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${TWO_SEG_FLAG_1}             ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${TWO_SEG_FLAG_2}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Write         ${TWO_SEG_FLAG_3}             ${216173882346831872}   hmc-id   ${HTTP_OK}
    Write         ${THREE_SEG_FLAG_1}           ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${THREE_SEG_FLAG_2}           ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${THREE_SEG_FLAG_3}           ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${FOUR_SEG_FLAG_1}            ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${FOUR_SEG_FLAG_2}            ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${FOUR_SEG_FLAG_3}            ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${FIVE_SEG_FLAG_1}            ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${FIVE_SEG_FLAG_2}            ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${FIVE_SEG_FLAG_3}            ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${SIX_SEG_FLAG_1}             ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${SIX_SEG_FLAG_2}             ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${SIX_SEG_FLAG_3}             ${216173882346831872}   hmc-id   ${HTTP_CONFLICT}
    Write         ${SEVEN_SEG_FLAG_1}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${SEVEN_SEG_FLAG_2}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${SEVEN_SEG_FLAG_3}           ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${LOCKSAME_INVALID_LEN1}      ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${LOCKSAME_INVALID_LEN_STR}   ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${LOCKSAME_INVALID_LEN_NEG}   ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${LOCKSAME_INVALID_LEN_BOOL}  ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${DONTLOCK_INVALID_LEN_BOOL}  ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${TWO_SEG_FLAG_INVALID1}      ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${TWO_SEG_FLAG_INVALID2}      ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${FOUR_SEG_FLAG_INVALID1}     ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}
    Write         ${FOUR_SEG_FLAG_INVALID2}     ${216173882346831872}   hmc-id   ${HTTP_BAD_REQUEST}


Verify GetLockList Returns An Empty Record For An Invalid Session Id.
    [Documentation]  Verify GetLockList returns an empty record for an invalid session id.
    [Tags]  Verify_GetLockList_Returns_An_Empty_Record_For_An_Invalid_Session_Id

    ${session_location}=  Redfish.Get Session Location
    ${session_id}=  Evaluate  os.path.basename($session_location)  modules=os

    ${records}=  Run Keyword  Get Locks List  ${session_id}
    ${records}=  Run Keyword  Get Locks List  ZZzZZz9zzZ
    ${length}=  Get Length  ${records}
    Should Be Equal  ${length}  ${0}


*** Keywords ***

Return Data Dictionary For Single Request
    [Documentation]  Return data dictionary for single request.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}

    # Description of argument(s):
    # lock_type            Type of lock (Read/Write).
    # seg_flags             Segmentation Flags to identify lock elements under system level in the hierarchy.
    # resource_id          Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.

    ${SEG_FLAGS_LOCK}=  Create Dictionary  LockType=${lock_type}  SegmentFlags=@{SegFlags}  ResourceID=${${resource_id}}
    ${SEG_FLAGS_ENTRIES}=  Create List  ${SEG_FLAGS_LOCK}
    ${LOCK_REQUEST}=  Create Dictionary  Request=${SEG_FLAGS_ENTRIES}

    [Return]  ${LOCK_REQUEST}


Acquire Lock On A Given Resource
    [Documentation]  Acquire lock on a given resource.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type            Type of lock (Read/Write).
    # seg_flags             Segmentation Flags to identify lock elements under system level in the hierarchy.
    #                      Ex:  [{'LockFlag': 'LockAll', 'SegmentLength': 1},
    #                           {'LockFlag': 'LockSame', 'SegmentLength': 2}]
    # resource_id          Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.
    # exp_status_code      expected status code from the AcquireLock request for given inputs.

    ${data}=  Return Data Dictionary For Single Request  ${lock_type}  ${seg_flags}  ${resource_id}
    ${resp}=  Redfish.Post  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock
    ...  body=${data}  valid_status_codes=[${exp_status_code}]

    Log To Console  ${resp.text}
    ${transaction_id}=  Run Keyword If  ${exp_status_code} != ${HTTP_OK}
    ...  Set Variable  ${0}
    ...  ELSE   Load Lock Record And Build Transaction To Session Map  ${resp.text}

    Append Transaction Id And Session Id To Locks Dictionary  ${transaction_id}

    [Return]  ${transaction_id}


Load Lock Record And Build Transaction To Session Map
    [Documentation]  Load lock record and build transaction to session map.
    [Arguments]  ${resp_text}

    # Description of argument(s):
    # resp_text     Response test from a REST request.

    ${acquire_lock}=  Evaluate  json.loads('''${resp_text}''')  json
    Append Transaction Id And Session Id To Locks Dictionary  ${acquire_lock["TransactionID"]}

    [Return]  ${acquire_lock["TransactionID"]}


Append Transaction Id And Session Id To Locks Dictionary
    [Documentation]  Append transaction id and session id to locks dictionary.
    [Arguments]  ${transaction_id}

    # Description of argument(s):
    # transaction_id    Transaction ID created from acquire lock request. Ex: 8, 9 etc.

    ${session_location}=  Redfish.Get Session Location
    ${session_id}=  Evaluate  os.path.basename($session_location)  modules=os
    Set To Dictionary  ${LOCKS}  ${${transaction_id}}  ${session_id}
    Log To Console  LOCKS=${LOCKS}


Get Locks List
    [Documentation]  Get locks list.
    [Arguments]  @{sessions}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # sessions             List of comma separated strings. Ex: ["euHoAQpvNe", "ecTjANqwFr"]
    # exp_status_code      expected status code from the GetLockList request for given inputs.

    ${sessions}=  Evaluate  json.dumps(${sessions})  json
    ${data}=  Set Variable  {"SessionIDs": ${sessions}}
    ${resp}=  Redfish.Post  /ibm/v1/HMC/LockService/Actions/LockService.GetLockList
    ...  body=${data}  valid_status_codes=[${exp_status_code}]

    ${locks}=  Evaluate  json.loads('''${resp.text}''')  json

    [Return]  ${locks["Records"]}


Release Lock
    [Documentation]  Release lock.
    [Arguments]  @{transaction_ids}  ${release_type}=Transaction  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # transaction_ids     List of transaction ids. Ex: [15, 18]
    # release_type        Release all locks acquired using current session or only given transaction numbers.
    #                     Ex:  Session,  Transaction.  Default will be Transaction.
    # exp_status_code     expected status code from the ReleaseLock request for given inputs.     

    ${data}=  Set Variable  {"Type": "${release_type}", "TransactionIDs": ${transaction_ids}}
    ${data}=  Evaluate  json.dumps(${data})  json
    ${resp}=  Redfish.Post  /ibm/v1/HMC/LockService/Actions/LockService.ReleaseLock
    ...  body=${data}  valid_status_codes=[${exp_status_code}]
 

Verify Lock Record
    [Documentation]  Verify lock record.
    [Arguments]  ${lock_found}  &{lock_records}

    # Description of argument(s):
    # lock_records     A dictionary containing key value pairs of a lock record.
    # lock_found       True if lock record is expected to be present, else False.

    ${session}=  Get From Dictionary  ${LOCKS}  ${lock_records["TransactionID"]}
    ${locks}=  Run Keyword  Get Locks List  ${session}

    ${lock_record_found}=  Set Variable  ${False}
    FOR  ${record}  IN  @{locks}
      ${record}=  Evaluate  json.dumps(${record})  json
      ${record}=  Evaluate  json.loads('''${record}''')  json
      ${lock_record_found}=  Set Variable If  ${record["TransactionID"]} == ${lock_records["TransactionID"]}
      ...  ${True}  ${False}

      Continue For Loop If  ${lock_record_found} == ${False}
      
      Dictionaries Should Be Equal  ${record}  ${lock_records}
      Exit For Loop
    END

    Should Be Equal  ${lock_record_found}  ${lock_found}


Acquire And Release Lock
    [Documentation]  Acquire and release lock.
    [Arguments]  ${lock_type}  ${seg_flags}  ${resource_id}  ${hmc_id}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock_type            Type of lock (Read/Write).
    # seg_flags            Segmentation Flags to identify lock elements under system level in the hierarchy.
    #                      Ex:  [{'LockFlag': 'LockAll', 'SegmentLength': 1},
    #                           {'LockFlag': 'LockSame', 'SegmentLength': 2}]
    # resource_id          Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.
    # hmc_id               Hardware management console id.
    # exp_status_code      expected status code from the AcquireLock request for given inputs.

    ${inputs}=  Create Dictionary  LockType=${lock_type}  ResourceID=${resource_id}
    ...  SegmentFlags=${seg_flags}  HMCID=${hmc_id}

    ${transaction_id}=  Run Keyword  Acquire Lock On A Given Resource
    ...  ${inputs["LockType"]}  ${inputs["SegmentFlags"]}  ${inputs["ResourceID"]}  ${exp_status_code}

    ${session}=  Get From Dictionary  ${LOCKS}  ${transaction_id}
    ${locks}=  Run Keyword  Get Locks List  ${session}

    Set To Dictionary  ${inputs}  TransactionID=${${transaction_id}}  SessionID=${session}
    ${lock_found}=  Set Variable If  ${exp_status_code} == ${HTTP_OK}  ${True}  ${False}
    Verify Lock Record  ${lock_found}  &{inputs}

    Return From Keyword If  ${exp_status_code} != ${HTTP_OK}

    Release Lock  ${transaction_id}
    ${locks}=  Run Keyword  Get Locks List  ${session}
    Verify Lock Record  ${False}  &{inputs}
    

Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Get REST session to BMC.
    Redfish.Login


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
