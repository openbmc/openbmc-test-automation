*** Settings ***

Documentation    Module to test IPMI management controller ID functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py

Test Teardown    FFDC On Test Case Fail


*** Variables ***

${new_mc_id}=  HOST


*** Test Cases ***

Verify Get And Set Management Controller ID String
    [Documentation]  Verify get and set management controller ID string.
    [Tags]  Verify_Get_And_Set_Management_Controller_ID_String
    # Get the value of the managemment controller ID string.
    # Example:
    # Get Management Controller Identifier String: witherspoon

    ${cmd_output}=  Wait Until Keyword Succeeds  15 sec  5 sec
    ...  Run IPMI Standard Command  dcmi get_mc_id_string

    # Extract management controller ID from cmd_output.
    ${initial_mc_id}=  Fetch From Right  ${cmd_output}  :${SPACE}

    # Set the management controller ID string to other value.
    # Example:
    # Set Management Controller Identifier String Command: HOST

    Set Management Controller ID String  ${new_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${new_mc_id}

    # Set the value back to the initial value and verify.
    Set Management Controller ID String  ${initial_mc_id}

    # Get the management controller ID and verify.
    Get Management Controller ID String And Verify  ${initial_mc_id}


Test Management Controller ID String Status via IPMI
    [Documentation]  Test management controller ID string status via IPMI.
    [Tags]  Test_Management_Controller_ID_String_Status_via_IPMI
    # Disable management controller ID string status via IPMI and verify.
    Run IPMI Standard Command  dcmi set_conf_param dhcp_config 0x00
    Verify Management Controller ID String Status  disable

    # Enable management controller ID string status via IPMI and verify.
    Run IPMI Standard Command  dcmi set_conf_param dhcp_config 0x01
    Verify Management Controller ID String Status  enable


Test Management Controller ID String Status via Raw IPMI
    [Documentation]  Test management controller ID string status via IPMI.
    [Tags]  Test_Management_Controller_ID_String_Status_via_Raw_IPMI
    # Disable management controller ID string status via raw IPMI and verify.
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['conf_param']['Disabled'][0]}
    Verify Management Controller ID String Status  disable

    # Enable management controller ID string status via raw IPMI and verify.
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['conf_param']['Enabled'][0]}
    Verify Management Controller ID String Status  enable


*** Keywords ***

Set Management Controller ID String
    [Documentation]  Set the management controller ID string.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID String to be set

    ${set_mc_id_string}=  Run IPMI Standard Command
    ...  dcmi set_mc_id_string ${string}


Get Management Controller ID String And Verify
    [Documentation]  Get the management controller ID string.
    [Arguments]  ${string}

    # Description of argument(s):
    # string  Management Controller ID string

    ${get_mc_id}=  Run IPMI Standard Command  dcmi get_mc_id_string
    Should Contain  ${get_mc_id}  ${string}
    ...  msg=Command failed: get_mc_id.


Verify Management Controller ID String Status
    [Documentation]  Verify management controller ID string status via IPMI.
    [Arguments]  ${status}

    # Example of dcmi get_conf_param command output:
    # DHCP Discovery method   :
    #           Management Controller ID String is disabled
    #           Vendor class identifier DCMI IANA and Vendor class-specific Informationa are disabled
    #   Initial timeout interval        : 4 seconds
    #   Server contact timeout interval : 120 seconds
    #   Server contact retry interval   : 64 seconds

    ${resp}=  Run IPMI Standard Command  dcmi get_conf_param
    ${resp}=  Get Lines Containing String  ${resp}
    ...  Management Controller ID String  case_insensitive=True
    Should Contain  ${resp}  ${status}
    ...  msg=Management controller ID string is not ${status}
