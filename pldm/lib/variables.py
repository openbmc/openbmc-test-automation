#!/usr/bin/python

r"""
Contains pldm related string constants applicable to all pldm functions.
"""


class pldm_variables():

    pldm_types = {
        PLDM_BASE: '00',
        PLDM_PLATFORM: '02',
        PLDM_BIOS: '03',
        PLDM_OEM: '3F'}


    pldm_commands = {
        PLDM_GET_TID: '2',
        PLDM_GET_PLDM_VERSION: '3',
        PLDM_GET_PLDM_TYPES: '4',
        PLDM_GET_PLDM_COMMANDS: '5'}

    pldm_completion_codes = {
        PLDM_SUCCESS: '00',
        PLDM_ERROR: '01',
        PLDM_ERROR_INVALID_DATA: '02',
        PLDM_ERROR_INVALID_LENGTH: '03',
        PLDM_ERROR_NOT_READY: '04',
        PLDM_ERROR_UNSUPPORTED_PLDM_CMD: '05',
        PLDM_ERROR_INVALID_PLDM_TYPE: '20'}


    #  pldm bios related variables.
    pldm_bios_completion_codes = {
        PLDM_BIOS_TABLE_UNAVAILABLE: '83',
        PLDM_INVALID_BIOS_TABLE_DATA_INTEGRITY_CHECK: '84',
        PLDM_INVALID_BIOS_TABLE_TYPE: '85'}

    pldm_bios_commands = {
        PLDM_GET_BIOS_TABLE: '01',
        PLDM_SET_BIOS_ATTRIBUTE_CURRENT_VALUE: '07',
        PLDM_GET_BIOS_ATTRIBUTE_CURRENT_VALUE_BY_HANDLE: '08',
        PLDM_GET_DATE_TIME: '0c'}

    # pldm platform related variables
    pldm_platform_commands = {
        PLDM_SET_STATE_EFFECTER_STATES: '39',
        PLDM_GET_PDR: '51'}

    pldm_pdr_types = {
        PLDM_STATE_EFFECTER_PDR = '11'}

    # pldm oem related variables.
    pldm_fileio_commands = {
        PLDM_GET_FILE_TABLE: '1',
        PLDM_READ_FILE: '4',
        PLDM_WRITE_FILE: '5',
        PLDM_READ_FILE_INTO_MEMORY: '6',
        PLDM_WRITE_FILE_FROM_MEMORY: '7'}

    pldm_fileio_completion_codes = {
        PLDM_INVALID_FILE_HANDLE: '80',
        PLDM_DATA_OUT_OF_RANGE: '81',
        PLDM_INVALID_READ_LENGTH: '82',
        PLDM_INVALID_WRITE_LENGTH: '83',
        PLDM_FILE_TABLE_UNAVAILABLE: '84',
        PLDM_INVALID_FILE_TABLE_TYPE: '85' }
