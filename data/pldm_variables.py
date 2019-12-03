#!/usr/bin/python

r"""
Contains PLDM-related constants.
"""

# PLDM types.
PLDM_TYPE_BASE = {'VALUE': '00', 'STRING': 'base'}
PLDM_TYPE_PLATFORM = {'VALUE': '02', 'STRING': 'platform'}
PLDM_TYPE_BIOS = {'VALUE': '03', 'STRING': 'bios'}
PLDM_TYPE_FRU = {'VALUE': '04', 'STRING': 'fru'}
PLDM_TYPE_OEM = {'VALUE': '3F', 'STRING': 'oem'}

VERSION_BASE = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}
VERSION_PLATFORM = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.1.1'}
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

CMD_GETPLDMTYPES = 'pldmtool base GetPLDMTypes'

'''
e.g. : GetPLDMVersion usage

pldmtool base GetPLDMVersion -t <pldm_type>

pldm supported types

base->0,platform->2,bios->3,fru->4

'''
CMD_GETPLDMVERSION = 'pldmtool base GetPLDMVersion -t %s'

'''
e.g. : PLDM raw command usage

pldmtool raw -d 0x80 0x00 0x03 0x00 0x00 0x00 0x00 0x01 0x00

pldm raw -d 0x<header> 0x<pldm_type> 0x<pldm_cmd_type> 0x<payload_data>
'''

CMD_PLDMTOOL_RAW = 'pldmtool raw -d 0x80' + '0x%s' + ' ' + '0x%s'


# PLDM command payload data.

PAYLOAD_GetPLDMVersion = \
    ' 0x00 0x00 0x00 0x00 0x%s 0x%s'    # %(TransferOperationFlag, PLDMType)
