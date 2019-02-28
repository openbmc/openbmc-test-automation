*** Settings ***
Documentation       Test suite for OpenBMC IPMI user management.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/ipmi_utils.py

Test Teardown       Test Teardown Execution


*** Variables ***

${invalid_username}     user%
${invalid_password}     abc123
${root_userid}          1
${operator_level_priv}  0x3
${admin_level_priv}     4
${valid_password}       0penBmc1
${max_password_length}  20
${ipmi_setaccess_cmd}   channel setaccess
${IPMI_EXT_CMD}         ipmitool -I lanplus -C 3
${PASSWORD_OPTION}      -P
${USER_OPTION}          -U
${SEL_INFO_CMD}         sel info


*** Test Cases ***

Verify IPMI User Summary
    [Documentation]  Verify IPMI maximum supported IPMI user ID and
    ...  enabled user form user summary
    [Tags]  Verify_IPMI_User_Summary

    # Delete all non-root IPMI (i.e. except userid 1)
    Delete All Non Root IPMI User

    # Create a valid user and enable it.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}
    Run IPMI Standard Command  user enable ${random_userid}

    # Verify maximum user count IPMI local user can have. Also verify
    # currently enabled users.
    ${resp}=  Run IPMI Standard Command  user summary
    ${enabled_user_count}=
    ...  Get Lines Containing String  ${resp}  Enabled User Count
    ${maximum_ids}=  Get Lines Containing String  ${resp}  Maximum IDs
    Should Contain  ${enabled_user_count}  2
    Should Contain  ${maximum_ids}  15


Verify IPMI User Creation With Valid Name And ID
    [Documentation]  Create user via IPMI and verify.
    [Tags]  Test_IPMI_User_Creation_With_Valid_Name_And_ID

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}


Verify IPMI User Creation With Invalid Name
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  name(e.g. user name with special characters).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_Name

    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
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

    :FOR  ${id}  IN  @{id_list}
    \    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    \    ...  user set name ${id} newuser
    \    Should Contain  ${msg}  User ID is limited to range


Verify Setting IPMI User With Invalid Password
    [Documentation]  Verify error while setting IPMI user with invalid
    ...  password.
    [Tags]  Verify_Setting_IPMI_User_With_Invalid_Password

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ${invalid_password}

    Should Contain  ${msg}  Invalid data field in request


Verify Setting IPMI Root User With New Name
    [Documentation]  Verify error while setting IPMI root user with new
    ...  name.
    [Tags]  Verify_Setting_IPMI_Root_User_With_New_Name

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${root_userid} abcd

    Should Contain  ${msg}  Set User Name command failed


Verify IPMI User Password Via Test Command
    [Documentation]  Verify IPMI user password using test command.
    [Tags]  Verify_IPMI_User_Password_Via_Test_Command

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

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

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Enable IPMI user
    Run IPMI Standard Command  user enable ${random_userid}

    # Set admin privilege and enable IPMI messaging for newly created user
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    Verify IPMI Username And Password  ${random_username}  ${valid_password}


Verify IPMI User Creation With Same Name
    [Documentation]  Verify error while creating two IPMI user with same name.
    [Tags]  Verify_IPMI_User_Creation_With_Same_Name

    ${random_username}=  Generate Random String  8  [LETTERS]
    IPMI Create User  2  ${random_username}

    # Set same username for another IPMI user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name 3 ${random_username}
    Should Contain  ${msg}  Invalid data field in request


Verify Setting IPMI User With Null Password
    [Documentation]  Verify error while setting IPMI user with null
    ...  password.
    [Tags]  Verify_Setting_IPMI_User_With_Null_Password

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set null password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ""

    Should Contain  ${msg}  Invalid data field in request


Verify IPMI User Deletion
    [Documentation]  Delete user via IPMI and verify.
    [Tags]  Verify_IPMI_User_Deletion

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Delete IPMI User and verify
    Run IPMI Standard Command  user set name ${random_userid} ""
    ${user_info}=  Get User Info  ${random_userid}
    Should Be Equal  ${user_info['user_name']}  ${EMPTY}


Enable IPMI User And Verify
    [Documentation]  Enable IPMI user and verify that the user is able
    ...  to run IPMI command.
    [Tags]  Enable_IPMI_User_And_Verify

    # Create IPMI user and set valid password.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Enable IPMI user and verify.
    Run IPMI Standard Command  user enable ${random_userid}
    ${user_info}=  Get User Info  ${random_userid}
    Should Be Equal  ${user_info['enable_status']}  enabled

    # Verify that enabled IPMI  user is able to run IPMI command.
    Verify IPMI Username And Password  ${random_username}  ${valid_password}


Disable IPMI User And Verify
    [Documentation]  Disable IPMI user and verify that that the user
    ...  is unable to run IPMI command.
    [Tags]  Disable_IPMI_User_And_Verify

    # Create IPMI user and set valid password.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Set admin privilege and enable IPMI messaging for newly created user.
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Disable IPMI user and verify.
    Run IPMI Standard Command  user disable ${random_userid}
    ${user_info}=  Get User Info  ${random_userid}
    Should Be Equal  ${user_info['enable_status']}  disabled

    # Verify that disabled IPMI  user is unable to run IPMI command.
    ${msg}=  Run Keyword And Expect Error  *  Verify IPMI Username And Password
    ...  ${random_username}  ${valid_password}
    Should Contain  ${msg}  IPMI command fails


Verify IPMI Root User Password Change
    [Documentation]  Change IPMI root user password and verify that
    ...  root user is able to run IPMI command.
    [Tags]  Verify_IPMI_Root_User_Password_Change
    [Teardown]  Wait Until Keyword Succeeds  15 sec  5 sec
    ...  Set Default Password For IPMI Root User

    # Set new password for root user.
    Run IPMI Standard Command
    ...  user set password ${root_userid} ${valid_password}

    # Verify that root user is able to run IPMI command using new password.
    Verify IPMI Username And Password  root  ${valid_password}


*** Keywords ***

IPMI Create User
    [Documentation]  Create IPMI user with given userid and username.
    [Arguments]  ${userid}  ${username}

    # Description of argument(s):
    # userid      The user ID (e.g. "1", "2", etc.).
    # username    The user name (e.g. "root", "robert", etc.).

    ${ipmi_cmd}=  Catenate  user set name ${userid} ${username}
    ${resp}=  Run IPMI Standard Command  ${ipmi_cmd}
    ${user_info}=  Get User Info  ${userid}
    Should Be Equal  ${user_info['user_name']}  ${username}


Set Channel Access
    [Documentation]  Verify that user is able to run IPMI command
    ...  with given username and password.
    [Arguments]  ${userid}  ${options}  ${channel}=1

    # Description of argument(s):
    # userid          The user ID (e.g. "1", "2", etc.).
    # options         Set channel command options (e.g.
    #                 "link=on", "ipmi=on", etc.).
    # channel_number  The user's channel number (e.g. "1").

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  ${ipmi_setaccess_cmd}${SPACE}${channel}${SPACE}${userid}
    ...  ${SPACE}${options}
    Run IPMI Standard Command  ${ipmi_cmd}

Set Default Password For IPMI Root User
    [Documentation]  Set default password for IPMI root user (i.e. 0penBmc).

    # Set default password for root user.
    ${result}=  Run External IPMI Standard Command
    ...  user set password ${root_userid} ${OPENBMC_PASSWORD}
    ...  P=${valid_password}
    Should Contain  ${result}  Set User Password command successful

    # Verify that root user is able to run IPMI command using default password.
    Verify IPMI Username And Password  root  ${OPENBMC_PASSWORD}


Verify IPMI Username And Password
    [Documentation]  Verify that user is able to run IPMI command
    ...  with given username and password.
    [Arguments]  ${username}  ${password}

    ${ipmi_cmd}=  Catenate  SEPARATOR=
    ...  ${IPMI_EXT_CMD}${SPACE}${USER_OPTION}${SPACE}${username}
    ...  ${SPACE}${PASSWORD_OPTION}${SPACE}${password}
    ...  ${SPACE}${HOST}${SPACE}${OPENBMC_HOST}${SPACE}${SEL_INFO_CMD}
    ${rc}  ${output}=  Run and Return RC and Output  ${ipmi_cmd}
    Should Be Equal  ${rc}  ${0}  msg=IPMI command fails
    Should Contain  ${output}  SEL Information


Delete All Non Root IPMI User
    [Documentation]  Delete all non-root IPMI user.

    :FOR  ${userid}  IN RANGE  2  16
    \  ${user_info}=  Get User Info  ${userid}
    \  Run Keyword If  "${user_info['user_name']}" != ""
    ...  Run IPMI Standard Command  user set name ${userid} ""


Test Teardown Execution
    [Documentation]  Do the test teardown execution.

    FFDC On Test Case Fail
    Delete All Non Root IPMI User

