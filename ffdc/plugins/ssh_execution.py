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

# ssh_utility is in ../lib
from ssh_utility import SSHRemoteclient


def ssh_execute_cmd(hostname,
                    username,
                    password,
                    command,
                    timeout=60,
                    type=None):
    r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to FFCD files
        password        Password for user on remote host
        command         Command to run on remote host
        timeout         Time, in second, to wait for command completion
        type            Data type return as list or others.
    """
    ssh_remoteclient = SSHRemoteclient(hostname,
                                       username,
                                       password)

    cmd_exit_code = 0
    err = ''
    response = ''
    if ssh_remoteclient.ssh_remoteclient_login():

        """
        cmd_exit_code: command exit status from remote host
        err: stderr from remote host
        response: stdout from remote host
        """
        cmd_exit_code, err, response = \
            ssh_remoteclient.execute_command(command, int(timeout))

    # Close ssh session
    if ssh_remoteclient:
        ssh_remoteclient.ssh_remoteclient_disconnect()

    if type == "list":
        return response.split('\n')
    else:
        return response
