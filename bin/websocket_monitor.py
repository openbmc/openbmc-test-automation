#!/usr/bin/env python3

r"""
See help text for details.
"""

import json
import sys
import websocket
import ssl
import requests
from retrying import retry

save_path_0 = sys.path[0]
del sys.path[0]

from gen_print import *
from gen_arg import *
from gen_valid import *

# Restore sys.path[0].
sys.path.insert(0, save_path_0)

# Set exit_on_error for gen_valid functions.
set_exit_on_error(True)


parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS]',
    description="%(prog)s will open a websocket session on a remote OpenBMC. "
                + "When an eSEL is created on that BMC, the monitor will receive "
                + "notice over websocket that the eSEL was created "
                + "and it will print a message.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')
parser.add_argument(
    'openbmc_host',
    default='',
    help='The BMC host name or IP address.')
parser.add_argument(
    '--openbmc_username',
    default='root',
    help='The userid for the open BMC system.')
parser.add_argument(
    '--openbmc_password',
    default='',
    help='The password for the open BMC system.')
parser.add_argument(
    '--monitor_type',
    choices=['logging', 'dump'],
    default='logging',
    help='The type of notifications from websocket to monitor.')


stock_list = [("test_mode", 0), ("quiet", 0), ("debug", 0)]


def exit_function(signal_number=0,
                  frame=None):
    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    qprint_dashes(width=160)
    qprint_executing()
    qprint_pgm_footer()


def signal_handler(signal_number,
                   frame):
    r"""
    Handle signals.  Without a function to catch a SIGTERM or SIGINT, the
    program would terminate immediately with return code 143 and without
    calling the exit_function.
    """

    # Our convention is to set up exit_function with atexit.register() so
    # there is no need to explicitly call exit_function from here.

    dprint_executing()

    # Calling exit prevents returning to the code that was running
    # when the signal was received.
    exit(0)


def validate_parms():
    r"""
    Validate program parameters, etc.
    """

    register_passwords(openbmc_password)
    valid_value(openbmc_host)
    valid_value(openbmc_username)
    valid_value(openbmc_password)
    global monitoring_uri
    monitoring_uri = '/xyz/openbmc_project/' + monitor_type
    gen_post_validation(exit_function, signal_handler)


@retry(stop_max_attempt_number=3, wait_fixed=1000)
def login(openbmc_host,
          openbmc_username,
          openbmc_password):
    r"""
    Log into the BMC and return the session object.

    Description of argument(s):
    openbmc_host          The BMC host name or IP address.
    openbmc_username      The userid for the open BMC system.
    openbmc_password      The password for the open BMC system.
    """

    qprint_executing()

    http_header = {'Content-Type': 'application/json'}
    session = requests.session()
    response = session.post('https://' + openbmc_host + '/login', headers=http_header,
                            json={"data": [openbmc_username, openbmc_password]},
                            verify=False, timeout=30)
    valid_value(response.status_code, valid_values=[200])
    login_response = json.loads(response.text)
    qprint_var(login_response)
    valid_value(login_response['status'], valid_values=['ok'])

    return session


def on_message(websocket_obj, message):
    """
    Websocket message handler.  Close the websocket if the
    message is an eSEL message.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    message        The message sent from the websocket interface.
    """

    qprint_dashes(width=160)
    qprint_executing()

    # A typical message:
    # /xyz/openbmc_project/logging/entry/24","properties":{"Id":24}}
    # or
    # /xyz/openbmc_project/dump/entry/1","properties":{"Size":186180}}').

    if monitoring_uri + '/entry' in message:
        if 'Id' in message:
            qprint_timen('eSEL received over websocket interface.')
            websocket_obj.close()
        elif 'Size' in message:
            qprint_timen('Dump notification received over websocket interface.')
            websocket_obj.close()


def on_error(websocket_obj, wserror):
    """
    Websocket error handler.  This routine is called whenever the
    websocket interfaces wishes to report an issue.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    wserror        The error message sent from the websocket interface.
    """

    # It is normal to receive this message when websocked closes:
    # 'NoneType' object has no attribute 'connected'.

    qprint_dashes(width=160)
    qprint_executing()


def on_close(websocket_obj):
    """
    Websocket close event handler.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    """

    qprint_dashes(width=160)
    qprint_executing()


def on_open(websocket_obj):
    """
    Send the filters needed to listen to the logging interface.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    """

    qprint_dashes(width=160)
    qprint_executing()
    data = {"paths": [monitoring_uri]}
    websocket_obj.send(json.dumps(data))
    qprint_timen("Registered for websocket monitoring: " + monitoring_uri)


def open_socket(openbmc_host, openbmc_username, openbmc_password):
    """
    Open a long-running websocket to the BMC.
    Description of argument(s):
    openbmc_host      The BMC host name or IP address.
    openbmc_username  The userid for the open BMC system.
    openbmc_password  The Password for the open BMC system.
    """
    websocket.enableTrace(False)
    qprint_dashes(width=160)
    qprint_executing()
    session = login(openbmc_host, openbmc_username, openbmc_password)
    qprint_timen("Registering websocket handlers.")
    cookies = session.cookies.get_dict()
    cookies = sprint_var(cookies, fmt=no_header() | strip_brackets(),
                         col1_width=0, trailing_char="",
                         delim="=").replace("\n", ";")
    # Register the event handlers. When an ESEL is created by the system
    # under test, the on_message() handler will be called.
    websocket_obj = websocket.WebSocketApp("wss://" + openbmc_host + "/subscribe",
                                           on_message=on_message,
                                           on_error=on_error,
                                           on_close=on_close,
                                           on_open=on_open,
                                           cookie=cookies)
    qprint_timen("Completed registering of websocket handlers.")
    websocket_obj.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE})


def main():
    gen_get_options(parser, stock_list)
    validate_parms()
    qprint_pgm_header()
    qprint_var(monitoring_uri)
    open_socket(openbmc_host, openbmc_username, openbmc_password)


main()
