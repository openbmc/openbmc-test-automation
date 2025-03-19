*** Settings ***
Documentation       Test suite for OpenBMC IPMI user management.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/bmc_network_utils.robot
Library             ../lib/ipmi_utils.py
Test Setup          Printn

Suite Setup         Suite Setup Execution
Test Teardown       Test Teardown Execution

Test Tags          IPMI_User

*** Variables ***

${invalid_username}     user%
${invalid_password}     abc123
${new_username}         newuser
${root_userid}          1
${operator_level_priv}  0x3
${user_priv}            2
${operator_priv}        3
${admin_level_priv}     4
${valid_password}       0penBmc1
${max_password_length}  20
${ipmi_setaccess_cmd}   channel setaccess
&{password_values}      16=0penBmc10penBmc2  17=0penBmc10penBmc2B
              ...       20=0penBmc10penBmc2Bmc3  21=0penBmc10penBmc2Bmc34
              ...       7=0penBmc  8=0penBmc0
${expected_max_ids}     15
${root_pattern}         ^.*\\sroot\\s.*ADMINISTRATOR.*$

# User defined count.
${USER_LOOP_COUNT}      20

*** Test Cases ***

Verify IPMI User Summary
    [Documentation]  Verify IPMI maximum supported IPMI user ID and
    ...  enabled user from user summary.
    [Tags]  Verify_IPMI_User_Summary
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${initial_user_count}  ${maximum_ids}=  Get Enabled User Count

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command  user enable ${random_userid}

    # Enable IPMI user and verify
    Enable IPMI User And Verify  ${random_userid}

    # Verify number of currently enabled users.
    ${current_user_count}  ${maximum_ids}=  Get Enabled User Count
    ${calculated_count}=  Evaluate  ${initial_user_count} + 1
    Should Be Equal As Integers  ${current_user_count}   ${calculated_count}

    # Verify maximum user count IPMI local user can have.
    Should Be Equal As Integers  ${maximum_ids}  ${expected_max_ids}


Verify IPMI User List
    [Documentation]  Verify user list via IPMI.
    [Tags]  Verify_IPMI_User_List
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}

    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}
    Run IPMI Standard Command  user enable ${random_userid}
    # Delay added for IPMI user to get enabled.
    Sleep  5s
    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    ${users_access}=  Get User Access Ipmi  ${CHANNEL_NUMBER}
    Rprint Vars  users_access

    ${index}=  Evaluate  ${random_userid} - 1
    # Verify the user access of created user.
    Valid Value  users_access[${index}]['id']  ['${random_userid}']
    Valid Value  users_access[${index}]['name']  ['${random_username}']
    Valid Value  users_access[${index}]['callin']  ['true']
    Valid Value  users_access[${index}]['link']  ['false']
    Valid Value  users_access[${index}]['auth']  ['true']
    Valid Value  users_access[${index}]['ipmi']  ['ADMINISTRATOR']


Verify IPMI User Creation With Valid Name And ID
    [Documentation]  Create user via IPMI and verify.
    [Tags]  Verify_IPMI_User_Creation_With_Valid_Name_And_ID
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}


Verify IPMI User Creation With Invalid Name
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  name (e.g. user name with special characters).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_Name

    ${random_userid}=  Find Free User Id
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${random_userid} ${invalid_username}
    Should Contain  ${msg}  Invalid data


Verify IPMI User Creation With Invalid ID
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  ID(i.e. any number greater than 15 or 0).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_ID

    @{id_list}=  Create List
    ${random_invalid_id}=  Evaluate  random.randint(16, 1000)  modules=random
    Append To List  ${id_list}  ${random_invalid_id}
    Append To List  ${id_list}  0

    FOR  ${id}  IN  @{id_list}
      ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
      ...  user set name ${id} newuser
      Should Contain Any  ${msg}  User ID is limited to range  Parameter out of range
    END


Verify Setting IPMI User With Invalid Password
    [Documentation]  Verify error while setting IPMI user with invalid password.
    [Tags]  Verify_Setting_IPMI_User_With_Invalid_Password
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ${invalid_password}

    # Delay added for user password to get set.
    Sleep  5s

    Should Contain  ${msg}  Set User Password command failed


Verify Setting IPMI Root User With New Name
    [Documentation]  Verify error while setting IPMI root user with new name.
    [Tags]  Verify_Setting_IPMI_Root_User_With_New_Name

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${root_userid} abcd

    Should Contain  ${msg}  Set User Name command failed


Verify IPMI User Password Via Test Command
    [Documentation]  Verify IPMI user password using test command.
    [Tags]  Verify_IPMI_User_Password_Via_Test_Command
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Verify newly set password using test command.
    ${msg}=  Run IPMI Standard Command
    ...  user test ${random_userid} ${max_password_length} ${valid_password}

    Should Contain  ${msg}  Success


Verify Setting Valid Password For IPMI User
    [Documentation]  Set valid password for IPMI user and verify.
    [Tags]  Verify_Setting_Valid_Password_For_IPMI_User
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    Run IPMI Standard Command  user enable ${random_userid}

    # Delay added for IPMI user to get enable
    Sleep  5s

    # Set admin privilege and enable IPMI messaging for newly created user
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    Verify IPMI Username And Password  ${random_username}  ${valid_password}


Verify IPMI User Creation With Same Name
    [Documentation]  Verify error while creating two IPMI user with same name.
    [Tags]  Verify_IPMI_User_Creation_With_Same_Name
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User

    # Set same username for another IPMI user.
    ${rand_userid_two}=  Find Free User Id
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${rand_userid_two} ${random_username}
    Should Contain  ${msg}  Invalid data field in request


Verify Setting IPMI User With Null Password
    [Documentation]  Verify error while setting IPMI user with null
    ...  password.
    [Tags]  Verify_Setting_IPMI_User_With_Null_Password
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}

    # Set null password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ""

    Should Contain  ${msg}  Invalid data field in request


Verify IPMI User Deletion
    [Documentation]  Delete user via IPMI and verify.
    [Tags]  Verify_IPMI_User_Deletion
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    # Delete IPMI User and verify
    Run IPMI Standard Command  user set name ${random_userid} ""
    ${user_info}=  Get User Info  ${random_userid}  ${CHANNEL_NUMBER}
    Should Be Equal  ${user_info['user_name']}  ${EMPTY}


Test IPMI User Privilege Level
    [Documentation]  Verify IPMI user with user privilege can only run user level commands.
    [Tags]  Test_IPMI_User_Privilege_Level
    [Template]  Test IPMI User Privilege
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    #Privilege level     User Cmd Status  Operator Cmd Status  Admin Cmd Status
    ${user_priv}         Passed           Failed               Failed


Test IPMI Operator Privilege Level
    [Documentation]  Verify IPMI user with operator privilege can only run user and
    ...   operator level commands.
    [Tags]  Test_IPMI_Operator_Privilege_Level
    [Template]  Test IPMI User Privilege
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    #Privilege level     User Cmd Status  Operator Cmd Status  Admin Cmd Status
    ${operator_priv}     Passed           Passed               Failed


Test IPMI Administrator Privilege Level
    [Documentation]  Verify IPMI user with admin privilege can run all levels command.
    [Tags]  Test_IPMI_Administrator_Privilege_Level
    [Template]  Test IPMI User Privilege
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    #Privilege level     User Cmd Status  Operator Cmd Status  Admin Cmd Status
    ${admin_level_priv}  Passed           Passed               Passed


Enable IPMI User And Verify
    [Documentation]  Enable IPMI user and verify that the user is able
    ...  to run IPMI command.
    [Tags]  Enable_IPMI_User_And_Verify
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Delay added for user privilege to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${random_userid}
    Wait And Confirm New Username And Password  ${random_username}  ${valid_password}

    # Verify that enabled IPMI  user is able to run IPMI command.
    Verify IPMI Username And Password  ${random_username}  ${valid_password}


Disable IPMI User And Verify
    [Documentation]  Disable IPMI user and verify that that the user
    ...  is unable to run IPMI command.
    [Tags]  Disable_IPMI_User_And_Verify
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Disable IPMI user and verify.
    Run IPMI Standard Command  user disable ${random_userid}
    ${user_info}=  Get User Info  ${random_userid}  ${CHANNEL_NUMBER}
    Should Be Equal  ${user_info['enable_status']}  disabled

    # Verify that disabled IPMI  user is unable to run IPMI command.
    ${msg}=  Run Keyword And Expect Error  *  Verify IPMI Username And Password
    ...  ${random_username}  ${valid_password}
    Should Contain  ${msg}  Unable to establish IPMI


Verify IPMI Root User Password Change
    [Documentation]  Change IPMI root user password and verify that
    ...  root user is able to run IPMI command.
    [Tags]  Verify_IPMI_Root_User_Password_Change
    [Setup]  Skip if  len( '${OPENBMC_PASSWORD}' ) < 8
    ...  msg= Do not run this test if len( OPENBMC_PASSWORD ) < 8
    # Reason: if OPENBMC_PASSWORD is not at least 8 characters,
    #         it cannot be restored in the Teardown step.
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Run Keyword If  "${TEST STATUS}" != "SKIP"
    ...  Wait Until Keyword Succeeds  15 sec  5 sec
    ...  Restore Default Password For IPMI Root User

    # Set new password for root user.
    Run IPMI Standard Command
    ...  user set password ${root_userid} ${valid_password}

    # Delay added for user password to get set.
    Sleep  5s

    # Verify that root user is able to run IPMI command using new password.
    Wait Until Keyword Succeeds  15 sec  5 sec  Verify IPMI Username And Password
    ...  root  ${valid_password}


Verify Administrator And User Privilege For Different Channels
    [Documentation]  Set administrator and user privilege for different channels and verify.
    [Tags]  Verify_Administrator_And_User_Privilege_For_Different_Channels
    [Setup]  Check Active Ethernet Channels
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set admin privilege for newly created user with channel 1.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}  ${CHANNEL_NUMBER}

    # Set user privilege for newly created user with channel 2.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${user_priv}  ${secondary_channel_number}

    # Delay added for user privileges to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${random_userid}

    # Verify that user is able to run administrator level IPMI command with channel 1.
    Verify IPMI Command  ${random_username}  ${valid_password}  Administrator  ${CHANNEL_NUMBER}

    # Verify that user is unable to run IPMI command with channel 2.
    Run IPMI Standard Command
    ...  sel info ${secondary_channel_number}  expected_rc=${1}  U=${random_username}  P=${valid_password}


Verify Operator And User Privilege For Different Channels
    [Documentation]  Set operator and user privilege for different channels and verify.
    [Tags]  Verify_Operator_And_User_Privilege_For_Different_Channels
    [Setup]  Check Active Ethernet Channels
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set operator privilege for newly created user with channel 1.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${operator_priv}  ${CHANNEL_NUMBER}

    # Set user privilege for newly created user with channel 2.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${user_priv}  ${secondary_channel_number}

    # Delay added for user privileges to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${random_userid}

    # Verify that user is able to run operator level IPMI command with channel 1.
    Verify IPMI Command  ${random_username}  ${valid_password}  Operator  ${CHANNEL_NUMBER}

    # Verify that user is able to run user level IPMI command with channel 2.
    Verify IPMI Command  ${random_username}  ${valid_password}  User  ${secondary_channel_number}


Verify Setting IPMI User With Max Password Length
    [Documentation]  Verify IPMI user creation with password length of 20 characters.
    [Tags]  Verify_Setting_IPMI_User_With_Max_Password_Length
    [Template]  Set User Password And Verify

    # password_length  password_option  expected_status
    20                 20               ${True}


Verify Setting IPMI User With Invalid Password Length
    [Documentation]  Verify that IPMI user cannot be set with 21 character password using 16 char
    ...  or 20 char password option.
    [Tags]  Verify_Setting_IPMI_User_With_Invalid_Password_Length
    [Template]  Set User Password And Verify

    # password_length  password_option  expected_status
    21                 16               ${False}
    21                 20               ${False}


Verify Setting IPMI User With 16 Character Password
    [Documentation]  Verify that IPMI user can create a 16 character password using 16 char or 20
    ...  char password option.
    [Tags]  Verify_Setting_IPMI_User_With_16_Character_Password
    [Template]  Set User Password And Verify

    # password_length  password_option  expected_status
    16                 16               ${True}
    16                 20               ${True}


Verify Default Selection Of 16 Character Password For IPMI User
    [Documentation]  Verify that ipmitool by default opts for the 16 character option when given a
    ...  password whose length is in between 17 and 20.
    [Tags]  Verify_Default_Selection_Of_16_Character_Password_For_IPMI_User
    [Template]  Set User Password And Verify

    # password_length  password_option  expected_status
    17                 16               ${True}
    20                 16               ${True}


Verify Minimum Password Length For IPMI User
    [Documentation]  Verify minimum password length of 8 characters.
    [Tags]  Verify_Minimum_Password_Length_For_IPMI_User
    [Template]  Set User Password And Verify

    # password_length  password_option  expected_status
    7                  16               ${False}
    8                  16               ${True}
    7                  20               ${False}
    8                  20               ${True}


Verify Continuous IPMI Command Execution
    [Documentation]  Verify that continuous IPMI command execution runs fine.
    [Tags]  Verify_Continuous_IPMI_Command_Execution

    FOR  ${i}  IN RANGE  ${USER_LOOP_COUNT}
        Run IPMI Standard Command  lan print ${CHANNEL_NUMBER}
        Run IPMI Standard Command  power status
        Run IPMI Standard Command  fru list
        Run IPMI Standard Command  sel list
    END


Modify IPMI User
    [Documentation]  Verify modified IPMI user is communicating via IPMI.
    [Tags]  Modify_IPMI_User
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}

    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Delay added for user privilege to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${random_userid}

    # Verify that user is able to run administrator level IPMI command.
    Verify IPMI Command  ${random_username}  ${valid_password}  Administrator  ${CHANNEL_NUMBER}

    # Set different username for same IPMI user.
    Run IPMI Standard Command
    ...  user set name ${random_userid} ${new_username}
    Wait And Confirm New Username And Password  ${new_username}  ${valid_password}

    # Verify that user is able to run administrator level IPMI command.
    Verify IPMI Command  ${new_username}  ${valid_password}  Administrator  ${CHANNEL_NUMBER}


*** Keywords ***

Restore Default Password For IPMI Root User
    [Documentation]  Restore default password for IPMI root user

    ${result}=  Run External IPMI Standard Command
    ...  user set password ${root_userid} ${OPENBMC_PASSWORD}
    ...  P=${valid_password}
    Should Contain  ${result}  Set User Password command successful

    # Verify that root user is able to run IPMI command using default password.
    Verify IPMI Username And Password  root  ${OPENBMC_PASSWORD}


Test IPMI User Privilege
    [Documentation]  Test IPMI user privilege by executing IPMI command with different privileges.
    [Arguments]  ${privilege_level}  ${user_cmd_status}  ${operator_cmd_status}  ${admin_cmd_status}

    # Description of argument(s):
    # privilege_level     Privilege level of IPMI user (e.g. 4, 3).
    # user_cmd_status     Expected status of IPMI command run with the "User"
    #                     privilege (i.e. "Passed" or "Failed").
    # operator_cmd_status Expected status of IPMI command run with the "Operator"
    #                     privilege (i.e. "Passed" or "Failed").
    # admin_cmd_status    Expected status of IPMI command run with the "Administrator"
    #                     privilege (i.e. "Passed" or "Failed").

    # Create IPMI user and set valid password.
    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${privilege_level}

    # Delay added for user privilege to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${random_userid}

    Verify IPMI Command  ${random_username}  ${valid_password}  User
    ...  expected_status=${user_cmd_status}
    Verify IPMI Command  ${random_username}  ${valid_password}  Operator
    ...  expected_status=${operator_cmd_status}
    Verify IPMI Command  ${random_username}  ${valid_password}  Administrator
    ...  expected_status=${admin_cmd_status}


Verify IPMI Command
    [Documentation]  Verify IPMI command execution with given username,
    ...  password, privilege and expected status.
    [Arguments]  ${username}  ${password}  ${privilege}  ${channel}=${1}  ${expected_status}=Passed
    # Description of argument(s):
    # username         The user name (e.g. "root", "robert", etc.).
    # password         The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # privilege        The session privilege for IPMI command (e.g. "User", "Operator", etc.).
    # channel          The user channel number (e.g. "1" or "2").
    # expected_status  Expected status of IPMI command run with the user
    #                  of above password and privilege (i.e. "Passed" or "Failed").

    ${expected_rc}=  Set Variable If  '${expected_status}' == 'Passed'  ${0}  ${1}
    Wait Until Keyword Succeeds  15 sec  5 sec  Run IPMI Standard Command
    ...  sel info ${channel}  expected_rc=${expected_rc}  U=${username}  P=${password}
    ...  L=${privilege}


Set User Password And Verify
    [Documentation]  Create a user and set its password with given length and option.
    [Arguments]  ${password_length}  ${password_option}  ${expected_result}
    [Teardown]  Run Keyword  Delete Created User  ${random_userid}
    # Description of argument(s):
    # password_length  Length of password to be generated and used (e.g. "16").
    # password_option  Password length option to be given in IPMI command (e.g. "16", "20").
    # expected_result  Expected result for setting the user's password (e.g. "True", "False").

    Rprint Vars  password_length  password_option  expected_result
    ${random_userid}  ${random_username}=  Create Random IPMI User
    Set Test Variable  ${random_userid}
    ${password}=  Get From Dictionary  ${password_values}  ${password_length}
    Rprint Vars  random_userid  password

    # Set password for newly created user.
    ${status}=  Run Keyword And Return Status  Run IPMI Standard Command
    ...  user set password ${random_userid} ${password} ${password_option}
    Rprint Vars  status
    Valid Value  status  [${expected_result}]
    Return From Keyword If  '${expected_result}' == '${False}'

    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Delay added for user privilege to get set.
    Sleep  5s

    Enable IPMI User And Verify  ${random_userid}

    # For password_option 16, passwords with length between 17 and 20 will be truncated.
    # For all other cases, passwords will be retained as it is to verify.
    ${truncated_password}=  Set Variable  ${password[:${password_option}]}
    Rprint Vars  truncated_password
    ${status}=  Run Keyword And Return Status  Verify IPMI Username And Password  ${random_username}
    ...  ${truncated_password}
    Rprint Vars  status
    Valid Value  status  [${expected_result}]


Test Teardown Execution
    [Documentation]  Do the test teardown execution.

    FFDC On Test Case Fail


Check Active Ethernet Channels
    [Documentation]  Check active ethernet channels and set suite variables.

    ${channel_number_list}=  Get Active Ethernet Channel List
    ${channel_length}=  Get Length  ${channel_number_list}
    Skip If  '${channel_length}' == '1'
    ...  msg= Skips this test case as only one channel was in active.

    FOR  ${channel_num}  IN  @{channel_number_list}
        ${secondary_channel_number}=  Set Variable If  ${channel_num} != ${CHANNEL_NUMBER}  ${channel_num}
    END

    Set Suite Variable  ${secondary_channel_number}


Suite Setup Execution
    [Documentation]  Make sure the enabled user count is below maximum,
    ...  and prepares administrative user list suite variables.

    Check Enabled User Count
    # Skip root user checking if user decides not to use root user as default.
    Run Keyword If  '${IPMI_USERNAME}' == 'root'  Determine Root User Id


Determine Root User Id
    [Documentation]  Determines the user ID of the root user.

    ${resp}=  Wait Until Keyword Succeeds  15 sec  1 sec  Run IPMI Standard Command
    ...  user list ${CHANNEL_NUMBER}
    @{lines}=  Split To Lines  ${resp}

    ${root_userid}=  Set Variable  ${-1}
    ${line_count}=  Get Length  ${lines}
    FOR  ${id_index}  IN RANGE  1  ${line_count}
        ${line}=  Get From List  ${lines}  ${id_index}
        ${root_found}=  Get Lines Matching Regexp  ${line}  ${root_pattern}
        IF  '${root_found}' != '${EMPTY}'
            ${root_userid}=  Set Variable  ${id_index}
            Exit For Loop
        END
    END
    Set Suite Variable  ${root_userid}

    Log To Console  The root user ID is ${root_userid}.
    Run Keyword If  ${root_userid} < ${1}  Fail  msg= Did not identify root user ID.


Wait And Confirm New Username And Password
    [Documentation]  Wait in loop trying to to confirm Username And Password.
    [Arguments]  ${username}  ${password}

    # Description of argument(s):
    # username         The user name (e.g. "root", "robert", etc.).
    # password         The user password (e.g. "0penBmc", "0penBmc1", etc.).

    # Give time for previous command to complete.
    Sleep  5s

    # Looping verify that root user is able to run IPMI command using new password.
    Wait Until Keyword Succeeds  15 sec  5 sec  Verify IPMI Username And Password
    ...  ${username}  ${password}


Get Enabled User Count
    [Documentation]  Return as integers: current number of enabled users and
    ...  Maximum number of Ids.

    # Isolate 'Enabled User Count' value and convert to integer
    ${resp}=  Wait Until Keyword Succeeds  15 sec  1 sec  Run IPMI Standard Command
    ...  user summary ${CHANNEL_NUMBER}
    ${user_count_line}=  Get Lines Containing String  ${resp}  Enabled User Count
    ${count}=  Fetch From Right  ${user_count_line}  \:
    ${user_count}=  Convert To Integer  ${count}

    # Isolate 'Maximum IDs' value and convert to integer
    ${maximum_ids}=  Get Lines Containing String  ${resp}  Maximum IDs
    ${max_ids}=  Fetch From Right  ${maximum_ids}  \:
    ${int_maximum_ids_count}=  Convert To Integer  ${max_ids}

    RETURN  ${user_count}  ${int_maximum_ids_count}
