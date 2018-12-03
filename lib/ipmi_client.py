#!/usr/bin/env python

r"""
A python companion file for ipmi_client.robot.
"""

import gen_print as gp
import gen_cmd as gc
from robot.libraries.BuiltIn import BuiltIn


def build_ipmi_ext_cmd(quiet=None):
    r"""
    Build the global IPMI_EXT_CMD variable.

    If global variable IPMI_EXT_CMD already has a value, this keyword will
    simply return without taking any action.

    This keyword is designed for use by keywords which use the IPMI_EXT_CMD
    variable (e.g. 'Run External IPMI Raw Command').  This keyword is
    warranted because the ipmitool program may or may not accept the -U (i.e.
    username) parameter depending on the version of code loaded on the BMC.
    This keyword will determine whether the "-U" parameter should be used and
    create IPMI_EXT_CMD accordingly.

    Furthermore, this keyword will run the command to create the 'root' IPMI
    username.

    Description of argument(s):
    # quiet                         Indicates whether this keyword should run
    #                               without any output to the console.
    """

    ipmi_ext_cmd = BuiltIn().get_variable_value("${IPMI_EXT_CMD}", "")
    if ipmi_ext_cmd != "":
        return

    quiet = int(gp.get_var_value(quiet, 0))
    openbmc_host = BuiltIn().get_variable_value("${OPENBMC_HOST}")
    ipmi_username = BuiltIn().get_variable_value("${IPMI_USERNAME}", "root")
    ipmi_password = BuiltIn().get_variable_value("${IPMI_PASSWORD}",
                                                 "0penBmc")
    ipmi_cipher_level = BuiltIn().get_variable_value("${IPMI_CIPHER_LEVEL}",
                                                     "3")

    old_ipmi_ext_cmd = "ipmitool -I lanplus -C " + str(ipmi_cipher_level)\
        + " -P " + ipmi_password
    new_ipmi_ext_cmd = "ipmitool -I lanplus -C " + str(ipmi_cipher_level)\
        + " -U " + ipmi_username + " -P " + ipmi_password
    # The command shown below will create the ipmi_username account.
    ipmi_cmd = "raw 6 1"
    ipmi_cmd_suffix = " -H " + openbmc_host + " " + ipmi_cmd
    print_output = 0
    cmd_buf = old_ipmi_ext_cmd + ipmi_cmd_suffix
    old_rc, stdout = gc.shell_cmd(cmd_buf,
                                  print_output=print_output,
                                  show_err=0,
                                  ignore_err=1)
    gp.qprint_varx("rc", old_rc, 1)

    cmd_buf = new_ipmi_ext_cmd + ipmi_cmd_suffix
    new_rc, stdout = gc.shell_cmd(cmd_buf,
                                  print_output=print_output,
                                  show_err=0,
                                  ignore_err=1)
    gp.qprint_varx("rc", new_rc, 1)
    if old_rc != 0 and new_rc != 0:
        message = "Unable to run ipmitool, (with or without the '-U' parm)."
        BuiltIn().fail(message)

    if new_rc == 0:
        ipmi_ext_cmd = new_ipmi_ext_cmd
    else:
        ipmi_ext_cmd = old_ipmi_ext_cmd

    BuiltIn().set_global_variable("${IPMI_EXT_CMD}", ipmi_ext_cmd)


build_ipmi_ext_cmd()
