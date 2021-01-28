Redfish Request Via mTLS
=========================

When the BMC only enables mTLS type for authentication. Redfish request in robot
test should be tested normally.

## Required environment variables in Robot

  -  **MTLS_ENABLED** indicates whether mTLS is enabled in BMC.
       False by default:

        ```
            ${MTLS_ENABLED}        False
        ```

  -  **VALID_CERT** indicates valid mTLS certificate for authentication.
       When a redfish request doesn't specify a certificate, it will be the
       default certificate.

        ```
            ${VALID_CERT}        ${EMPTY}
        ```

  -  **CERT_DIR_PATH** indicates path of mTLS certificates directory:

        ```
            ${CERT_DIR_PATH}        ${EMPTY}
        ```
## How to send a redfish request with certificate

- When a redfish request is executed, it will be executed through the python
   library **requests** with certificate. It supports for all Redfish REST
   requests (get, head, post, put, patch, delete):

   ```
        import requests

        cert_dict = kwargs.pop('certificate', {"certificate_name":VALID_CERT})
        response = requests.get(
                    url='https://'+ host + args[0],
                    cert=CERT_DIR_PATH + '/' + cert_dict['certificate_name'],
                    verify=False,
                    headers={"Cache-Control": "no-cache"})
   ```

- Original robot code of redfish request doesn’t need to modify. It will send
   the request with the default certificate ${VALID_CERT}.

- The example provides Redfish request to use different certificate in the
  Robot code below:

    ```
    ${certificate_dict}=  Create Dictionary  certificate_name=${CERT}
    Redfish.Get  ${VALID_URL}  certificate=&{certificate_dict}
    ...  valid_status_codes=[${HTTP_OK}]
    ```

## Test Cases for mTLS authentication

mTLS authentication is only a means to connect to the BMC, not for testing
purposes. Therefore, some test cases need to write a new one to match it for
mTLS authentication. (Requires test certificates with different privileges or
user name) Some cases don’t need to be tested because the purpose of
them are inapplicable to mTLS. Example cases are as follows:

- **Create_IPMI_User_And_Verify_Login_Via_Redfish**

    In this case, it uses IPMI to create a random user with password and
    privilege, and then verify login via Redfish. Next, it logout the default
    user and then login with the user just created by the IPMI. However,
    it does not need to use mTLS to authenticate login and logout.
    It can be replaced as follows: Prepare a certificate with user name
    "admin_user" in advance. Use IPMI to create a user named admin_user then
    verify via a valid Redfish request with admin_user certificate.

- **Attempt_Login_With_Expired_Session**

    Most cases related to session are inapplicable to mTLS. Because a Redfish
    request don't need to create a session first. So there is no need to test
    those cases when mTLS is enabled.
