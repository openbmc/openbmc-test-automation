*** Settings ***

Documentation    Test Lock Management feature of Management Console on BMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot


Suite Setup      Redfish.Login
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
&{LOCKSAME_INVALID_LEN1}        Lock=LOCK          SegmentLength=${1}
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
@{TWO_SEG_FLAG_2}               ${LOCKALL_LEN1}   ${DONTLOCK_LEN3}
@{TWO_SEG_FLAG_3}               ${LOCKSAME_LEN3}  ${DONTLOCK_LEN4}

@{TWO_SEG_FLAG_INVALID1}        ${LOCKSAME_INVALID_LEN1}  ${DONTLOCK_LEN4}
@{TWO_SEG_FLAG_INVALID2}        ${LOCKSAME_INVALID_LEN_STR}  ${LOCKALL_LEN1}

@{THREE_SEG_FLAG_1}             ${LOCKALL_LEN1}   ${TWO_SEG_FLAG_3}
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

Acquire And Verify Read Lock On A Resource
    [Documentation]  Acquire and verify read lock on a resource.
    [Tags]  Acquire_And_Verify_Read_Lock_On_A_Resource

    ${acq_lock}=  Run Keyword  Acquire Lock On A Given Resource  Read  ${TWO_SEG_FLAG_1}  216173882346831872
    Get Locks List  ${LOCKS[${acq_lock}]}


Verify GetLockList Returns An Empty Record For An Invalid Session Id.
    [Documentation]  Verify GetLockList returns an empty record for an invalid session id.
    [Tags]  Verify_GetLockList_Returns_An_Empty_Record_For_An_Invalid_Session_Id

    Get Locks List  "ZZzZZz9zzZ"


*** Keywords ***

Return Data Dictionary For Single Request
    [Documentation]  Return data dictionary for single request.
    [Arguments]  ${lock}  ${SegFlags}  ${resource_id}

    ${SEG_FLAGS_LOCK}=  Create Dictionary  LockType=${lock}  SegmentFlags=@{SegFlags}  ResourceID=${${resource_id}}
    ${SEG_FLAGS_ENTRIES}=  Create List  ${SEG_FLAGS_LOCK}
    ${LOCK_REQUEST}=  Create Dictionary  Request=${SEG_FLAGS_ENTRIES}

    [Return]  ${LOCK_REQUEST}


Acquire Lock On A Given Resource
    [Documentation]  Acquire lock on a given resource.
    [Arguments]  ${lock}  ${SegFlags}  ${resource_id}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # lock                 Type of lock (Read/Write).
    # SegFlags             Segmentation Flags to identify lock elements under system level in the hierarchy.
    #                      Ex:  [{'LockFlag': 'LockAll', 'SegmentLength': 1},
                                {'LockFlag': 'LockSame', 'SegmentLength': 2}]
    # resource_id          Decimal +ve integer value of maximum 8 hex bytes.  Ex: 134, 2048 etc.
    # exp_status_code      expected status code from the AcquireLock request for given inputs.

    ${data}=  Return Data Dictionary For Single Request  ${lock}  ${SegFlags}  ${resource_id}
    ${resp}=  Redfish.Post  /ibm/v1/HMC/LockService/Actions/LockService.AcquireLock
    ...  body=${data}  valid_status_codes=[${exp_status_code}]

    ${acquire_lock}=  Evaluate  json.loads('''${resp.text}''')  json
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


Get Locks List
    [Documentation]  Get locks list.
    [Arguments]  @{sessions}  ${exp_status_code}=${HTTP_OK}

    # Description of argument(s):
    # sessions             List of comma separated strings. Ex: ["euHoAQpvNe", "ecTjANqwFr"]
    # exp_status_code      expected status code from the GetLockList request for given inputs.

    ${data}=  Set Variable  {"SessionIDs": ${sessions}}
    ${resp}=  Redfish.Post  /ibm/v1/HMC/LockService/Actions/LockService.GetLockList
    ...  body=${data}  valid_status_codes=[${exp_status_code}]

    ${locks}=  Evaluate  json.loads('''${resp.text}''')  json


Suite Setup Execution
    [Documentation]  Suite setup execution.

    # Get REST session to BMC.
    Redfish.Login


Test Teardown Execution
    [Documentation]  Test teardown execution.

    FFDC On Test Case Fail
    Redfish.Logout

