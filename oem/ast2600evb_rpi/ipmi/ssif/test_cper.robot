*** Settings ***
Documentation  CPER (Common Platform Error Record) injection test cases for AST2600 EVB+RPI setup.
...
...  Iterates over all *.cperhex files in data/cper/, injects each one into the
...  BMC via the SSIF IPMI Group Extension command (NetFn 0x2C Cmd 0x01
...  GroupExt 0xAE), verifies that a new entry appears in the Redfish CPER log
...  service, and validates that the downloaded CPER attachment matches the
...  original hex file data byte-for-byte.
...
...  Test Environment:
...  - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...  - Host: Raspberry Pi (RPI) at ${HOST_IP}

Library         OperatingSystem
Library         Process
Resource        ../../resource.resource

Suite Setup     Redfish.Login
Suite Teardown  Suite Teardown Execution
Test Teardown   FFDC On Test Case Fail

Test Tags  EVB_RPI

*** Variables ***
# Absolute path to the directory containing *.cperhex test data files.
${CPER_DATA_DIR}    ${EXECDIR}${/}data${/}cper
# CPER hex files to inject, one per loop iteration.
@{CPER_FILES}
...    cxlcomponent-media.cperhex
...    dmargeneric.cperhex
...    firmware.cperhex

*** Test Cases ***

Inject All CPER Records And Verify Log Entries
    [Documentation]  Loop over all CPER hex files (cxlcomponent-media, dmargeneric,
    ...  firmware), inject each one into the BMC via SSIF IPMI raw command
    ...  (NetFn 0x2C Cmd 0x01 GroupExt 0xAE), verify that a new Redfish CPER log
    ...  entry is created for each injection, and validate that the downloaded
    ...  CPER attachment matches the original hex file data byte-for-byte.
    [Tags]  Inject_All_CPER_Records_And_Verify_Log_Entries
    [Setup]  Setup Host SSH Only
    [Teardown]  Close All Connections

    FOR  ${filename}  IN  @{CPER_FILES}
        Log  \n=== Injecting CPER record: ${filename} ===  console=True
        Inject CPER And Verify  ${filename}
    END


*** Keywords ***

Get CPER Entries
    [Documentation]  Return the Members list from the Redfish CPER LogService Entries collection.

    ${resp}=  Redfish.Get  ${CPER_ENTRIES_URI}
    RETURN  ${resp.dict.get('Members', [])}


Get CPER Entry Count
    [Documentation]  Return the current number of entries in the Redfish CPER LogService.

    ${members}=  Get CPER Entries
    ${count}=  Get Length  ${members}
    RETURN  ${count}


Verify CPER Attachment
    [Documentation]  Download the CPER attachment for ${entry_id} from the Redfish LogService
    ...  using curl on the test PC, decode the base64 response, and compare it byte-for-byte
    ...  with the original hex-encoded file at ${local_hex_file}.
    ...  The downloaded base64 file is saved to ${EXECDIR}/logs with the entry Id in the
    ...  filename for post-run debugging.
    [Arguments]  ${entry_id}  ${local_hex_file}

    # Description of argument(s):
    # entry_id        Redfish CPER log entry Id (e.g. "6") used to construct the attachment URL.
    # local_hex_file  Local path to the original hex-encoded CPER data file for comparison.

    # Download the Redfish attachment (base64-encoded) to the log directory.
    VAR  ${log_dir}  ${EXECDIR}/logs
    Create Directory  ${log_dir}
    VAR  ${b64_local_file}  ${log_dir}/cper_downloaded_${entry_id}.b64
    VAR  ${attachment_url}
    ...  https://${OPENBMC_HOST}:${HTTPS_PORT}${CPER_ENTRIES_URI}/${entry_id}/attachment
    ${result}=  Run Process  curl  -sk  -u  ${OPENBMC_USERNAME}:${OPENBMC_PASSWORD}
    ...  ${attachment_url}  -o  ${b64_local_file}
    Should Be Equal As Integers  ${result.rc}  0
    ...  msg=curl download of CPER attachment failed for entry ${entry_id} (rc=${result.rc}): ${result.stderr}
    Log  Downloaded base64 attachment to ${b64_local_file} (logs dir).

    # Verify the downloaded base64 file is non-empty.
    ${b64_size}=  Get File Size  ${b64_local_file}
    Should Be True  ${b64_size} > 0
    ...  msg=Downloaded base64 attachment is empty (0 bytes) for entry ${entry_id}.
    Log  Downloaded base64 file size: ${b64_size} bytes (${b64_local_file}).

    # Decode base64 attachment and compare byte-for-byte with original hex data.
    # bytes.fromhex strips whitespace and converts the continuous hex string to bytes.
    ${match}=  Evaluate
    ...  bytes.fromhex(''.join(open(r'${local_hex_file}').read().split())) == __import__('base64').b64decode(open(r'${b64_local_file}','rb').read())
    Should Be True  ${match}
    ...  msg=Decoded CPER attachment does not match original data for entry ${entry_id}.
    Log  CPER attachment for entry ${entry_id} matches original data. Verification passed.
    Log  Debug file retained in logs dir: ${b64_local_file} (raw b64).


Convert Hex File To IPMI Args
    [Documentation]  Read a .cperhex file from ${CPER_DATA_DIR} and convert its
    ...  contents to a space-separated list of 0x-prefixed byte tokens suitable
    ...  for passing directly to ipmitool raw, e.g. "0xAB 0xCD 0xEF ...".
    ...  All whitespace (newlines, carriage returns, spaces) is stripped before
    ...  splitting into 2-character byte pairs.
    [Arguments]    ${filename}

    ${raw}=  OperatingSystem.Get File  ${CPER_DATA_DIR}${/}${filename}
    ${clean}=  Replace String Using Regexp
    ...  ${raw}
    ...  \s+
    ...
    ${clean}=  Replace String Using Regexp
    ...  ${clean}
    ...  \n+
    ...
    ${byte_count}=  Evaluate  len("${clean}") // 2
    @{bytes}=  Create List
    FOR  ${i}  IN RANGE  0  ${byte_count}
        ${start}=  Evaluate  ${i} * 2
        ${byte}=  Get Substring  ${clean}  ${start}  ${start+2}
        Append To List  ${bytes}  0x${byte}
    END
    ${hex_args}=  Catenate  SEPARATOR=${SPACE}  @{bytes}
    Log  ${filename}: ${byte_count} bytes
    RETURN  ${hex_args}


Inject CPER And Verify
    [Documentation]  Inject a CPER record from the given hex file via SSIF IPMI
    ...  raw command, verify that a new entry appears in the Redfish CPER log
    ...  service, and validate that the downloaded CPER attachment matches the
    ...  original hex file data byte-for-byte.
    [Arguments]  ${filename}

    # Description of argument(s):
    # filename  Base name of the .cperhex file under ${CPER_DATA_DIR}.

    # Snapshot entry count and URIs before injection.
    ${count_before}=  Get CPER Entry Count
    ${entries_before}=  Get CPER Entries
    Log  CPER entries before injecting ${filename}: ${count_before}.

    # Read hex file and derive ipmitool args.
    ${hex_args}=  Convert Hex File To IPMI Args  ${filename}

    # Inject via SSIF IPMI raw command and assert success.
    # NetFn 0x2C = Group Extension, Cmd 0x01, GroupExt 0xAE = CPER.
    ${output}  ${rc}=  Execute Command
    ...  sudo ipmitool raw ${IPMI_RAW_CMD}[ssif_send_platform_error_record][Send][0] ${hex_args}
    ...  return_stdout=True  return_rc=True
    Should Be Equal As Integers  ${rc}  0
    ...  msg=ipmitool CPER injection failed (rc=${rc}) for ${filename}: ${output}
    Log  ipmitool output for ${filename}: ${output}

    # Verify a new entry appeared in the CPER log.
    ${entries}=  Get CPER Entries
    ${count_after}=  Get CPER Entry Count
    Should Be True  ${count_after}== ${count_before}+1
    ...  msg=No new CPER entry appeared after injecting ${filename} (before=${count_before}, after=${count_after}).

    # Inspect the most recently added entry.
    VAR  ${last_uri}  ${entries[-1]['@odata.id']}
    ${resp}=  Redfish.Get  ${last_uri}
    VAR  ${entry}  ${resp.dict}
    VAR  ${entry_id}  ${entry['Id']}

    # Verify all expected metadata fields are present.
    Dictionary Should Contain Key  ${entry}  Id
    Dictionary Should Contain Key  ${entry}  Name
    Dictionary Should Contain Key  ${entry}  EntryType
    Dictionary Should Contain Key  ${entry}  @odata.type
    Dictionary Should Contain Key  ${entry}  AdditionalDataURI
    Dictionary Should Contain Key  ${entry}  DiagnosticDataType

    # Verify specific field values.
    Should Not Be Empty  ${entry_id}
    ...  msg=[${filename}] Entry Id is empty.
    Should Be Equal As Strings  ${entry['EntryType']}  Event
    ...  msg=[${filename}] Expected EntryType=Event, got ${entry['EntryType']}.
    Should Be Equal As Strings  ${entry['Name']}  System CPER
    ...  msg=[${filename}] Expected Name=System CPER, got ${entry['Name']}.
    Should Be Equal As Strings  ${entry['DiagnosticDataType']}  CPER
    ...  msg=[${filename}] Expected DiagnosticDataType=CPER, got ${entry['DiagnosticDataType']}.
    VAR  ${expected_attachment_uri}  ${CPER_ENTRIES_URI}/${entry_id}/attachment
    Should Be Equal As Strings  ${entry['AdditionalDataURI']}  ${expected_attachment_uri}
    ...  msg=[${filename}] Expected AdditionalDataURI=${expected_attachment_uri}, got ${entry['AdditionalDataURI']}.

    # Log all verified field values.
    Log  [${filename}] Entry Id: ${entry_id}
    Log  [${filename}] Entry Name: ${entry['Name']}
    Log  [${filename}] Entry EntryType: ${entry['EntryType']}
    Log  [${filename}] Entry @odata.type: ${entry['@odata.type']}
    Log  [${filename}] Entry AdditionalDataURI: ${entry['AdditionalDataURI']}
    Log  [${filename}] Entry DiagnosticDataType: ${entry['DiagnosticDataType']}

    Verify CPER Attachment  ${entry_id}  ${CPER_DATA_DIR}${/}${filename}
