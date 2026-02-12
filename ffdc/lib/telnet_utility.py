#!/usr/bin/env python3


import logging
import socket
import telnetlib
import time
from collections import deque


class TelnetRemoteclient:
    r"""
    Class to create telnet connection to remote host for command execution.
    """

    def __init__(
        self, hostname, username, password, port=23, read_timeout=None
    ):
        r"""
        Initialize the TelnetRemoteClient object with the provided remote host
        details.

        This method initializes a TelnetRemoteClient object with the given
        attributes, which represent the details of the remote (targeting) host.

        The attributes include the hostname, username, password, and Telnet
        port.

        The method also accepts an optional read_timeout parameter, which
        specifies a new read timeout value to override the default one.

        Parameters:
            hostname (str):               Name or IP address of the remote
                                          host.
            username (str):               User on the remote host with access
                                          to files.
            password (str):               Password for the user on the remote
                                          host.
            port (int, optional):         Telnet port value. Defaults to 23.
            read_timeout (int, optional): New read timeout value to override
                                          the default one. Defaults to None.

        Returns:
            None
        """
        self.hostname = hostname
        self.username = username
        self.password = password
        self.tnclient = None
        self.port = port
        self.read_timeout = read_timeout

    def tn_remoteclient_login(self):
        r"""
        Establish a Telnet connection to the remote host and log in.

        This method establishes a Telnet connection to the remote host using
        the provided hostname, username, and password. If the connection and
        login are successful, the method returns True. Otherwise, it returns
        False.

        Parameters:
            None

        Returns:
            bool: True if the Telnet connection and login are successful,
                  False otherwise.
        """
        is_telnet = True
        try:
            self.tnclient = telnetlib.Telnet(
                self.hostname, self.port, timeout=15
            )
            if b"login:" in self.tnclient.read_until(
                b"login:", timeout=self.read_timeout
            ):
                self.tnclient.write(self.username.encode("utf-8") + b"\n")

                if b"Password:" in self.tnclient.read_until(
                    b"Password:", timeout=self.read_timeout
                ):
                    self.tnclient.write(self.password.encode("utf-8") + b"\n")

                    n, match, pre_match = self.tnclient.expect(
                        [
                            b"Login incorrect",
                            b"invalid login name or password.",
                            rb"\#",
                            rb"\$",
                        ],
                        timeout=self.read_timeout,
                    )
                    if n == 0 or n == 1:
                        logging.error(
                            "\n\tERROR: Telnet Authentication Failed.  Check"
                            " userid and password.\n\n"
                        )
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
        r"""
        Disconnect from the remote host when the object is deleted.

        This method disconnects from the remote host when the
        TelnetRemoteClient object is deleted.
        """
        self.tn_remoteclient_disconnect()

    def tn_remoteclient_disconnect(self):
        r"""
        Disconnect from the remote host using the Telnet client.

        This method disconnects from the remote host using the Telnet client
        established during the FFDC collection process.

        The method attempts to close the Telnet connection. If the Telnet
        client does not exist, the method ignores the exception.
        """
        try:
            self.tnclient.close()
        except Exception:
            # the telnet object might not exist yet, so ignore this one
            pass

    def execute_command(self, cmd, i_timeout=120):
        r"""
        Executes a command on the remote host using Telnet and returns the
        output.

        This method executes a provided command on the remote host using
        Telnet. The method takes the cmd argument, which is expected to be a
        valid command to execute, and an optional i_timeout parameter, which
        specifies the timeout for the command output.

        The method returns the output of the executed command as a string.

        Parameters:
            cmd (str):                 The command to be executed on the
                                       remote host.
            i_timeout (int, optional): The timeout for the command output.
                                       Defaults to 120 seconds.

        Returns:
            str: The output of the executed command as a string.
        """
        # Wait time for command execution before reading the output.
        # Use user input wait time for command execution if one exists.
        # Else use the default 120 sec,
        if i_timeout != 120:
            execution_time = i_timeout
        else:
            execution_time = 120

        # Execute the command and read the command output.
        return_buffer = b""
        try:
            # Do at least one non-blocking read.
            #  to flush whatever data is in the read buffer.
            while self.tnclient.read_very_eager():
                continue

            # Execute the command
            self.tnclient.write(cmd.encode("utf-8") + b"\n")
            time.sleep(execution_time)

            local_buffer = b""
            # Read the command output one block at a time.
            return_buffer = self.tnclient.read_very_eager()
            while return_buffer:
                local_buffer = b"".join([local_buffer, return_buffer])
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
        return local_buffer.decode("ascii", "ignore").replace("$ ", "\n")
