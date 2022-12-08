#!/usr/bin/env python3


import time
import socket
import logging
import telnetlib
from collections import deque


class TelnetRemoteclient:

    r"""
    Class to create telnet connection to remote host for command execution.
    """

    def __init__(self, hostname, username, password, port=23, read_timeout=None):

        r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to FFCD files
        password        Password for user on remote host
        read_timeout    New read timeout value to override default one
        """

        self.hostname = hostname
        self.username = username
        self.password = password
        self.tnclient = None
        self.port = port
        self.read_timeout = read_timeout

    def tn_remoteclient_login(self):

        is_telnet = True
        try:
            self.tnclient = telnetlib.Telnet(self.hostname, self.port, timeout=15)
            if b'login:' in self.tnclient.read_until(b'login:', timeout=self.read_timeout):
                self.tnclient.write(self.username.encode('utf-8') + b"\n")

                if b'Password:' in self.tnclient.read_until(b'Password:', timeout=self.read_timeout):
                    self.tnclient.write(self.password.encode('utf-8') + b"\n")

                    n, match, pre_match = \
                        self.tnclient.expect(
                            [b'Login incorrect', b'invalid login name or password.', br'\#', br'\$'],
                            timeout=self.read_timeout)
                    if n == 0 or n == 1:
                        logging.error(
                            "\n\tERROR: Telnet Authentication Failed.  Check userid and password.\n\n")
                        is_telnet = False
                    else:
                        # login successful
                        self.fifo = deque()
                else:
                    # Anything else, telnet server is not running
                    logging.error("\n\tERROR: Telnet Connection Refused.\n\n")
                    is_telnet = False
            else:
                is_telnet = False
        except Exception:
            # Any kind of exception, skip telnet protocol
            is_telnet = False

        return is_telnet

    def __del__(self):
        self.tn_remoteclient_disconnect()

    def tn_remoteclient_disconnect(self):
        try:
            self.tnclient.close()
        except Exception:
            # the telnet object might not exist yet, so ignore this one
            pass

    def execute_command(self, cmd,
                        i_timeout=120):

        r'''
            Executes commands on the remote host

            Description of argument(s):
            cmd             Command to run on remote host
            i_timeout       Timeout for command output
                            default is 120 seconds
        '''

        # Wait time for command execution before reading the output.
        # Use user input wait time for command execution if one exists.
        # Else use the default 120 sec,
        if i_timeout != 120:
            execution_time = i_timeout
        else:
            execution_time = 120

        # Execute the command and read the command output.
        return_buffer = b''
        try:

            # Do at least one non-blocking read.
            #  to flush whatever data is in the read buffer.
            while self.tnclient.read_very_eager():
                continue

            # Execute the command
            self.tnclient.write(cmd.encode('utf-8') + b'\n')
            time.sleep(execution_time)

            local_buffer = b''
            # Read the command output one block at a time.
            return_buffer = self.tnclient.read_very_eager()
            while return_buffer:
                local_buffer = b''.join([local_buffer, return_buffer])
                time.sleep(3)  # let the buffer fill up a bit
                return_buffer = self.tnclient.read_very_eager()
        except (socket.error, EOFError) as e:
            self.tn_remoteclient_disconnect()

            if str(e).__contains__("Connection reset by peer"):
                msg = e
            elif str(e).__contains__("telnet connection closed"):
                msg = "Telnet connection closed."
            else:
                msg = "Some other issue.%s %s %s\n\n" % (cmd, e.__class__, e)

            logging.error("\t\t ERROR %s " % msg)

        # Return ASCII string data with ending PROMPT stripped
        return local_buffer.decode('ascii', 'ignore').replace('$ ', '\n')
