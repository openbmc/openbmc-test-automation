#!/usr/bin/env python3


import os
import sys

# ---------Set sys.path for pluqin execution----------------------------------
# Absolute path to this plugin
abs_path = os.path.abspath(os.path.dirname(sys.argv[0]))
# full_path to plugins parent directory
full_path = abs_path.split("plugins")[0]
sys.path.append(full_path)
# Walk path and append to sys.path
for root, dirs, files in os.walk(full_path):
    for found_dir in dirs:
        sys.path.append(os.path.join(root, found_dir))

from telnet_utility import TelnetRemoteclient  # NOQA


def telnet_execute_cmd(hostname, username, password, command, timeout=60):
    r"""
    Execute a command on the remote host using Telnet and return the output.

    This function executes a provided command on the remote host using Telnet.
    The function takes the remote host details (hostname, username, password)
    and the command to be executed as arguments.

    The function also accepts an optional timeout parameter, which specifies
    the time in seconds to wait for the command to complete.

    The function returns the output of the executed command as a string.

    Parameters:
        hostname (str):          Name or IP address of the remote host.
        username (str):          User on the remote host with access to files.
        password (str):          Password for the user on the remote host.
        command (str):           The command to be executed on the remote host.
        timeout (int, optional): The time in seconds to wait for the command
                                 to complete. Defaults to 60 seconds.

    Returns:
        str: The output of the executed command as a string.
    """
    telnet_remoteclient = TelnetRemoteclient(hostname, username, password)
    result = ""
    if telnet_remoteclient.tn_remoteclient_login():
        # result: stdout from remote host
        result = telnet_remoteclient.execute_command(command, timeout)

    # Close telnet session
    if telnet_remoteclient:
        telnet_remoteclient.tn_remoteclient_disconnect()

    return result
