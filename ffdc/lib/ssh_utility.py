#!/usr/bin/env python3

import paramiko
from paramiko.ssh_exception import AuthenticationException
from paramiko.ssh_exception import NoValidConnectionsError
from paramiko.ssh_exception import SSHException
from paramiko.ssh_exception import BadHostKeyException
from paramiko.buffered_pipe import PipeTimeout as PipeTimeout
from scp import SCPClient, SCPException
import time
import socket
import logging
from socket import timeout as SocketTimeout


class SSHRemoteclient:
    r"""
    Class to create ssh connection to remote host
    for remote host command execution and scp.
    """

    def __init__(self, hostname, username, password):

        r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to FFCD files
        password        Password for user on remote host
        """

        self.ssh_output = None
        self.ssh_error = None
        self.sshclient = None
        self.scpclient = None
        self.hostname = hostname
        self.username = username
        self.password = password

    def ssh_remoteclient_login(self):

        r"""
        Method to create a ssh connection to remote host.
        """

        is_ssh_login = True
        try:
            # SSHClient to make connections to the remote server
            self.sshclient = paramiko.SSHClient()
            # setting set_missing_host_key_policy() to allow any host
            self.sshclient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            # Connect to the server
            self.sshclient.connect(hostname=self.hostname,
                                   username=self.username,
                                   password=self.password,
                                   banner_timeout=120,
                                   timeout=60,
                                   look_for_keys=False)

        except (BadHostKeyException, AuthenticationException,
                SSHException, NoValidConnectionsError, socket.error) as e:
            is_ssh_login = False

        return is_ssh_login

    def ssh_remoteclient_disconnect(self):

        r"""
        Clean up.
        """

        if self.sshclient:
            self.sshclient.close()

        if self.scpclient:
            self.scpclient.close()

    def execute_command(self, command,
                        default_timeout=60):
        """
        Execute command on the remote host.

        Description of argument(s):
        command                Command string sent to remote host

        """

        empty = ''
        cmd_start = time.time()
        try:
            stdin, stdout, stderr = \
                self.sshclient.exec_command(command, timeout=default_timeout)
            start = time.time()
            while time.time() < start + default_timeout:
                # Need to do read/write operation to trigger
                # paramiko exec_command timeout mechanism.
                xresults = stderr.readlines()
                results = ''.join(xresults)
                time.sleep(1)
                if stdout.channel.exit_status_ready():
                    break
            cmd_exit_code = stdout.channel.recv_exit_status()

            # Convert list of string to one string
            err = ''
            out = ''
            for item in results:
                err += item
            for item in stdout.readlines():
                out += item

            return cmd_exit_code, err, out

        except (paramiko.AuthenticationException, paramiko.SSHException,
                paramiko.ChannelException, SocketTimeout) as e:
            # Log command with error. Return to caller for next command, if any.
            logging.error("\n\tERROR: Fail remote command %s %s" % (e.__class__, e))
            logging.error("\tCommand '%s' Elapsed Time %s" %
                          (command, time.strftime("%H:%M:%S", time.gmtime(time.time() - cmd_start))))
            return 0, empty, empty

    def scp_connection(self):

        r"""
        Create a scp connection for file transfer.
        """
        try:
            self.scpclient = SCPClient(self.sshclient.get_transport(), sanitize=lambda x: x)
            logging.info("\n\t[Check] %s SCP transport established.\t [OK]" % self.hostname)
        except (SCPException, SocketTimeout, PipeTimeout) as e:
            self.scpclient = None
            logging.error("\n\tERROR: SCP get_transport has failed. %s %s" % (e.__class__, e))
            logging.info("\tScript continues generating FFDC on %s." % self.hostname)
            logging.info("\tCollected data will need to be manually offloaded.")

    def scp_file_from_remote(self, remote_file, local_file):

        r"""
        scp file in remote system to local with date-prefixed filename.

        Description of argument(s):
        remote_file            Full path filename on the remote host

        local_file             Full path filename on the local host
                               local filename = date-time_remote filename

        """

        try:
            self.scpclient.get(remote_file, local_file, recursive=True)
        except (SCPException, SocketTimeout, PipeTimeout) as e:
            # Log command with error. Return to caller for next file, if any.
            logging.error(
                "\n\tERROR: Fail scp %s from remotehost %s %s\n\n" % (remote_file, e.__class__, e))
            return False

        # Return True for file accounting
        return True
