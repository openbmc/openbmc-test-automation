#!/usr/bin/python

r"""
Contains PLDM-related constants.
"""


PLDM_TYPE_BASE = {'CODE': '00', 'TYPE': 'base'}
PLDM_TYPE_PLATFORM = {'CODE': '02', 'TYPE': 'platform'}
PLDM_TYPE_BIOS = {'CODE': '03', 'TYPE': 'bios'}
PLDM_TYPE_FRU = {'CODE': '04', 'TYPE': 'fru'}
PLDM_TYPE_OEM = {'CODE': '3F', 'TYPE': 'oem'}

VERSION_BASE = {'CODE': ['f1', 'f0', 'f0', '00'], 'TYPE': '1.0.0'}
VERSION_PLATFORM = {'CODE': ['f1', 'f0', 'f0', '00'], 'TYPE': '1.1.1'}
VERSION_BIOS = {'CODE': ['f1', 'f1', 'f1', '00'], 'TYPE': '1.0.0'}
VERSION_FRU = {'CODE': ['f1', 'f0', 'f0', '00'], 'TYPE': '1.0.0'}

PLDM_BASE_CMD = {
    'GET_TID': '02',
    'GET_PLDM_VERSION': '03',
    'GET_PLDM_TYPES': '04',
    'GET_PLDM_COMMANDS': '05'}

PLDM_SUCCESS = '00'
PLDM_ERROR = '01'
PLDM_ERROR_INVALID_DATA = '02'
PLDM_ERROR_INVALID_LENGTH = '03'
PLDM_ERROR_NOT_READY = '04'
PLDM_ERROR_UNSUPPORTED_PLDM_CMD = '05'
PLDM_ERROR_INVALID_PLDM_TYPE = '20'

BIOS_TABLE_UNAVAILABLE = '83'
INVALID_BIOS_TABLE_DATA_INTEGRITY_CHECK = '84'
INVALID_BIOS_TABLE_TYPE = '85'

PLDM_BIOS_CMD = {
    'GET_BIOS_TABLE': '01',
    'SET_BIOS_ATTRIBUTE_CURRENT_VALUE': '07',
    'GET_BIOS_ATTRIBUTE_CURRENT_VALUE_BY_HANDLE': '08',
    'GET_DATE_TIME': '0c'}

PLDM_BIOS_TABLE_TYPES = {
    'STRING_TABLE': '00',
    'ATTRIBUTE_TABLE': '01',
    'ATTRIBUTE_VAL_TABLE': '02'}

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


PLDM_FRU_CMD = {
    'PLDM_GET_FRU_RECORD_TABLE_METADATA': '01',
    'PLDM_GET_FRU_RECORD_TABLE': '02'}


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


PLDM_RAW_CMD_PAYLOAD_DATA = {
    'GetPLDMVersion_BASE': ' 0x00 0x00 0x00 0x00 0x01 0x00',
    'GetPLDMVersion_PLATFORM': ' 0x00 0x00 0x00 0x00 0x01 0x02',
    'GetPLDMVersion_BIOS': ' 0x00 0x00 0x00 0x00 0x01 0x03',
    'GetPLDMVersion_FRU': ' 0x00 0x00 0x00 0x00 0x01 0x04'}
