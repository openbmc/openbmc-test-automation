*** Settings ***
Documentation  Utilities for eSEL testing.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/utils.robot
Variables           ../data/variables.py


*** Variables ***

${RAW_PREFIX}       raw 0x3a 0xf0 0x

${RESERVE_ID}       raw 0x0a 0x42

${RAW_SUFFIX}       0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x00
...  0xdf 0x00 0x00 0x00 0x00 0x20 0x00 0x04 0x12 0x65 0x6f 0xaa 0x00 0x00

${RAW_SEL_COMMIT}   raw 0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20
...  0x00 0x04 0x12 0xA6 0x6f 0x02 0x00 0x01


*** Keywords ***

Create eSEL
    [Documentation]  Create an eSEL.
    Open Connection And Log In
    ${Resv_id}=  Run Inband IPMI Standard Command  ${RESERVE_ID}
    ${cmd}=  Catenate
    ...  ${RAW_PREFIX}${Resv_id.strip().rsplit(' ', 1)[0]}  ${RAW_SUFFIX}
    Run Inband IPMI Standard Command  ${cmd}
    Run Inband IPMI Standard Command  ${RAW_SEL_COMMIT}


Count eSEL Entries
    [Documentation]  Count eSEL entries logged.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    ${count}=  Get Length  ${jsondata["data"]}
    [Return]  ${count}


Verify eSEL Entries
    [Documentation]  Verify eSEL entries logged.
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    #  "data": {
    #       "AdditionalData": [
    #           "ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00 "
    #          ],
    #       "Id": 1,
    #       "Message": "org.open_power.Host.Error.Event",
    #       "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #       "Timestamp": 1485904869061
    # }
    ${entry_id}=  Read Attribute  ${elog_entry[0]}  Message
    Should Be Equal  ${entry_id}
    ...  org.open_power.Host.Error.Event

    ${entry_id}=  Read Attribute  ${elog_entry[0]}  Severity
    # Could be either xyz.openbmc_project.Logging.Entry.Level.Error
    # or xyz.openbmc_project.Logging.Entry.Level.Warning.
    Should Contain  ${entry_id}  xyz.openbmc_project.Logging.Entry.Level
