*** Settings ***

Documentation    VMI certificate exchange tests.

Library          ../../lib/jobs_processing.py
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/utils.robot

Suite Setup       Suite Setup Execution
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Suite Teardown Execution


*** Variables ***

# users           User Name               password
@{ADMIN}          admin_user              TestPwd123
@{OPERATOR}       operator_user           TestPwd123
@{ReadOnly}       readonly_user           TestPwd123
@{NoAccess}       noaccess_user           TestPwd123
&{USERS}          Administrator=${ADMIN}  Operator=${OPERATOR}  ReadOnly=${ReadOnly}
...               NoAccess=${NoAccess}
${VMI_BASE_URI}   /ibm/v1/


*** Test Cases ***

Get CSR Request Signed By VMI And Verify
    [Documentation]  Get CSR request signed by VMI using different user roles and verify.
    [Tags]  Get_CSR_Request_Signed_By_VMI_And_Verify
    [Template]  Get Certificate Signed By VMI

    # username           password             force_create  valid_csr  valid_status_code
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${True}    ${HTTP_OK}

    # Send CSR request from operator user.
    operator_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Send CSR request from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Send CSR request from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}


Get Root Certificate Using Different Privilege Users Roles
    [Documentation]  Get root certificate using different users.
    [Tags]  Get_Root_Certificate_Using_Different_Users
    [Template]  Get Root Certificate

    # username     password    force_create  valid_csr  valid_status_code
    # Request root certificate from admin user.
    admin_user     TestPwd123  ${True}       ${True}    ${HTTP_OK}

    # Request root certificate from operator user.
    operator_user  TestPwd123  ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from ReadOnly user.
    readonly_user  TestPwd123  ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from NoAccess user.
    noaccess_user  TestPwd123  ${False}      ${True}    ${HTTP_FORBIDDEN}


Send CSR Request When VMI Is Off And Verify
    [Documentation]  Send CSR signing request to VMI when it is off and expect an error.
    [Tags]  Get_CSR_Request_When_VMI_Is_Off_And_verify
    [Setup]  Redfish Power Off
    [Teardown]  Run keywords  Redfish Power On  stack_mode=skip  AND  FFDC On Test Case Fail
    [Template]  Get Certificate Signed By VMI

    # username           password             force_create  valid_csr  valid_status_code         read_timeout
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${True}    ${HTTP_SERVICE_UNAVAILABLE}   60

    # Send CSR request from operator user.
    operator_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Send CSR request from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Send CSR request from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

Get Corrupted CSR Request Signed By VMI And Verify
    [Documentation]  Send corrupted CSR for signing and expect an error.
    [Tags]  Get_Corrupted_CSR_Request_Signed_By_VMI_And_Verify
    [Template]  Get Certificate Signed By VMI

    # username           password             force_create  valid_csr   valid_status_code        read_timeout
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${False}    ${HTTP_SERVICE_UNAVAILABLE}    60

    # Send CSR request from operator user.
    operator_user        TestPwd123           ${False}      ${False}    ${HTTP_FORBIDDEN}

    # Send CSR request from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${False}    ${HTTP_FORBIDDEN}

    # Send CSR request from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${False}    ${HTTP_FORBIDDEN}

Get Root Certificate When VMI Is Off And Verify
    [Documentation]  Get root certificate when vmi is off and verify.
    [Tags]  Get_Root_Certificate_When_VMI_Is_Off_And_Verify
    [Setup]  Redfish Power Off
    [Teardown]  Run keywords  Redfish Power On  stack_mode=skip  AND  FFDC On Test Case Fail
    [Template]  Get Root Certificate

    # username           password             force_create  valid_csr  valid_status_code
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${True}       ${True}    ${HTTP_OK}

    # Request root certificate from operator user.
    operator_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from ReadOnly user.
    readonly_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from NoAccess user.
    noaccess_user        TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}


Get Root Certificate After BMC Reboot And Verify
    [Documentation]  Get root certificate after bmc reboot and verify.
    [Tags]  Get_Root_Certificate_After_BMC_Reboot_And_Verify
    [Setup]  Run Keywords  OBMC Reboot (off)  AND  Redfish Power On
    [Template]  Get Root Certificate

    # username            password             force_create  valid_csr  valid_status_code
    ${OPENBMC_USERNAME}   ${OPENBMC_PASSWORD}  ${True}       ${True}    ${HTTP_OK}

    # Request root certificate from operator user.
    operator_user         TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from ReadOnly user.
    readonly_user         TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

    # Request root certificate from NoAccess user.
    noaccess_user         TestPwd123           ${False}      ${True}    ${HTTP_FORBIDDEN}

Get Concurrent Root Certificate Requests From Multiple Admin Users
    [Documentation]  Get multiple concurrent root certificate requests from multiple admins
    ...  and verify no errors.
    [Tags]  Get_Concurrent_Root_Certificate_Requests_From_Multiple_Admin_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent CSR Requests From Multiple Admin Users
    [Documentation]  Get multiple concurrent csr requests from multiple admins and verify no errors.
    [Tags]  Get_Concurrent_CSR_Requests_From_Multiple_Admin_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent Corrupted CSR Requests From Multiple Admin Users
    [Documentation]  Get multiple concurrent corrupted csr requests from multiple admins and verify no errors.
    [Tags]  Get_Concurrent_Corrupted_CSR_Requests_From_Multiple_Admin_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent Root Certificate Request From Operator Users
    [Documentation]  Get multiple concurrent root certificate from non admin users and verify no errors.
    [Tags]  Get_Concurrent_Root_Certificate_Request_From_Operator_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent Root Certificate Request From Admin And Non Admin Users
    [Documentation]  Get multiple concurrent root certificate from admin and non admin users
    ...  and verify no errors.
    [Tags]  Get_Concurrent_Root_Certificate_Request_From_Admin_And_Non_Admin_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent Root Certificate Request From Different Non Admin Users
    [Documentation]  Get multiple concurrent root certificate from different non admin users
    ...  and verify no errors.
    [Tags]  Get_Concurrent_Root_Certificate_Request_From_Different_Non_Admin_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate noaccess_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent CSR Request From Operator Users
    [Documentation]  Get multiple concurrent csr request from non admin users and verify no errors.
    [Tags]  Get_Concurrent_CSR_Request_From_Operator_Users

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate And Send CSR Request Concurrently And Verify
    [Documentation]  Get root certificate and send csr request concurrently and
    ...  verify gets root and signed certificate.
    [Tags]  Get_Root_Certificate_And_Send_CSR_Request_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Concurrent Root Certificate And Send CSR Request And Verify
    [Documentation]  Get concurrent root certificate and send csr request
    ...  and verify gets root certificate and signed certificate.
    [Tags]  Get_Concurrent_Root_Certificate_And_Send_CSR_Request_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate And Send Multiple CSR Requests Concurrently And Verify
    [Documentation]  Get root certificate and send multiple csr requests concurrently and
    ...  verify gets root certificate and signed certificates.
    [Tags]  Get_Root_Certificate_And_Send_Multiple_CSR_Requests_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate And Send Multiple Corrupted CSR Requests Concurrently And Verify
    [Documentation]  Get root certificate and send multiple corrupted csr requests concurrently and
    ...  verify gets root certificate and error for corrupted csr requests.
    [Tags]  Get_Root_Certificate_And_Send_Multiple_Corrupted_CSR_Requests_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send Concurrent CSR Request And Corrupted CSR Request And Verify
    [Documentation]  Send concurrent csr request and corrupted csr request
    ...  and verify gets certificate for valid csr and error for corrupted csr.
    [Tags]  Send_Concurrent_CSR_Request_And_Corrupted_CSR_Request_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate Send CSR And Corrupted CSR Request Concurrently And Verify
    [Documentation]  Get root certificate send csr and corrupted csr requests concurrently and
    ...  verify gets root certificate and certificate for valid csr and error for corrupted csr.
    [Tags]  Get_Root_Certificate_Send_CSR_And_Corrupted_CSR_Request_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send Concurrent CSR Request From Admin And Non Admin Users And Verify
    [Documentation]  Send concurrent csr requests from admin and non-admin users and verify
    ...  admin gets certificate and non-admin gets error.
    [Tags]  Send_Concurrent_CSR_Request_From_Admin_And_Non_Admin_Users_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send Concurrent CSR Request From Non Admin Users And Verify
    [Documentation]  Send concurrent csr request from non admin users
    ...  and verify gets error.
    [Tags]  Send_Concurrent_CSR_Request_From_Non_Admin_Users_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI noaccess_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate And Send Corrupted CSR From Admin CSR Request From Operator Concurrently
    [Documentation]  Get root certificate and send corrupted csr request from admin and
    ...  csr from operator concurrently and verify gets root certificate and errors for corrupted
    ...  and for operator.
    [Tags]  Get_Root_Certificate_And_Send_Corrupted_CSR_From_Admin_CSR_Request_From_Operator_Concurrently

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate From Operator And Send Corrupted CSR Request And CSR Request From Admin Concurrently
    [Documentation]  Get root certificate from operator and send corrupted csr request
    ...  and csr from admin and verify errors for operator and corrupted csr and signed certificate
    ...  for valid csr.
    [Tags]  Get_Root_Certificate_From_Operator_And_Send_Corrupted_CSR_Request_And_CSR_Request_From_Admin_Concurrently

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END


Get Root Certificate From Operator And Admin Send CSR Request From Admin Concurrently
    [Documentation]  Get root certificate from operator and admin and
    ...  and send csr request from admin concurrently and verify error for operator
    ...  and admin gets root and signed certificate.
    [Tags]  Get_Root_Certificate_From_Operator_And_Admin_Send_CSR_Request_From_Admin_Concurrently

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send CSR Request From Admin And Operator And Corrupted CSR From Admin Concurrently And Verify
    [Documentation]  Send csr request from admin and operator and corrupted
    ...  csr request from admin and verify gets signed certificate for valid csr for admin
    ...  gets error for operator and error for corrupted csr.
    [Tags]  Send_CSR_Request_From_Admin_And_Operator_And_Corrupted_CSR_From_Admin_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send Corrupted CSR Requests From Admin And Operator And CSR Request From Admin Concurrently And Verify
    [Documentation]  Send corrupted csr request from admin and operator and csr request
    ...  from admin concurrently and verify errors for corrupted csr and gets signed certificate
    ...  for valid csr from admin.
    [Tags]  Send_Corrupted_CSR_Requests_From_Admin_And_Operator_And_CSR_Request_From_Admin_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${False} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send Corrupted CSR Requests From Admin And Operator User Concurrently And Verify
    [Documentation]  Send corrupted csr requests from admin and operator and
    ...  verify gets error.
    [Tags]  Send_Corrupted_CSR_Requests_From_Admin_And_Operator_User_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${False} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate From Admin And Send CSR Requests From Non Admin Concurrently And Verify
    [Documentation]  Get root certificate from admin and csr requests from
    ...  non admin users concurrently and verify gets root certificate for admin and
    ...  errors for non-admins.
    [Tags]  Get_Root_Certificate_From_Admin_And_Send_CSR_Requests_From_Non_Admin_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate And Send CSR Requests From Non Admin Users Concurrently And Verify
    [Documentation]  Get root certificate and send csr requests from non admin
    ...  users and verify gets errors.
    [Tags]  Get_Root_Certificate_And_Send_CSR_Requests_From_Non_Admin_Users_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Root Certificate readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI noaccess_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send Corrupted CSR Request From Admin And CSR Requests From Non Admin Concurrently And Verify
    [Documentation]  Send corrupted csr request from admin and csr request from non admin
    ...  users concurrently and verify gets errors.
    [Tags]  Send_Corrupted_CSR_Request_From_Admin_And_CSR_Requests_From_Non_Admin_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Send CSR Request And Corrupted CSR Requests From Non Admin Users Concurrently And Verify
    [Documentation]  Send csr and corrupted csr request from non admin users
    ...  and verify gets errors.
    [Tags]  Send_CSR_Request_And_Corrupted_CSR_Requests_From_Non_Admin_Users_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${False} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${False} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI noaccess_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        ...  Get Certificate Signed By VMI readonly_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

Get Root Certificate And Send CSR Requests From Admin And Operator Concurrently And Verify
    [Documentation]  Get root certificate from admin and send csr requests
    ...  from admin and operator concurrently and verify gets root certificate
    ...  and signed certificate and gets error for operator.
    [Tags]  Get_Root_Certificate_And_Send_CSR_Requests_From_Admin_And_Operator_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${True} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END


Get Root Certificate And Send Corrupted CSR Requests From Admin And Operator Concurrently And Verify
    [Documentation]  Get root certificate from admin and send corrupted csr requests
    ...  from admin and operator concurrently and verify gets root certificate and errors
    ...  for corrupted csr.
    [Tags]  Get_Root_Certificate_And_Send_Corrupted_CSR_Requests_From_Admin_And_Operator_Concurrently_And_Verify

    FOR  ${i}  IN RANGE  ${5}
        ${dict}=  Execute Process Multi Keyword  ${5}
        ...  Get Root Certificate ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${True} ${HTTP_OK}
        ...  Get Certificate Signed By VMI ${OPENBMC_USERNAME} ${OPENBMC_PASSWORD} ${True} ${False} ${HTTP_INTERNAL_SERVER_ERROR}
        ...  Get Certificate Signed By VMI operator_user TestPwd123 ${True} ${False} ${HTTP_FORBIDDEN}
        Dictionary Should Not Contain Value  ${dict}  False
        ...  msg=One or more operations has failed.
    END

*** Keywords ***

Generate CSR String
    [Documentation]  Generate a csr string.

    # Note: Generates and returns csr string.
    ${csr_gen_time} =  Get Current Date Time
    ${CSR_FILE}=  Catenate  SEPARATOR=_  ${csr_gen_time}  csr_server.csr
    ${CSR_KEY}=   Catenate  SEPARATOR=_  ${csr_gen_time}  csr_server.key
    Set Test Variable  ${CSR_FILE}
    Set Test Variable  ${CSR_KEY}
    ${ssl_cmd}=  Set Variable  openssl req -new -newkey rsa:2048 -nodes -keyout ${CSR_KEY} -out ${CSR_FILE}
    ${ssl_sub}=  Set Variable
    ...  -subj "/C=XY/ST=Abcd/L=Efgh/O=ABC/OU=Systems/CN=abc.com/emailAddress=xyz@xx.ABC.com"

    # Run openssl command to create a new private key and use that to generate a CSR string
    # in server.csr file.
    ${output}=  Run  ${ssl_cmd} ${ssl_sub}
    ${csr}=  OperatingSystem.Get File  ${CSR_FILE}

    [Return]  ${csr}


Send CSR To VMI And Get Signed
    [Documentation]  Upload CSR to VMI and get signed.
    [Arguments]  ${csr}  ${force_create}  ${username}  ${password}  ${read_timeout}

    # Description of argument(s):
    # csr                    Certificate request from client to VMI.
    # force_create           Create a new REST session if True.
    # username               Username to create a REST session.
    # password               Password to create a REST session.

    Run Keyword If  "${XAUTH_TOKEN}" != "${EMPTY}" or ${force_create} == ${True}
    ...  Initialize OpenBMC  rest_username=${username}  rest_password=${password}

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    ...  Content-Type=application/json

    ${cert_uri}=  Set Variable  ${VMI_BASE_URI}Host/Actions/SignCSR

    # For SignCSR request, we need to pass CSR string generated by openssl command.
    ${csr_data}=  Create Dictionary  CsrString  ${csr}
    Set To Dictionary  ${data}  data  ${csr_data}

    ${resp}=  Post Request  openbmc  ${cert_uri}  &{data}  headers=${headers}  timeout=${read_timeout}
    Log to console  ${resp.content}

    [Return]  ${resp}


Get Root Certificate
    [Documentation]  Get root certificate from VMI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}
    ...  ${force_create}=${False}  ${valid_csr}=${True}  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # cert_type          Type of the certificate requesting. eg. root or SignCSR.
    # username           Username to create a REST session.
    # password           Password to create a REST session.
    # force_create       Create a new REST session if True.
    # valid_csr          Uses valid CSR string in the REST request if True.
    #                    This is not applicable for root certificate.
    # valid_status_code  Expected status code from REST request.

    Run Keyword If  "${XAUTH_TOKEN}" != "${EMPTY}" or ${force_create} == ${True}
    ...  Initialize OpenBMC  rest_username=${username}  rest_password=${password}

    ${data}=  Create Dictionary
    ${headers}=  Create Dictionary  X-Auth-Token=${XAUTH_TOKEN}
    ...  Content-Type=application/json

    ${cert_uri}=  Set Variable  ${VMI_BASE_URI}Host/Certificate/root

    ${resp}=  Get Request  openbmc  ${cert_uri}  &{data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${valid_status_code}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}

    ${cert}=  Evaluate  json.loads('''${resp.text}''', strict=False)  json
    Should Contain  ${cert["Certificate"]}  BEGIN CERTIFICATE
    Should Contain  ${cert["Certificate"]}  END CERTIFICATE


Get Subject
    [Documentation]  Generate a csr string.
    [Arguments]  ${file_name}  ${is_csr_file}

    # Description of argument(s):
    # file_name          Name of CSR or signed CERT file.
    # is_csr_file        A True value means a CSR while a False is for signed CERT file.

    ${subject}=  Run Keyword If  ${is_csr_file}  Run  openssl req -in ${file_name} -text -noout | grep Subject:
    ...   ELSE  Run  openssl x509 -in ${file_name} -text -noout | grep Subject:

    [Return]  ${subject}


Get Public Key
    [Documentation]  Generate a csr string.
    [Arguments]  ${file_name}  ${is_csr_file}

    # Description of argument(s):
    # file_name          Name of CSR or CERT file.
    # is_csr_file        A True value means a CSR while a False is for signed CERT file.

    ${PublicKey}=  Run Keyword If  ${is_csr_file}  Run  openssl req -in ${file_name} -noout -pubkey
    ...   ELSE  Run  openssl x509 -in ${file_name} -noout -pubkey

    [Return]  ${PublicKey}


Get Certificate Signed By VMI
    [Documentation]  Get signed certificate from VMI.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}
    ...  ${force_create}=${False}  ${valid_csr}=${True}  ${valid_status_code}=${HTTP_OK}
    ...  ${read_timeout}=20

    # Description of argument(s):
    # cert_type          Type of the certificate requesting. eg. root or SignCSR.
    # username           Username to create a REST session.
    # password           Password to create a REST session.
    # force_create       Create a new REST session if True.
    # valid_csr          Uses valid CSR string in the REST request if True.
    #                    This is not applicable for root certificate.
    # valid_status_code  Expected status code from REST request.

    Set Test Variable  ${CSR}  CSR
    Set Test Variable  ${CORRUPTED_CSR}  CORRUPTED_CSR

    ${CSR}=  Generate CSR String
    ${csr_left}  ${csr_right}=  Split String From Right  ${CSR}  ==  1
    ${CORRUPTED_CSR}=  Catenate  SEPARATOR=  ${csr_left}  \N  ${csr_right}

    # For SignCSR request, we need to pass CSR string generated by openssl command
    ${csr_str}=  Set Variable If  ${valid_csr} == ${True}  ${CSR}  ${CORRUPTED_CSR}

    ${resp}=  Send CSR To VMI And Get Signed  ${csr_str}  ${force_create}  ${username}  ${password}
    ...  ${read_timeout}

    Should Be Equal As Strings  ${resp.status_code}  ${valid_status_code}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}

    ${cert}=  Evaluate  json.loads('''${resp.text}''', strict=False)  json
    Should Contain  ${cert["Certificate"]}  BEGIN CERTIFICATE
    Should Contain  ${cert["Certificate"]}  END CERTIFICATE

    # Now do subject and public key verification
    ${subject_csr}=  Get Subject  ${CSR_FILE}  True
    ${pubKey_csr}=  Get Public Key  ${CSR_FILE}  True

    # create a crt file with certificate string
    ${signed_cert}=  Set Variable  ${cert["Certificate"]}
    ${testcert_gen_time} =  Get Current Date Time
    ${test_cert_file}=   Catenate  SEPARATOR=_  ${testcert_gen_time}  test_certificate.cert

    Create File  ${test_cert_file}  ${signed_cert}
    ${subject_signed_csr}=  Get Subject   ${test_cert_file}  False
    ${pubKey_signed_csr}=  Get Public Key  ${test_cert_file}  False

    Should be equal as strings    ${subject_signed_csr}    ${subject_csr}
    Should be equal as strings    ${pubKey_signed_csr}     ${pubKey_csr}


Suite Setup Execution
    [Documentation]  Suite setup execution.

    Remove Files  *.csr  *.key  *.cert
    # Create different user accounts.
    Redfish.Login
    Redfish Power On
    Create Users With Different Roles  users=${USERS}  force=${True}


Suite Teardown Execution
    [Documentation]  Suite teardown execution.

    Remove Files  *.csr  *.key  *.cert
    Delete BMC Users Via Redfish  users=${USERS}
    Delete All Sessions
    Redfish.Logout
