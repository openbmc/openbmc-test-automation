#!/usr/bin/env python3

import logging
import socket
import time
from socket import timeout as SocketTimeout

import paramiko
from paramiko.buffered_pipe import PipeTimeout as PipeTimeout
from paramiko.ssh_exception import (
    AuthenticationException,
    BadHostKeyException,
    NoValidConnectionsError,
    SSHException,
)
from scp import SCPClient, SCPException


class SSHRemoteclient:
    r"""
    Class to create ssh connection to remote host
    for remote host command execution and scp.
    """

    def __init__(self, hostname, username, password, port_ssh):
        r"""
        Initialize the FFDCCollector object with the provided remote host
        details.

        This method initializes an FFDCCollector object with the given
        attributes, which represent the details of the remote (targeting)
        host. The attributes include the hostname, username, password, and
        SSH port.

        Parameters:
            hostname (str): Name or IP address of the remote (targeting) host.
            username (str): User on the remote host with access to FFDC files.
            password (str): Password for the user on the remote host.
            port_ssh (int): SSH port value. By default, 22.

        Returns:
            None
        """
        self.ssh_output = None
        self.ssh_error = None
        self.sshclient = None
        self.scpclient = None
        self.hostname = hostname
        self.username = username
        self.password = password
        self.port_ssh = port_ssh

    def ssh_remoteclient_login(self):
        r"""
        Connect to remote host using the SSH client.

        Returns:
            bool: The method return True on success and False in failure.
        """
        is_ssh_login = True
        try:
            # SSHClient to make connections to the remote server
            self.sshclient = paramiko.SSHClient()
            # setting set_missing_host_key_policy() to allow any host
            self.sshclient.set_missing_host_key_policy(
                paramiko.AutoAddPolicy()
            )
            # Connect to the server
            self.sshclient.connect(
                hostname=self.hostname,
                port=self.port_ssh,
                username=self.username,
                password=self.password,
                banner_timeout=120,
                timeout=60,
                look_for_keys=False,
            )

        except (
            BadHostKeyException,
            AuthenticationException,
            SSHException,
            NoValidConnectionsError,
            socket.error,
        ) as e:
            is_ssh_login = False
            print("SSH Login: Exception: %s" % e)

        return is_ssh_login

    def ssh_remoteclient_disconnect(self):
        r"""
        Disconnect from the remote host using the SSH client.

        This method disconnects from the remote host using the SSH client
        established during the FFDC collection process. The method does not
        return any value.

        Returns:
            None
        """
        if self.sshclient:
            self.sshclient.close()

        if self.scpclient:
            self.scpclient.close()

    def execute_command(self, command, default_timeout=60):
        r"""
        Execute a command on the remote host using the SSH client.

        This method executes a provided command on the remote host using the
        SSH client. The method takes the command string as an argument and an
        optional default_timeout parameter of 60 seconds, which specifies the
        timeout for the command execution.

        The method returns the output of the executed command as a string.

        Parameters:
            command (str):                   The command string to be executed
                                             on the remote host.
            default_timeout (int, optional): The timeout for the command
                                             execution. Defaults to 60 seconds.

        Returns:
            str: The output of the executed command as a string.
        """
        empty = ""
        cmd_start = time.time()
        try:
            stdin, stdout, stderr = self.sshclient.exec_command(
                command, timeout=default_timeout
            )
            start = time.time()
            while time.time() < start + default_timeout:
                # Need to do read/write operation to trigger
                # paramiko exec_command timeout mechanism.
                xresults = stderr.readlines()
                results = "".join(xresults)
                time.sleep(1)
                if stdout.channel.exit_status_ready():
                    break
            cmd_exit_code = stdout.channel.recv_exit_status()

            # Convert list of string to one string
            err = ""
            out = ""
            for item in results:
                err += item
            for item in stdout.readlines():
                out += item

            return cmd_exit_code, err, out

        except (
            paramiko.AuthenticationException,
            paramiko.SSHException,
            paramiko.ChannelException,
            SocketTimeout,
        ) as e:
            # Log command with error.
            # Return to caller for next command, if any.
            logging.error(
                "\n\tERROR: Fail remote command %s %s" % (e.__class__, e)
            )
            logging.error(
                "\tCommand '%s' Elapsed Time %s"
                % (
                    command,
                    time.strftime(
                        "%H:%M:%S", time.gmtime(time.time() - cmd_start)
                    ),
                )
            )
            return 0, empty, empty

    def scp_connection(self):
        r"""
        Establish an SCP connection for file transfer.

        This method creates an SCP connection for file transfer using the SSH
        client established during the FFDC collection process.

        Returns:
            None
        """
        try:
            self.scpclient = SCPClient(
                self.sshclient.get_transport(), sanitize=lambda x: x
            )
            logging.info(
                "\n\t[Check] %s SCP transport established.\t [OK]"
                % self.hostname
            )
        except (SCPException, SocketTimeout, PipeTimeout) as e:
            self.scpclient = None
            logging.error(
                "\n\tERROR: SCP get_transport has failed. %s %s"
                % (e.__class__, e)
            )
            logging.info(
                "\tScript continues generating FFDC on %s." % self.hostname
            )
            logging.info(
                "\tCollected data will need to be manually offloaded."
            )

    def scp_file_from_remote(self, remote_file, local_file):
        r"""
        SCP a file from the remote host to the local host with a filename.

        This method copies a file from the remote host to the local host using
        the SCP protocol. The method takes the remote_file and local_file as
        arguments, which represent the full paths of the files on the remote
        and local hosts, respectively.


        Parameters:
            remote_file (str): The full path filename on the remote host.
            local_file (str):  The full path filename on the local host.

        Returns:
            bool: The method return True on success and False in failure.
        """
        try:
            self.scpclient.get(remote_file, local_file, recursive=True)
        except (SCPException, SocketTimeout, PipeTimeout, SSHException) as e:
            # Log command with error. Return to caller for next file, if any.
            logging.error(
                "\n\tERROR: Fail scp %s from remotehost %s %s\n\n"
                % (remote_file, e.__class__, e)
            )
            # Pause for 2 seconds allowing Paramiko to finish error processing
            # before next fetch. Without the delay after SCPException, next
            # fetch will get 'paramiko.ssh_exception.SSHException'> Channel
            # closed Error.
            time.sleep(2)
            return False
        # Return True for file accounting
        return True
