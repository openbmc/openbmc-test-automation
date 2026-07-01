#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
PTY Process Library for Robot Framework
========================================

Provides Robot Framework keywords to run interactive commands (such as
``ipmitool sol activate``) inside a **pseudo-terminal (PTY)**, with full
support for:

* Logging all stdout/stderr to a caller-supplied log file in real time.
* Sending arbitrary input (keystrokes, escape sequences, …) to the running
  process via its stdin.
* Reading output / waiting for regex patterns in the process output.
* Managing multiple concurrent PTY sessions identified by an *alias*.

Dependencies
------------
* ``pexpect >= 4.0``  (``pip install pexpect``)
"""

import os
import signal
import threading

import pexpect
from robot.api import logger


class PtyProcess:
    r"""Robot Framework library for running interactive commands in a PTY.

    All public methods are automatically exposed as Robot Framework keywords.
    Robot Framework keyword matching is case-insensitive, so
    ``start_pty_process`` is callable as ``Start PTY Process``.

    Scope: SUITE – one instance is shared across all tests in a suite so that
    processes started in one test are accessible in subsequent tests and in
    suite teardown.
    """

    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self):
        self._processes = {}  # alias -> pexpect.spawn
        self._log_handles = {}  # alias -> open file handle
        self._log_paths = {}  # alias -> log file path
        self._lock = threading.Lock()

    def start_pty_process(
        self,
        command,
        log_file,
        alias=None,
        encoding="utf-8",
        timeout=30,
        dimensions=(24, 200),
    ):
        r"""Start *command* inside a pseudo-terminal and stream all output to *log_file*.

        Arguments:
        | Argument    | Description                                                        |
        |-------------|--------------------------------------------------------------------|
        | command     | Full command string to execute (shell-style, e.g. ``ipmitool …``) |
        | log_file    | Absolute or relative path for the session log file                 |
        | alias       | Unique name for this session (auto-generated if omitted)           |
        | encoding    | Character encoding for the PTY (default: ``utf-8``)                |
        | timeout     | Default timeout in seconds for expect operations (default: ``30``) |
        | dimensions  | PTY window size as ``(rows, cols)`` tuple (default: ``(24, 200)``) |

        Returns the *alias* string that must be passed to all other keywords.

        Example:
        | ${alias}= | Start PTY Process | ipmitool -I lanplus -H ${HOST} sol activate | /tmp/sol.log |
        | ${alias}= | Start PTY Process | ipmitool … | /tmp/sol.log | alias=sol_session | timeout=60 |
        """
        log_dir = os.path.dirname(os.path.abspath(log_file))
        os.makedirs(log_dir, exist_ok=True)

        with self._lock:
            if alias is None:
                alias = "pty_proc_{}".format(len(self._processes))
            if alias in self._processes:
                raise RuntimeError(
                    "A PTY process with alias '{}' is already running. "
                    "Stop it first with 'Stop PTY Process'.".format(alias)
                )

        log_fh = open(
            log_file, "w", encoding=encoding, errors="ignore", buffering=1
        )

        child = pexpect.spawn(
            command,
            encoding=encoding,
            timeout=int(timeout),
            logfile=log_fh,
            dimensions=dimensions,
        )

        with self._lock:
            if alias in self._processes:  # re-check inside lock
                child.close(force=True)
                log_fh.close()
                raise RuntimeError(
                    "A PTY process with alias '{}' is already running. "
                    "Stop it first with 'Stop PTY Process'.".format(alias)
                )
            self._processes[alias] = child
            self._log_handles[alias] = log_fh
            self._log_paths[alias] = log_file

        logger.info(
            "[PtyProcess] Started PTY process alias='{}': {}".format(
                alias, command
            )
        )
        logger.info("[PtyProcess] Session log: {}".format(log_file))
        return alias

    def stop_pty_process(self, alias, force=False):
        r"""Stop the PTY process identified by *alias* and close its log file.

        Arguments:
        | Argument | Description                                                  |
        |----------|--------------------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process``              |
        | force    | If ``True``, send SIGKILL instead of SIGTERM (default False) |

        Returns the process exit code (or ``-1`` if unavailable).

        Example:
        | Stop PTY Process | sol_session |
        | Stop PTY Process | sol_session | force=True |
        """
        with self._lock:
            child = self._processes.pop(alias, None)
            log_fh = self._log_handles.pop(alias, None)
            self._log_paths.pop(alias, None)

        if child is None:
            logger.warn(
                "[PtyProcess] No PTY process found with alias '{}'".format(
                    alias
                )
            )
            return -1

        exit_code = -1
        try:
            if child.isalive():
                child.close(force=bool(force))
            exit_code = child.exitstatus if child.exitstatus is not None else 0
        except Exception as exc:
            logger.warn(
                "[PtyProcess] Error stopping '{}': {}".format(alias, exc)
            )

        if log_fh:
            try:
                log_fh.flush()
                log_fh.close()
            except Exception:
                pass

        logger.info(
            "[PtyProcess] Stopped PTY process '{}', exit_code={}".format(
                alias, exit_code
            )
        )
        return exit_code

    def stop_all_pty_processes(self, force=True):
        r"""Stop **all** running PTY processes.  Intended for suite/test teardown.

        Arguments:
        | Argument | Description                                                  |
        |----------|--------------------------------------------------------------|
        | force    | If ``True``, send SIGKILL to each process (default ``True``) |

        Example:
        | Stop All PTY Processes |
        | Stop All PTY Processes | force=False |
        """
        with self._lock:
            aliases = list(self._processes.keys())

        count = 0
        for alias in aliases:
            try:
                self.stop_pty_process(alias, force=force)
                count += 1
            except Exception as exc:
                logger.warn(
                    "[PtyProcess] Error stopping '{}': {}".format(alias, exc)
                )

        logger.info("[PtyProcess] Stopped {} PTY process(es)".format(count))

    def send_to_pty_process(self, alias, text):
        r"""Send *text* to the stdin of the running PTY process (no newline appended).

        Use this for escape sequences or raw keystrokes that must **not** have
        a trailing newline (e.g. ``~?`` or ``~.`` for ipmitool SOL).

        Arguments:
        | Argument | Description                                          |
        |----------|------------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process``      |
        | text     | Text to send (newline is NOT appended automatically) |

        Example:
        | Send To PTY Process | sol_session | ~? |
        | Send To PTY Process | sol_session | ~. |
        """
        child = self._get_process(alias)
        child.send(text)
        logger.info("[PtyProcess] Sent to '{}': {}".format(alias, repr(text)))

    def send_line_to_pty_process(self, alias, text):
        r"""Send *text* followed by a newline to the PTY process stdin.

        Use this for shell commands or menu selections that require Enter.

        Arguments:
        | Argument | Description                                     |
        |----------|-------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process`` |
        | text     | Text to send (newline IS appended automatically)|

        Example:
        | Send Line To PTY Process | sol_session | ls -la |
        | Send Line To PTY Process | sol_session | exit   |
        """
        child = self._get_process(alias)
        child.sendline(text)
        logger.info(
            "[PtyProcess] Sent line to '{}': {}".format(alias, repr(text))
        )

    def wait_for_pty_process_output(
        self, alias, pattern, timeout=30.0, error_patterns=None
    ):
        r"""Wait until *pattern* (regex) appears in the PTY process output.

        Arguments:
        | Argument       | Description                                                        |
        |----------------|--------------------------------------------------------------------|
        | alias          | Process alias returned by ``Start PTY Process``                    |
        | pattern        | Regex pattern to wait for                                          |
        | timeout        | Maximum seconds to wait (default: ``30``)                          |
        | error_patterns | Optional list of regex patterns that indicate failure              |

        Returns the text matched by *pattern*.

        Raises ``RuntimeError`` if timeout expires, process exits, or an error pattern matches.

        Example:
        | Wait For PTY Process Output | sol_session | SOL Session operational | timeout=30 |
        """
        child = self._get_process(alias)
        patterns = [pattern]
        if error_patterns:
            patterns.extend(error_patterns)
        patterns.extend([pexpect.TIMEOUT, pexpect.EOF])

        try:
            idx = child.expect(patterns, timeout=float(timeout))
        except pexpect.ExceptionPexpect as exc:
            raise RuntimeError(
                "[PtyProcess] pexpect error waiting for '{}' in '{}': {}".format(
                    pattern, alias, exc
                )
            )

        n_user = 1 + (len(error_patterns) if error_patterns else 0)

        if idx == 0:
            matched = child.match.group(0) if child.match else ""
            logger.info(
                "[PtyProcess] '{}' matched pattern: {}".format(
                    alias, repr(matched)
                )
            )
            return matched
        elif 1 <= idx < n_user:
            err_pat = patterns[idx]
            raise RuntimeError(
                "[PtyProcess] Error pattern '{}' matched in '{}' "
                "while waiting for '{}'".format(err_pat, alias, pattern)
            )
        elif idx == n_user:
            raise RuntimeError(
                "[PtyProcess] Timeout ({}s) waiting for '{}' in '{}'".format(
                    timeout, pattern, alias
                )
            )
        else:
            raise RuntimeError(
                "[PtyProcess] Process '{}' exited (EOF) before '{}' was found".format(
                    alias, pattern
                )
            )

    def read_pty_process_output(self, alias, timeout=2.0):
        r"""Read any output currently available from the PTY process.

        Non-blocking read with a short *timeout*.  Returns whatever the process
        has written since the last read, or empty string if nothing available.

        Arguments:
        | Argument | Description                                                  |
        |----------|--------------------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process``              |
        | timeout  | How long to wait for output in seconds (default: ``2``)      |

        Example:
        | ${output}= | Read PTY Process Output | sol_session |
        | ${output}= | Read PTY Process Output | sol_session | timeout=5 |
        """
        child = self._get_process(alias)
        try:
            child.expect(
                [pexpect.TIMEOUT, pexpect.EOF], timeout=float(timeout)
            )
        except pexpect.ExceptionPexpect:
            pass
        output = child.before or ""
        logger.info(
            "[PtyProcess] Read from '{}' ({} chars): {}".format(
                alias, len(output), repr(output[:200])
            )
        )
        return output

    def is_pty_process_running(self, alias):
        r"""Return ``True`` if the PTY process *alias* is still alive.

        Arguments:
        | Argument | Description                                     |
        |----------|-------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process`` |

        Example:
        | ${running}= | Is PTY Process Running | sol_session |
        | Should Be True | ${running} | msg=SOL session died unexpectedly |
        """
        child = self._get_process(alias)
        running = child.isalive()
        logger.info("[PtyProcess] '{}' is_alive={}".format(alias, running))
        return running

    def wait_for_pty_process_to_exit(self, alias, timeout=30.0):
        r"""Wait for the PTY process to exit and return its exit code.

        Arguments:
        | Argument | Description                                          |
        |----------|------------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process``      |
        | timeout  | Maximum seconds to wait (default: ``30``)            |

        Returns the integer exit code.

        Raises ``RuntimeError`` if the process does not exit within *timeout*.

        Example:
        | ${rc}= | Wait For PTY Process To Exit | sol_session | timeout=60 |
        | Should Be Equal As Integers | ${rc} | 0 |
        """
        child = self._get_process(alias)
        try:
            child.expect(pexpect.EOF, timeout=float(timeout))
        except pexpect.TIMEOUT:
            raise RuntimeError(
                "[PtyProcess] Process '{}' did not exit within {}s".format(
                    alias, timeout
                )
            )
        exit_code = (
            child.wait() if child.isalive() else (child.exitstatus or 0)
        )
        logger.info(
            "[PtyProcess] '{}' exited with code {}".format(alias, exit_code)
        )
        return exit_code

    def get_pty_process_log(self, log_file):
        r"""Read and return the full content of a PTY session log file.

        Arguments:
        | Argument | Description                    |
        |----------|--------------------------------|
        | log_file | Path to the session log file   |

        Returns the log content as a string (empty string if file not found).

        Example:
        | ${log}= | Get PTY Process Log | /tmp/sol.log |
        | Should Contain | ${log} | SOL Session operational |
        """
        try:
            with open(log_file, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
            logger.info(
                "[PtyProcess] Read log '{}': {} bytes".format(
                    log_file, len(content)
                )
            )
            return content
        except FileNotFoundError:
            logger.warn("[PtyProcess] Log file not found: {}".format(log_file))
            return ""

    def get_pty_process_log_path(self, alias):
        r"""Return the log file path associated with *alias*.

        Arguments:
        | Argument | Description                                     |
        |----------|-------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process`` |

        Example:
        | ${path}= | Get PTY Process Log Path | sol_session |
        | ${log}=  | Get PTY Process Log      | ${path}     |
        """
        with self._lock:
            path = self._log_paths.get(alias)
        if path is None:
            raise RuntimeError(
                "[PtyProcess] No log path found for alias '{}'".format(alias)
            )
        return path

    def start_sol_pty_session(
        self,
        ipmi_command,
        log_file,
        alias="sol_pty",
        startup_timeout=30.0,
        startup_pattern=r"SOL Session operational",
    ):
        r"""Start an ipmitool SOL session in a PTY and wait for the operational banner.

        Convenience wrapper around ``Start PTY Process`` +
        ``Wait For PTY Process Output`` tailored for ``ipmitool sol activate``.

        Arguments:
        | Argument        | Description                                                          |
        |-----------------|----------------------------------------------------------------------|
        | ipmi_command    | Full ``ipmitool … sol activate`` command string                      |
        | log_file        | Path for the session log file                                        |
        | alias           | Process alias (default: ``sol_pty``)                                 |
        | startup_timeout | Seconds to wait for the SOL banner (default: ``30``)                 |
        | startup_pattern | Regex to detect a live SOL session (default: ``SOL Session operational``) |

        Returns the alias.

        Raises ``RuntimeError`` if the SOL banner is not seen within *startup_timeout*.

        Example:
        | ${cmd}=   | Create IPMI Ext Command String | sol activate usesolkeepalive |
        | ${alias}= | Start SOL PTY Session | ${cmd} | /tmp/sol.log |
        """
        self.start_pty_process(
            ipmi_command,
            log_file,
            alias=alias,
            timeout=int(startup_timeout) + 5,
        )
        try:
            self.wait_for_pty_process_output(
                alias,
                startup_pattern,
                timeout=startup_timeout,
                error_patterns=[r"Error|Unable|failed|refused"],
            )
        except RuntimeError as exc:
            self.stop_pty_process(alias, force=True)
            raise RuntimeError(
                "SOL session '{}' did not become operational: {}".format(
                    alias, exc
                )
            )
        logger.info(
            "[PtyProcess] SOL session '{}' is operational".format(alias)
        )
        return alias

    def resume_pty_process(self, alias):
        r"""Send SIGCONT to a suspended PTY process to resume it.

        Use this after sending a suspend escape sequence (e.g. ``~^Z`` or
        ``~^X`` in an ipmitool SOL session) to bring the process back to the
        foreground.

        Arguments:
        | Argument | Description                                     |
        |----------|-------------------------------------------------|
        | alias    | Process alias returned by ``Start PTY Process`` |

        Example:
        | PTY.Send To PTY Process | sol_pty | ~\\x1a |   # ~^Z – suspend
        | PTY.Resume PTY Process  | sol_pty |            # resume with SIGCONT
        """
        child = self._get_process(alias)
        try:
            child.kill(signal.SIGCONT)
            logger.info(
                "[PtyProcessLib] Sent SIGCONT to '{}' (pid={})".format(
                    alias, child.pid
                )
            )
        except Exception as exc:
            logger.warn(
                "[PtyProcessLib] Error sending SIGCONT to '{}': {}".format(
                    alias, exc
                )
            )

    def stop_sol_pty_session(
        self, alias="sol_pty", exit_sequence="~.", exit_timeout=15.0
    ):
        r"""Terminate an ipmitool SOL session by sending the ``~.`` escape sequence.

        Arguments:
        | Argument      | Description                                                    |
        |---------------|----------------------------------------------------------------|
        | alias         | Process alias (default: ``sol_pty``)                           |
        | exit_sequence | Escape sequence to send (default: ``~.``)                      |
        | exit_timeout  | Seconds to wait for the process to exit (default: ``15``)      |

        Returns the process exit code.

        Example:
        | Stop SOL PTY Session | sol_pty |
        | ${rc}= | Stop SOL PTY Session | sol_pty | exit_timeout=30 |
        """
        try:
            child = self._get_process(alias)
            if child.isalive():
                child.send(exit_sequence)
                try:
                    child.expect(pexpect.EOF, timeout=float(exit_timeout))
                except pexpect.TIMEOUT:
                    logger.warn(
                        "[PtyProcess] SOL session '{}' did not exit after "
                        "'{}' within {}s – forcing close".format(
                            alias, exit_sequence, exit_timeout
                        )
                    )
        except RuntimeError:
            pass  # process already gone

        return self.stop_pty_process(alias, force=True)

    def _get_process(self, alias):
        r"""Return the pexpect child for *alias*, raising if not found."""
        with self._lock:
            child = self._processes.get(alias)
        if child is None:
            available = list(self._processes.keys())
            raise RuntimeError(
                "[PtyProcess] No PTY process with alias '{}'. "
                "Available aliases: {}".format(alias, available)
            )
        return child


# Module-level alias so Robot Framework can find the library class by module
# name.  RF resolves the class by looking for an attribute whose name matches
# the module name (case-insensitive).  "PtyProcess".lower() == "ptyprocess"
# but the module name is "pty_process", so without this alias RF would fall
# back to using the bare module (which has no keywords).
pty_process = PtyProcess
