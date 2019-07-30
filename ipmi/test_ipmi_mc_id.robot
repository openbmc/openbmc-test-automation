*** Settings ***

Documentation    Module to test IPMI management controller ID functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Get And Set Management Controller ID String
    [Documentation]  Verify get and set management controller ID string.
    [Tags]  Verify_Get_And_Set_Management_Controller_ID_String
    # Get the value of the managemment controller ID string.
    # Example:
    # Get Management Controller Identifier String: witherspoon

    ${cmd_output}=  Run IPMI Standard Command  dcmi get_mc_id_string

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

