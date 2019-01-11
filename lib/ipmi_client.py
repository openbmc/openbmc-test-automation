#!/usr/bin/env python

r"""
A python companion file for ipmi_client.robot.
"""

import gen_print as gp
import gen_cmd as gc
from robot.libraries.BuiltIn import BuiltIn


def build_ipmi_ext_cmd(ipmi_cipher_level=None, quiet=None):
    r"""
    Build the global IPMI_EXT_CMD variable.

    If global variable IPMI_EXT_CMD already has a value, this keyword will
    simply return without taking any action with the following exception:

    If ipmi_cipher_level is is anything but None, this function will continue
    on and re-build the IPMI_EXT_CMD variable.

    This keyword is designed for use by keywords which use the IPMI_EXT_CMD
    variable (e.g. 'Run External IPMI Raw Command').  This keyword is
    warranted because the ipmitool program may or may not accept the -U (i.e.
    username) parameter depending on the version of code loaded on the BMC.
    This keyword will determine whether the "-U" parameter should be used and
    create IPMI_EXT_CMD accordingly.

    Furthermore, this keyword will run the command to create the 'root' IPMI
    username.

    Description of argument(s):
    # ipmi_cipher_level             IPMI cipher level value
    #                               (e.g. "1", "2", "3", "15", "16", "17").
    # quiet                         Indicates whether this keyword should run
    #                               without any output to the console.
    """

    ipmi_ext_cmd = BuiltIn().get_variable_value("${IPMI_EXT_CMD}", "")
    if ipmi_ext_cmd != "" and not ipmi_cipher_level:
        return

    quiet = int(gp.get_var_value(quiet, 0))
    openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}")
    ipmi_username = BuiltIn().get_variable_value("${IPMI_USERNAME}", "root")
    ipmi_password = BuiltIn().get_variable_value("${IPMI_PASSWORD}",
                                                 "0penBmc")
    if not ipmi_cipher_level:
        ipmi_cipher_level = BuiltIn().get_variable_value("${IPMI_CIPHER_LEVEL}",
                                                         "3")

    old_ipmi_ext_cmd = "ipmitool -I lanplus -C " + str(ipmi_cipher_level)\
        + " -P " + ipmi_password
    new_ipmi_ext_cmd = "ipmitool -I lanplus -C " + str(ipmi_cipher_level)\
        + " -U " + ipmi_username + " -P " + ipmi_password
    # Use a basic ipmitool command to help us determine whether the BMC will
    # accept the -U parm.
    ipmi_cmd = "power status"
    ipmi_cmd_suffix = " -H " + openbmc_host + " " + ipmi_cmd
    print_output = 0
    cmd_buf = new_ipmi_ext_cmd + ipmi_cmd_suffix
    new_rc, stdout = gc.shell_cmd(cmd_buf,
                                  print_output=print_output,
                                  show_err=0,
                                  ignore_err=1)
    gp.qprint_varx("rc", new_rc, 1)
    if new_rc == 0:
        ipmi_ext_cmd = new_ipmi_ext_cmd
        BuiltIn().set_global_variable("${IPMI_EXT_CMD}", ipmi_ext_cmd)
        return

    cmd_buf = old_ipmi_ext_cmd + ipmi_cmd_suffix
    old_rc, stdout = gc.shell_cmd(cmd_buf,
                                  print_output=print_output,
                                  show_err=0,
                                  ignore_err=1)
    gp.qprint_varx("rc", old_rc, 1)

    if old_rc == 0:
        ipmi_ext_cmd = old_ipmi_ext_cmd
        BuiltIn().set_global_variable("${IPMI_EXT_CMD}", ipmi_ext_cmd)
        return

    message = "Unable to run ipmitool, (with or without the '-U' parm)."
    BuiltIn().fail(message)


build_ipmi_ext_cmd()
