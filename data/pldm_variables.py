#!/usr/bin/python

r"""
Contains PLDM-related constants.
"""

PLDM_SUPPORTED_TYPES = ['base', 'platform', 'bios']

# PLDM types.
PLDM_TYPE_BASE = {'VALUE': '00', 'STRING': 'base'}
PLDM_TYPE_PLATFORM = {'VALUE': '02', 'STRING': 'platform'}
PLDM_TYPE_BIOS = {'VALUE': '03', 'STRING': 'bios'}
PLDM_TYPE_FRU = {'VALUE': '04', 'STRING': 'fru'}
PLDM_TYPE_OEM = {'VALUE': '3F', 'STRING': 'oem'}

VERSION_BASE = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}
VERSION_PLATFORM = {'VALUE': ['f1', 'f2', 'f0', '00'], 'STRING': '1.2.0'}
VERSION_BIOS = {'VALUE': ['f1', 'f1', 'f1', '00'], 'STRING': '1.0.0'}
VERSION_FRU = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}

# PLDM base related variables.
PLDM_BASE_CMD = {
    'GET_TID': '02',
    'GET_PLDM_VERSION': '03',
    'GET_PLDM_TYPES': '04',
    'GET_PLDM_COMMANDS': '05'}

# Response lengths are inclusive of completion code.
GET_TID_RESP_BYTES = 2
GET_PLDM_VERSION_RESP_BYTES = 10
GET_PLDM_TYPES_RESP_BYTES = 9
GET_PLDM_COMMANDS_RESP_BYTES = 33

# PLDM bios related variables.
PLDM_BIOS_CMD = {
    'GET_BIOS_TABLE': '01',
    'SET_BIOS_ATTRIBUTE_CURRENT_VALUE': '07',
    'GET_BIOS_ATTRIBUTE_CURRENT_VALUE_BY_HANDLE': '08',
    'GET_DATE_TIME': '0c'}

PLDM_BIOS_TABLE_TYPES = {
    'STRING_TABLE': '00',
    'ATTRIBUTE_TABLE': '01',
    'ATTRIBUTE_VAL_TABLE': '02'}

TRANSFER_OPERATION_FLAG = {
    'GETNEXTPART': '00',
    'GETFIRSTPART': '01'}

TRANSFER_RESP_FLAG = {
    'PLDM_START': '01',
    'PLDM_MIDDLE': '02',
    'PLDM_END': '04',
    'PLDM_START_AND_END': '05'}

# PLDM platform related variables.
PLDM_PLATFORM_CMD = {
    'SET_STATE_EFFECTER_STATES': '39',
    'GET_PDR': '51'}

PLDM_PDR_TYPES = {
    'STATE_EFFECTER_PDR': '11'}

# PLDM OEM related variables.
PLDM_FILEIO_CMD = {
    'GET_FILE_TABLE': '1',
    'READ_FILE': '4',
    'WRITE_FILE': '5',
    'READ_FILE_INTO_MEMORY': '6',
    'WRITE_FILE_FROM_MEMORY': '7'}

PLDM_FILEIO_COMPLETION_CODES = {
    'INVALID_FILE_HANDLE': '80',
    'DATA_OUT_OF_RANGE': '81',
    'INVALID_READ_LENGTH': '82',
    'INVALID_WRITE_LENGTH': '83',
    'FILE_TABLE_UNAVAILABLE': '84',
    'INVALID_FILE_TABLE_TYPE': '85'}

# PLDM FRU related variables.
PLDM_FRU_CMD = {
    'PLDM_GET_FRU_RECORD_TABLE_METADATA': '01',
    'PLDM_GET_FRU_RECORD_TABLE': '02'}

# PLDM command format.

'''
e.g. : GetPLDMVersion usage

pldmtool base GetPLDMVersion -t <pldm_type>

pldm supported types

base->0,platform->2,bios->3,fru->4

'''
CMD_GETPLDMVERSION = 'base GetPLDMVersion -t %s'

'''
e.g. : PLDM raw command usage

pldmtool raw -d 0x80 0x00 0x03 0x00 0x00 0x00 0x00 0x01 0x00

pldm raw -d 0x<header> 0x<pldm_type> 0x<pldm_cmd_type> 0x<payload_data>
'''

CMD_PLDMTOOL_RAW = 'raw -d 0x80' + '0x%s' + ' ' + '0x%s'


# PLDM command payload data.

PAYLOAD_GetPLDMVersion = \
    ' 0x00 0x00 0x00 0x00 0x%s 0x%s'    # %(TransferOperationFlag, PLDMType)


'''
e.g. : SetDateTime usage

pldmtool bios SetDateTime -d <YYYYMMDDHHMMSS>

'''
CMD_SETDATETIME = 'bios SetDateTime -d %s'


CMD_GETPDR = 'platform GetPDR -d %s'

'''
e.g. : SetStateEffecterStates usage

pldmtool platform GetPDR -d <effecterID, requestSet, effecterState>

pldmtool platform SetStateEffecterStates -d 1 1 1

'''

CMD_SETSTATEEFFECTERSTATES = 'platform SetStateEffecterStates -d %s'

# GetPDR parsed response message for record handle.
# Dictionary value array holds the expected output for record handle 1, 2.
# e.g. : 'nextrecordhandle': ['0', '2']
#
# Note :
#      Record handle - 0 is default &  has same behaviour as record handle 1
#      Only record handle 0, 1, 2 are supported as of now.

RESPONSE_DICT_GETPDR = {
    'nextrecordhandle': ['0', '2'],
    'responsecount': ['29', '30'],
    'recordhandle': ['1', '2'],
    'pdrheaderversion': ['1'],
    'pdrtype': ['11'],
    'recordchangenumber': ['0'],
    'datalength': ['19', '20'],
    'pldmterminushandle': ['0'],
    'effecterid': ['1', '2'],
    'entitytype': ['33', '45'],
    'entityinstancenumber': ['0'],
    'containerid': ['0'],
    'effectersemanticid': ['0'],
    'effecterinit': ['0'],
    'effecterdescriptionpdr': ['false'],
    'compositeeffectercount': ['1'],
    'statesetid': ['196', '260'],
    'possiblestatessize': ['1', '2'],
    'possiblestates': ['6', '0']}

RESPONSE_DICT_GETBIOSTABLE_STRTABLE = {
    'biosstringhandle': ['BIOSString'],
    '0': ['Allowed'],
    '1': ['Disabled'],
    '2': ['Enabled'],
    '3': ['Not Allowed'],
    '4': ['Perm'],
    '5': ['Temp'],
    '6': ['pvm-fw-boot-side'],
    '7': ['pvm-inband-code-update'],
    '8': ['pvm-os-boot-side'],
    '9': ['pvm-pcie-error-inject'],
    '10': ['pvm-surveillance'],
    '11': ['pvm-system-name'],
    '12': ['vmi-if-count']}
