#!/usr/bin/env python

r"""
This module contains functions which pertain to firmware.
"""

import bmc_ssh_utils as bsu
import var_funcs as vf


def get_hard_disk_info(device="/dev/sdb"):
    r"""
    Get firmware information for the given device on the OS and return it as a
    dictionary.

    Description of argument(s):
    device                          The device to be passed to the hdparm and
                                    lsblk commands (e.g. "/dev/sdb").

    Example result:

    sda_info:
      [model_number]:                        MTFDDAK1T9TCB 00LY461 00LY570IBM
      [serial_number]:                       179C413F
      [firmware_revision]:                   MJ06
      [transport]:                           Serial, ATA8-AST, SATA 1.0a,
                                             SATA II Extensions,
                                             SATA Rev 2.5,
                                             SATA Rev 2.6, SATA Rev 3.0
      [used]:                                unknown (minor revision code 0x006d)
      [supported]:                           enhanced erase
      [likely_used]:                         10
      [lba_user_addressable_sectors]:        268435455
      [lba48_user_addressable_sectors]:      3750748848
      [logical_sector_size]:                 512 bytes
      [physical_sector_size]:                4096 bytes
      [logical_sector-0_offset]:             0 bytes
      [device_size_with_m_=_1024*1024]:      1831420 MBytes
      [device_size_with_m_=_1000*1000]:      1920383 MBytes (1920 GB)
      [form_factor]:                         2.5 inch
      [nominal_media_rotation_rate]:         Solid State Device
      [queue_depth]:                         32
      [standby_timer_values]:                spec'd by Standard, with device
                                             specific minimum
      [r/w_multiple_sector_transfer]:        Max = 16 Current = 16
      [advanced_power_management_level]:     254
      [dma]:                                 mdma0 mdma1 mdma2 udma0 udma1
                                             udma2 udma3 udma4 udma5 *udma6
      [cycle_time]:                          no flow control=120ns IORDY flow
                                             control=120ns
      [pio]:                                 pio0 pio1 pio2 pio3 pio4
      [security]:
      [not_expired]:                         security count
      [logical_unit_wwn_device_identifier]:  500a0751179c413f
      [naa]:                                 5
      [ieee_oui]:                            00a075
      [unique_id]:                           1179c413f
      [checksum]:                            correct
      [name]:                                sda1
      [maj:min]:                             8:1
      [rm]:                                  1
      [size]:                                4M
      [ro]:                                  0
      [type]:                                part
      [mountpoint]:

    """

    cmd_buf = "hdparm -I " + device + " | egrep \":.+\" | sed -re" +\
        " \"s/[ \t]+/ /g\""
    stdout, stderr, rc = bsu.os_execute_command(cmd_buf)

    firmware_dict = vf.key_value_outbuf_to_dict(stdout)

    cmd_buf = "lsblk -P " + device + " | sed -re 's/\" /\"\\n/g'"
    stdout, stderr, rc = bsu.os_execute_command(cmd_buf)
    firmware_dict.update(vf.key_value_outbuf_to_dict(stdout, delim='=',
                                                     strip=" \""))

    return firmware_dict
