#!/usr/bin/env python3


import os
import sys

# ---------Set sys.path for pluqin execution---------------------------------------
# Absolute path to this plugin
abs_path = os.path.abspath(os.path.dirname(sys.argv[0]))
# full_path to plugins parent directory
full_path = abs_path.split('plugins')[0]
sys.path.append(full_path)
# Walk path and append to sys.path
for root, dirs, files in os.walk(full_path):
    for found_dir in dirs:
        sys.path.append(os.path.join(root, found_dir))

from telnet_utility import TelnetRemoteclient


def telnet_execute_cmd(hostname,
                       username,
                       password,
                       command,
                       timeout=60):
    r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to FFCD files
        password        Password for user on remote host
        command         Command to run on remote host
        timeout         Time, in second, to wait for command completion
    """
    telnet_remoteclient = TelnetRemoteclient(hostname,
                                             username,
                                             password)
    result = ''
    if telnet_remoteclient.tn_remoteclient_login():
        # result: stdout from remote host
        result = \
            telnet_remoteclient.execute_command(command, timeout)

    # Close telnet session
    if telnet_remoteclient:
        telnet_remoteclient.tn_remoteclient_disconnect()

    return result
