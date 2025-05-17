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

# ssh_utility is in ../lib
from ssh_utility import SSHRemoteclient  # NOQA


def ssh_execute_cmd(
    hostname, username, password, port_ssh, command, timeout=60, type=None
):
    r"""
    Execute a command on the remote host using SSH and return the output.

    This function executes a provided command on the remote host using SSH.
    The function takes the remote host details (hostname, username, password,
    and SSH port) and the command to be executed as arguments.

    The function also accepts an optional timeout parameter, which specifies
    the time in seconds to wait for the command to complete.

    The function returns the output of the executed command as a string or
    list

    Parameters:
        hostname (str):          Name or IP address of the remote host.
        username (str):          User on the remote host.
        password (str):          Password for the user on the remote host.
        port_ssh (int):          SSH port value. By default, 22.
        command (str):           The command to be executed on the remote host.
        timeout (int, optional): The time in seconds to wait for the command
                                 to complete. Defaults to 60 seconds.
        type (str, optional):    The data type to return. If set to list,
                                 the function returns a list of lines from the
                                 command output. Defaults to None.

    Returns:
        str or list: The output of the executed command as a string or a list
                     of lines, depending on the type parameter.
    """
    ssh_remoteclient = SSHRemoteclient(hostname, username, password, port_ssh)

    cmd_exit_code = 0
    err = ""
    response = ""
    if ssh_remoteclient.ssh_remoteclient_login():
        """
        cmd_exit_code: command exit status from remote host
        err: stderr from remote host
        response: stdout from remote host
        """
        cmd_exit_code, err, response = ssh_remoteclient.execute_command(
            command, int(timeout)
        )

    # Close ssh session
    if ssh_remoteclient:
        ssh_remoteclient.ssh_remoteclient_disconnect()

    if type == "list":
        return response.split("\n")
    else:
        return response
