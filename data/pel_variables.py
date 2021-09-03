#!/usr/bin/env python3

r"""
Contains PEL related constants.
"""

PEL_DETAILS = {
    'CreatorID': 'BMC',
    'CompID': '0x1000',
    'Subsystem': 'BMC Firmware',
    'Message': 'An application had an internal failure',
    'SRC': 'BD8D1002',
    'Sev': 'Unrecoverable Error'}

ERROR_LOG_CREATE_BASE_CMD = 'busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging \
    xyz.openbmc_project.Logging.Create Create ssa{ss} '

CMD_INTERNAL_FAILURE = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Common.Error.InternalFailure \
    xyz.openbmc_project.Logging.Entry.Level.Error 0'

CMD_FRU_CALLOUT = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Common.Error.Timeout \
    xyz.openbmc_project.Logging.Entry.Level.Error 2 "TIMEOUT_IN_MSEC" "5" "CALLOUT_INVENTORY_PATH" \
    "/xyz/openbmc_project/inventory/system/chassis/motherboard"'

CMD_PROCEDURAL_SYMBOLIC_FRU_CALLOUT = ERROR_LOG_CREATE_BASE_CMD + 'org.open_power.Logging.Error.TestError1 \
    xyz.openbmc_project.Logging.Entry.Level.Error 0'

CMD_INFORMATIONAL_ERROR = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Common.Error.TestError2 \
    xyz.openbmc_project.Logging.Entry.Level.Informational 0'

CMD_INVENTORY_PREFIX = 'busctl get-property xyz.openbmc_project.Inventory.Manager \
    /xyz/openbmc_project/inventory/system/chassis/motherboard'

CMD_UNRECOVERABLE_ERROR = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Common.Error.InternalFailure \
    xyz.openbmc_project.Logging.Entry.Level.Error 0'

CMD_PREDICTIVE_ERROR = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Common.Error.InternalFailure \
    xyz.openbmc_project.Logging.Entry.Level.Warning 0'

CMD_UNRECOVERABLE_HOST_ERROR = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Host.Error.Event \
    xyz.openbmc_project.Logging.Entry.Level.Error 1 RAWPEL /tmp/FILE_NBMC_UNRECOVERABLE'

CMD_INFORMATIONAL_HOST_ERROR = ERROR_LOG_CREATE_BASE_CMD + 'xyz.openbmc_project.Host.Error.Event \
    xyz.openbmc_project.Logging.Entry.Level.Error 1 RAWPEL /tmp/FILE_HOST_INFORMATIONAL'
