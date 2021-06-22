*** Settings ***
Documentation   This suite tests enablig of service user with a valid
...             ACF (Access Control File)

Resource        ../lib/connection_client.robot
Resource        ../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail

*** Variables ***



*** Test Cases ***


Verify service user availability
    [Documentation]  Verify service user avalability.

    # Use redfish API call with admin credetials
    # to iterate the local user list
    # Chcek service user availability  


Verify service user Login with Expired ACF 
    [Documentation]  Verify if service user can be logged when ACF is expired 
    [Setup]  Run Keywords  Upload ACF  ${EXPIRED_ACF}

    # Login with Redfish API after uploading
    Remove ACF

Verify enabling service user
    [Documentation]  Verify enabling service user after factory reset.
    [Setup]  Run Keywords  Upload ACF

    # Do ssh login with service user
    # Remove the acf file after test complete


*** Keywords ***


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login

Upload ACF
    [Documentation]  Upload ACF to BMC system with admin credetials.
    [Arguments]  ${file_path}  ${admin_user}  ${admin_password}

    # use scp or redfish API with admin credentials

