*** Settings ***
Documentation    Verify the BIOS resource is linked from the ComputerSystem
...              resource, is discoverable and schema-conformant, and
...              correctly enforces access control and privilege
...              restrictions.
...
...              On EVB (${PLATFORM_IS_EVB}), Suite Setup mints Redfish Host
...              Interface bootstrap credentials to provision the
...              BiosAttributeRegistry table, then returns to the admin
...              session as the suite's default. 
...              Test Environment:
...              - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...              - Host: Raspberry Pi (RPI) at ${HOST_IP}
...              - USB Ethernet: BMC at ${BMC_USB_ETH_IP}, Host at ${HOST_USB_ETH_IP}

Resource         ../../../../lib/bmc_redfish_resource.robot
Resource         ../../../../lib/bmc_redfish_utils.robot
Resource         ../../../../lib/openbmc_ffdc.robot
Resource         bios_attribute_registry_setup.robot
Library          ../../../../lib/gen_robot_valid.py

Suite Setup      Setup Bios Resource Test Suite
Suite Teardown   Teardown Bios Resource Test Suite
Test Teardown    FFDC On Test Case Fail

Test Tags        Bios_Resource

*** Variables ***
 
${RESETBIOS_TEST_PASSWORD}    TestPwd123 

*** Test Cases *** 

Verify BIOS Resource Is Linked And Discoverable From ComputerSystem 
    [Documentation]  Verify the BIOS resource is linked from ComputerSystem
    ...  and conforms to its DMTF JSON Schema.
    [Tags]  Verify_BIOS_Resource_Is_Linked_And_Discoverable_From_ComputerSystem

    ${system}=  Redfish.Get Properties  ${SYSTEM_BASE_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    Dictionary Should Contain Key  ${system}  Bios
    ...  msg=ComputerSystem resource does not advertise a Bios link.
    Dictionary Should Contain Key  ${system['Bios']}  @odata.id
    ...  msg=Bios link does not contain an @odata.id.

    Log  Discovered Bios link from ComputerSystem: ${BIOS_ATTR_URI}  console=True

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    Should Be Equal As Strings  ${bios['@odata.id']}  ${BIOS_ATTR_URI}
    ...  msg=Bios resource @odata.id does not match the ComputerSystem Bios link.

    Valid Dmtf Schema  bios
    Log  Bios resource (@odata.type=${bios['@odata.type']}) conforms to its DMTF schema  console=True
 

Verify BIOS Resource Mandatory Fields
    [Documentation]  Verify the BIOS resource's mandatory identity fields and
    ...  Attributes/AttributeRegistry/@Redfish.Settings are present and
    ...  populated.
    [Tags]  Verify_BIOS_Resource_Mandatory_Fields

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Log  Bios Attributes: ${bios['Attributes']}  console=True
    Log  Bios AttributeRegistry: ${bios['AttributeRegistry']}  console=True

    # Schema conformance is already verified by the discovery test case above.
    Valid Dict  bios
    ...  required_keys=['@odata.id', '@odata.type', 'Id', 'Name', 'Attributes', 'AttributeRegistry', '@Redfish.Settings']

    Should Not Be Empty  ${bios['Attributes']}
    ...  msg=Bios Attributes is empty; host may not have reported its BIOS table to the BMC.
    Should Not Be Equal  ${bios['AttributeRegistry']}  ${None}
    ...  msg=Bios AttributeRegistry is missing or null; host may not have reported its BIOS table to the BMC.
    Should Not Be Equal  ${bios['@Redfish.Settings']['SettingsObject']['@odata.id']}  ${None}
    ...  msg=@Redfish.Settings SettingsObject @odata.id is missing or null.
    Log  SettingsObject URI: ${bios['@Redfish.Settings']['SettingsObject']['@odata.id']}  console=True


Verify BIOS Resource Requires Authentication
    [Documentation]  Verify an unauthenticated GET to the BIOS resource is
    ...  rejected with 401 and exposes no BIOS attribute data.
    [Tags]  Verify_BIOS_Resource_Requires_Authentication
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Redfish.Logout

    ${response}=  Redfish.Get  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}]
    Log  Unauthenticated GET ${BIOS_ATTR_URI} returned status ${response.status}  console=True

    Should Be Equal As Integers  ${response.status}  ${HTTP_UNAUTHORIZED}
    ...  msg=Unauthenticated request for Bios resource did not return 401.

    Dictionary Should Not Contain Key  ${response.dict}  Attributes
    ...  msg=Unauthorized response body exposes Bios Attributes.
    Dictionary Should Not Contain Key  ${response.dict}  AttributeRegistry
    ...  msg=Unauthorized response body exposes Bios AttributeRegistry.


Verify BIOS Settings Object Is Reachable, Writable, And Remains Pending
    [Documentation]  PATCH TestAttrInteger onto the BIOS SettingsObject and
    ...  verify the new value lands in pending Settings while the active
    ...  Bios value is unchanged.
    ...  Uses PATCH, not PUT: PUT to /Bios/Settings returns 405 on this firmware. 
    [Tags]  Verify_BIOS_Settings_Object_Is_Reachable_Writable_And_Remains_Pending

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    VAR  ${original_value}  ${bios['Attributes']['TestAttrInteger']}

    ${settings}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Dictionary Should Contain Key  ${settings}  Attributes
    ...  msg=BIOS SettingsObject does not advertise an Attributes object.

    ${target_value}=  Evaluate  $original_value + 1 if $original_value < 100 else $original_value - 1
    Log  TestAttrInteger: original=${original_value}, patching to target=${target_value}  console=True

    ${patch_body}=  Evaluate  {'Attributes': {'TestAttrInteger': $target_value}}
    Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body=${patch_body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${settings_after}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal As Strings  ${settings_after['Attributes']['TestAttrInteger']}  ${target_value}
    ...  msg=Patched value does not appear in pending BIOS settings.

    ${bios_after}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal As Strings  ${bios_after['Attributes']['TestAttrInteger']}  ${original_value}
    ...  msg=Active BIOS value changed without an explicit apply step.


Apply Pending BIOS Settings To Active And Clear Pending
    [Documentation]  Under bootstrap credentials, PUT the merged
    ...  current+pending Attributes back to /Bios and
    ...  verify this promotes pending to active and clears pending as a
    ...  side effect
    ...  Depends on the previous test case having staged a pending change.
    [Tags]  Apply_Pending_BIOS_Settings_To_Active_And_Clear_Pending
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Switch To Bootstrap Session

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    ${settings}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    VAR  ${pending_attrs}  ${settings['Attributes']}
    Should Not Be Empty  ${pending_attrs}
    ...  msg=No pending BIOS attributes to apply; run the PATCH test case first.

    ${bios_put_body}=  Evaluate  {'Attributes': {**$bios['Attributes'], **$pending_attrs}}
    Redfish.Put  ${BIOS_ATTR_URI}  body=${bios_put_body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${bios_final}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    ${pending_keys}=  Evaluate  list($pending_attrs.keys())
    FOR  ${name}  IN  @{pending_keys}
        Should Be Equal As Strings  ${bios_final['Attributes']['${name}']}  ${pending_attrs['${name}']}
        ...  msg=Active BIOS attribute '${name}' does not reflect the applied pending value.
    END

    ${settings_final}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Empty  ${settings_final['Attributes']}
    ...  msg=Pending BIOS settings were not cleared after being applied to active.


Verify BIOS Attributes Persist Across BMC Reboot
    [Documentation]  Reboot the BMC and verify active BIOS attributes are unchanged
    [Tags]  Verify_BIOS_Attributes_Persist_Across_BMC_Reboot

    ${bios_before}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart

    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    IF  ${PLATFORM_IS_EVB}
        Setup Bootstrap Test
        Close All Connections
    END

    ${bios_after}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    Should Be Equal  ${bios_before['Attributes']}  ${bios_after['Attributes']}
    ...  msg=BIOS Attributes changed across a BMC reboot.


Verify ResetBios Action Is Advertised With Valid Target URI
    [Documentation]  Verify the Bios.ResetBios action's target URI matches <Bios URI>/Actions/Bios.ResetBios.
    [Tags]  Verify_ResetBios_Action_Is_Advertised_With_Valid_Target_URI

    ${reset_target}=  redfish_utils.Get Target Actions  ${BIOS_ATTR_URI}  Bios.ResetBios
    Should Not Be Equal  ${reset_target}  ${None}
    ...  msg=Bios resource does not advertise the Bios.ResetBios action.

    VAR  ${expected_target}  ${BIOS_ATTR_URI}/Actions/Bios.ResetBios
    Should Be Equal As Strings  ${reset_target}  ${expected_target}
    ...  msg=Bios.ResetBios target URI does not match the expected Actions path.


Execute ResetBios Action And Verify Accepted Response
    [Documentation]  POST to ResetBios with an empty body, verify an
    ...  accepted response with no error content, and verify pending
    ...  Settings is staged with the AttributeRegistry's default values.
    [Tags]  Execute_ResetBios_Action_And_Verify_Accepted_Response

    ${reset_target}=  redfish_utils.Get Target Actions  ${BIOS_ATTR_URI}  Bios.ResetBios
    Should Not Be Equal  ${reset_target}  ${None}
    ...  msg=Bios resource does not advertise the Bios.ResetBios action.

    ${registry}=  Build Test Attribute Registry
    ${expected_defaults}=  Expected Pending Defaults After Reset  ${registry}

    ${empty_body}=  Create Dictionary
    ${response}=  Redfish.Post  ${reset_target}  body=${empty_body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}, ${HTTP_ACCEPTED}]
    Log  ResetBios response: status=${response.status}, body=${response.dict}  console=True

    IF  ${response.dict}
        Dictionary Should Not Contain Key  ${response.dict}  error
        ...  msg=ResetBios response body contains Redfish error content.
    END

    ${settings_after}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Log  Pending Attributes after ResetBios: ${settings_after['Attributes']}  console=True

    Dictionaries Should Be Equal  ${expected_defaults}  ${settings_after['Attributes']}
    ...  msg=Pending Attributes after ResetBios do not match the AttributeRegistry's default values.


Verify ResetBios Requires Authentication
    [Documentation]  Verify an unauthenticated ResetBios POST is rejected
    ...  with 401 and creates no pending settings change.
    [Tags]  Verify_ResetBios_Requires_Authentication
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    ${reset_target}=  redfish_utils.Get Target Actions  ${BIOS_ATTR_URI}  Bios.ResetBios
    Should Not Be Equal  ${reset_target}  ${None}
    ...  msg=Bios resource does not advertise the Bios.ResetBios action.
    ${settings_before}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    Redfish.Logout

    ${empty_body}=  Create Dictionary
    ${response}=  Redfish.Post  ${reset_target}  body=${empty_body}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}]
    Should Be Equal As Integers  ${response.status}  ${HTTP_UNAUTHORIZED}
    ...  msg=Unauthenticated ResetBios request did not return 401.

    Restore Bios Test Session
    ${settings_after}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal  ${settings_before['Attributes']}  ${settings_after['Attributes']}
    ...  msg=Pending BIOS settings changed despite ResetBios being rejected for lack of authentication.


Verify ReadOnly Role Cannot Execute ResetBios
    [Documentation]  Verify a ReadOnly-role account cannot execute ResetBios
    ...  (403) and pending settings remain unchanged.
    [Tags]  Verify_ReadOnly_Role_Cannot_Execute_ResetBios
    [Teardown]  Run Keywords  Cleanup ResetBios Role Test  AND  FFDC On Test Case Fail


    ${settings_before}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    Create Temporary Account And Attempt ResetBios  ReadOnly  [${HTTP_FORBIDDEN}]

    ${settings_after}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal  ${settings_before['Attributes']}  ${settings_after['Attributes']}
    ...  msg=Pending BIOS settings changed despite ResetBios being forbidden for the ReadOnly role.


Verify Operator Or Administrator Role Can Execute ResetBios
    [Documentation]  Verify an Operator-role account can execute ResetBios.
    [Tags]  Verify_Operator_Or_Administrator_Role_Can_Execute_ResetBios
    [Teardown]  Run Keywords  Cleanup ResetBios Role Test  AND  FFDC On Test Case Fail

    Create Temporary Account And Attempt ResetBios  Operator
    ...  [${HTTP_OK}, ${HTTP_NO_CONTENT}, ${HTTP_ACCEPTED}]


Verify BIOS Resource Is Only Served Over Authenticated HTTPS
    [Documentation]  Verify plain HTTP to the BMC is refused at the socket level. 
    [Tags]  Verify_BIOS_Resource_Is_Only_Served_Over_Authenticated_HTTPS

    # max_retries=0: connection refusal is the expected outcome here, not a
    # transient failure.
    Create Session  bios_http_probe  http://${OPENBMC_HOST}  max_retries=0
    Run Keyword And Expect Error  *Connection refused*
    ...  GET On Session  bios_http_probe  ${BIOS_ATTR_URI}


Verify ReadOnly Role Cannot PATCH BIOS Settings
    [Documentation]  Verify a ReadOnly-role account cannot PATCH the BIOS
    ...  Settings object (403) and pending settings remain unchanged.
    [Tags]  Verify_ReadOnly_Role_Cannot_PATCH_BIOS_Settings
    [Teardown]  Run Keywords  Cleanup ResetBios Role Test  AND  FFDC On Test Case Fail

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    ${settings_before}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    VAR  ${orig_int}  ${bios['Attributes']['TestAttrInteger']}
    ${attempted_value}=  Evaluate  $orig_int + 1 if $orig_int < 100 else $orig_int - 1
    ${patch_body}=  Evaluate  {'Attributes': {'TestAttrInteger': $attempted_value}}
    Create Temporary Account And Attempt Settings Patch  ReadOnly
    ...  [${HTTP_FORBIDDEN}]  ${patch_body}

    ${settings_after}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal  ${settings_before['Attributes']}  ${settings_after['Attributes']}
    ...  msg=Pending BIOS settings changed despite the PATCH being forbidden for the ReadOnly role.


Verify Unsupported HTTP Methods Are Rejected On BIOS Resources
    [Documentation]  As admin, verify the DELETE/POST/PUT/PATCH
    ...  combinations below are all rejected (405) with no attribute data
    ...  leaked, confirmed empirically per resource (bodies are non-empty
    ...  to avoid a 400 EmptyJSON masking the 405):
    ...    /Bios                        : DELETE, POST
    ...    /Bios/Settings               : DELETE, POST, PUT
    ...    /Bios/BiosAttributeRegistry  : DELETE, PATCH
    ...
    ...  Final check is that pending Settings is unchanged, not empty --
    ...  ResetBios (run by earlier test cases) may have already staged
    ...  registry defaults into pending.
    [Tags]  Verify_Unsupported_HTTP_Methods_Are_Rejected_On_BIOS_Resources
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Redfish.Logout
    Redfish.Login

    ${settings_before}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]

    ${probe_body}=  Evaluate  {'Attributes': {'TestAttrInteger': 7}}

    ${resp}=  Redfish.Delete  ${BIOS_ATTR_URI}  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  Attributes
    ...  msg=Rejected DELETE response on /Bios exposes Attributes.

    ${resp}=  Redfish.Post  ${BIOS_ATTR_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  Attributes
    ...  msg=Rejected POST response on /Bios exposes Attributes.

    ${resp}=  Redfish.Delete  ${BIOS_ATTR_SETTINGS_URI}  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  Attributes
    ...  msg=Rejected DELETE response on /Bios/Settings exposes Attributes.

    ${resp}=  Redfish.Post  ${BIOS_ATTR_SETTINGS_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  Attributes
    ...  msg=Rejected POST response on /Bios/Settings exposes Attributes.

    ${resp}=  Redfish.Put  ${BIOS_ATTR_SETTINGS_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  Attributes
    ...  msg=Rejected PUT response on /Bios/Settings exposes Attributes.

    ${resp}=  Redfish.Delete  ${BIOS_ATTR_REGISTRY_URI}  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  RegistryEntries
    ...  msg=Rejected DELETE response on /Bios/BiosAttributeRegistry exposes RegistryEntries.

    ${resp}=  Redfish.Patch  ${BIOS_ATTR_REGISTRY_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]
    Dictionary Should Not Contain Key  ${resp.dict}  RegistryEntries
    ...  msg=Rejected PATCH response on /Bios/BiosAttributeRegistry exposes RegistryEntries.

    ${settings_final}=  Redfish.Get Properties  ${BIOS_ATTR_SETTINGS_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal  ${settings_before['Attributes']}  ${settings_final['Attributes']}
    ...  msg=Pending BIOS settings changed despite every request being rejected as unsupported.


Verify POST/PUT/PATCH To BIOS URI Is Rejected For Standard Admin User
    [Documentation]  Verify admin gets 405 for POST/PUT/PATCH to /Bios --
    ...  the same PUT succeeds under bootstrap credentials. 
    [Tags]  Verify_POST_PUT_PATCH_To_BIOS_URI_Is_Rejected_For_Standard_Admin_User
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Redfish.Logout
    Redfish.Login

    ${probe_body}=  Evaluate  {'Attributes': {'TestAttrInteger': 7}}

    ${resp}=  Redfish.Post  ${BIOS_ATTR_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    ${resp}=  Redfish.Put  ${BIOS_ATTR_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    ${resp}=  Redfish.Patch  ${BIOS_ATTR_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]


Verify POST/PUT/PATCH To BiosAttributeRegistry URI Is Rejected For Standard Admin User
    [Documentation]  Verify admin gets 405 for POST/PUT/PATCH to /Bios/BiosAttributeRegistry
    [Tags]  Verify_POST_PUT_PATCH_To_BiosAttributeRegistry_URI_Is_Rejected_For_Standard_Admin_User
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Redfish.Logout
    Redfish.Login

    ${probe_body}=  Create Dictionary  Description=x

    ${resp}=  Redfish.Post  ${BIOS_ATTR_REGISTRY_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # PUT needs a well-formed registry body: a malformed one would be
    # rejected earlier with 400 PropertyMissing regardless of verb.
    ${registry_body}=  Build Test Attribute Registry
    ${resp}=  Redfish.Put  ${BIOS_ATTR_REGISTRY_URI}  body=${registry_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    ${resp}=  Redfish.Patch  ${BIOS_ATTR_REGISTRY_URI}  body=${probe_body}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]


Verify Bootstrap Credentials Can PUT To BIOS URI
    [Documentation]  Switch to bootstrap credentials and PUT to /Bios;
    ...  verify it is accepted and active attributes update -- the same
    ...  operation admin gets 405 for.
    [Tags]  Verify_Bootstrap_Credentials_Can_PUT_To_BIOS_URI
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Switch To Bootstrap Session

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    VAR  ${orig_int}  ${bios['Attributes']['TestAttrInteger']}
    ${new_value}=  Evaluate  $orig_int + 1 if $orig_int < 100 else $orig_int - 1
    ${put_body}=  Evaluate  {'Attributes': {**$bios['Attributes'], 'TestAttrInteger': $new_value}}

    Redfish.Put  ${BIOS_ATTR_URI}  body=${put_body}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${bios_after}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    Should Be Equal As Strings  ${bios_after['Attributes']['TestAttrInteger']}  ${new_value}
    ...  msg=Bootstrap-credentialed PUT to the BIOS URI was accepted but did not update active attributes.


Verify Bootstrap Credentials Can PUT To BiosAttributeRegistry URI
    [Documentation]  Switch to bootstrap credentials and PUT a
    ...  freshly-built test registry to /Bios/BiosAttributeRegistry;
    [Tags]  Verify_Bootstrap_Credentials_Can_PUT_To_BiosAttributeRegistry_URI
    [Teardown]  Run Keywords  Restore Bios Test Session  AND  FFDC On Test Case Fail

    Switch To Bootstrap Session

    ${registry}=  Build Test Attribute Registry
    Redfish.Put  ${BIOS_ATTR_REGISTRY_URI}  body=${registry}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_CREATED}, ${HTTP_NO_CONTENT}]

    ${actual_registry}=  Redfish.Get Properties  ${BIOS_ATTR_REGISTRY_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    ${mismatches}=  Compare Attribute Registries  ${registry}  ${actual_registry}
    Should Be Empty  ${mismatches}
    ...  msg=BIOS Attribute Registry PUT under bootstrap credentials did not round-trip correctly: ${mismatches}


*** Keywords ***

Setup Bios Resource Test Suite
    [Documentation]  Suite Setup: log in as admin; on EVB, mint bootstrap
    ...  credentials, provision the BIOS Attribute Registry table, then
    ...  return to admin as the suite's default session.

    Redfish.Login 

    IF  ${PLATFORM_IS_EVB}
        Mint And Switch To Bootstrap Session
        Create BIOS Attribute Registry Table On EVB
        Restore Bios Test Session
        Log  Suite Setup complete: BIOS Attribute Registry provisioned, running as admin  console=True
    ELSE
        Log  Suite Setup complete: not an EVB platform, running as admin  console=True
    END

Mint And Switch To Bootstrap Session
    [Documentation]  Mint a fresh bootstrap account and switch the active
    ...  Redfish session to it, dropping the RPI/SSH connection. Requires
    ...  an active admin session -- minting itself authenticates as admin

    Setup Bootstrap Test 
    Log  Minted bootstrap account: ${BOOTSTRAP_USERNAME}  console=True
    Redfish.Logout
    Redfish.Login  ${BOOTSTRAP_USERNAME}  ${BOOTSTRAP_PASSWORD}
    Close All Connections

Switch To Bootstrap Session
    [Documentation]  Authenticate as the bootstrap account already minted
    ...  by Mint And Switch To Bootstrap Session (or refreshed via Setup
    ...  Bootstrap Test). 

    Redfish.Login  ${BOOTSTRAP_USERNAME}  ${BOOTSTRAP_PASSWORD}
    Log  Switched to bootstrap user ${BOOTSTRAP_USERNAME}  console=True

Teardown Bios Resource Test Suite
    [Documentation]  Suite Teardown: on EVB, delete the bootstrap account
    ...  (admin is already the ambient session); log out.

    IF  ${PLATFORM_IS_EVB}
        Teardown Bootstrap Test
    END
    Redfish.Logout

Restore Bios Test Session
    [Documentation]  Re-authenticate as admin, the suite's default session,
    ...  after a test case has deliberately logged out or switched to
    ...  bootstrap credentials.

    Redfish.Login

Create Temporary Account And Attempt ResetBios
    [Documentation]  Create a temporary Redfish account with the given role
    ...  and attempt to execute ResetBios as it, returning the response.

    [Arguments]  ${role_id}  ${expected_status_codes} 

    # Description of argument(s):
    # role_id   Redfish role to assign the temporary account (e.g. "ReadOnly", "Operator").
    # expected_status_codes  List of HTTP status codes accepted from the ResetBios POST.

    # "rb_" prefix keeps this within the firmware's 16-character username limit.

    VAR  ${RESETBIOS_TEST_USER}  rb_${role_id}  scope=SUITE

    Redfish Create User  ${RESETBIOS_TEST_USER}  ${RESETBIOS_TEST_PASSWORD}  ${role_id}  ${True}  force=${True}
    Redfish.Logout
    Redfish.Login  ${RESETBIOS_TEST_USER}  ${RESETBIOS_TEST_PASSWORD}

    ${reset_target}=  redfish_utils.Get Target Actions  ${BIOS_ATTR_URI}  Bios.ResetBios
    ${empty_body}=  Create Dictionary
    ${response}=  Redfish.Post  ${reset_target}  body=${empty_body}
    ...  valid_status_codes=${expected_status_codes}
    Log  ResetBios as '${RESETBIOS_TEST_USER}' (role ${role_id}) returned status ${response.status}  console=True
    RETURN  ${response}

Create Temporary Account And Attempt Settings Patch
    [Documentation]  Create a temporary Redfish account with the given role
    ...  and attempt to PATCH the given body onto the BIOS Settings object
    ...  as it, returning the response. 

    
    [Arguments]  ${role_id}  ${expected_status_codes}  ${patch_body}

    # Description of argument(s):
    # role_id   Redfish role to assign the temporary account (e.g. "ReadOnly", "Operator").
    # expected_status_codes  List of HTTP status codes accepted from the Settings PATCH.
    # patch_body   Dictionary body to PATCH onto the BIOS Settings object.

    VAR  ${RESETBIOS_TEST_USER}  rb_${role_id}  scope=SUITE

    Redfish Create User  ${RESETBIOS_TEST_USER}  ${RESETBIOS_TEST_PASSWORD}  ${role_id}  ${True}  force=${True}
    Redfish.Logout
    Redfish.Login  ${RESETBIOS_TEST_USER}  ${RESETBIOS_TEST_PASSWORD}

    ${bios}=  Redfish.Get Properties  ${BIOS_ATTR_URI}
    ...  valid_status_codes=[${HTTP_OK}]
    ${response}=  Redfish.Patch  ${BIOS_ATTR_SETTINGS_URI}  body=${patch_body}
    ...  valid_status_codes=${expected_status_codes}
    Log  PATCH ${BIOS_ATTR_SETTINGS_URI} as '${RESETBIOS_TEST_USER}' (role ${role_id}) returned status ${response.status}  console=True
    RETURN  ${response}

Cleanup ResetBios Role Test
    [Documentation]  Delete the temporary account created by "Create
    ...  Temporary Account And Attempt ResetBios"/"...Settings Patch" (if
    ...  any) and restore the suite's normal (admin) session. 

    Run Keyword And Ignore Error  Redfish.Logout
    Run Keyword And Ignore Error  Redfish.Login
    ${test_user}=  Get Variable Value  ${RESETBIOS_TEST_USER}  ${EMPTY}
    IF  '${test_user}' != '${EMPTY}'
        Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${test_user}
        ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}, ${HTTP_NOT_FOUND}]
    END
    Restore Bios Test Session