#!/usr/bin/env python

r"""
See help text for details.
"""

import json
import sys
import websocket
import ssl
import requests

save_path_0 = sys.path[0]
del sys.path[0]

from gen_print import *
from gen_arg import *
from gen_plug_in import *
from gen_valid import *

# Restore sys.path[0].
sys.path.insert(0, save_path_0)

# Set exit_on_error for gen_valid functions.
set_exit_on_error(True)

# URI of the logging interface.
# This should end with the word "logging" and have
# no / character at the end.
logging_uri = '/xyz/openbmc_project/logging'


parser = argparse.ArgumentParser(
    usage='%(prog)s [OPTIONS]',
    description="%(prog)s will open a websocket session on a remote openBMC. "
                + "When an eSEL is created on that BMC, the monitor will receive "
                + "notice over websocket that the eSEL was created "
                + "and print a message.",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    prefix_chars='-+')
parser.add_argument(
    'openbmc_host',
    default='',
    help='The BMC host name or IP address.')
parser.add_argument(
    'openbmc_username',
    default='',
    help='The userid for the open BMC system.')
parser.add_argument(
    'openbmc_password',
    default='',
    help='The password for the open BMC system.')

stock_list = [("test_mode", 0), ("quiet", 0), ("debug", 0)]


def exit_function(signal_number=0,
                  frame=None):
    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    qprint_dashes()
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

    qprint_dashes()
    dprint_executing()

    # Calling exit prevents us from returning to the code that was running
    # when the signal was received.
    exit(0)


def validate_parms():
    r"""
    Validate program parameters, etc.
    """

    register_passwords(openbmc_password)
    valid_value(openbmc_username)
    valid_value(openbmc_password)
    gen_post_validation(exit_function, signal_handler)


def my_login(openbmc_host, openbmc_username, openbmc_password, quiet=None):
    """
    Log into the BMC and return the session object.

    Description of argument(s):
    openbmc_host          The BMC host name or IP address.
    openbmc_username      The userid for the open BMC system.
    openbmc_password      The password for the open BMC system.
    quiet                 Flag that is passed to connectionErrHandler.
                          This will allow relevant data to be displayed.
                          The handler becomes silent when set to True.
    """

    # Set quiet to default to the next level of quiet in the call stack.
    quiet = int(gm.dft(quiet, gp.get_stack_var('quiet', 0)))

    qprint_timen("Attempting login.")
    http_header = {'Content-Type': 'application/json'}
    my_session = requests.session()
    try:
        response = my_session.post('https://' + openbmc_host + '/login', headers=http_header,
                                   json={"data": [openbmc_username, openbmc_password]},
                                   verify=False, timeout=30)
        loginMessage = json.loads(response.text)
        if (loginMessage['status'] != "ok"):
            print(loginMessage["data"]["description"].encode('utf-8'))
            sys.exit(1)
        return my_session
    except(requests.exceptions.Timeout):
        return (connectionErrHandler(quiet, "Timeout", None))
    except(requests.exceptions.ConnectionError) as err:
        return (connectionErrHandler(quiet, "ConnectionError", err))


def on_message(websocket_obj, message):
    """
    Websocket message handler.  Close the websocket if the
    message is an eSEL message.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    message        The message sent from the websocket interface.
    """

    qprint_dashes()
    qprint_executing()

    # A typical message:
    # {"event":"PropertiesChanged","interface":"xyz.openbmc_
    # project.Logging.Entry","path":"/xyz/openbmc_project/lo
    # gging/entry/24","properties":{"Id":24}}

    if logging_uri + '/entry' in message and 'Id' in message:
        qprint_timen('eSEL received over websocket interface.')
        qprint_timen("Closing websocket. Expect to receive 'NoneType' object has no attribute 'connected'.")
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

    qprint_dashes()
    qprint_executing()


def on_close(websocket_obj):
    """
    Websocket close event handler.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    """

    qprint_dashes()
    qprint_executing()


def on_open(websocket_obj):
    """
    Send the filters needed to listen to the logging interface.

    Description of argument(s):
    websocket_obj  The websocket established during opne_socket().
    """

    qprint_dashes()
    qprint_executing()
    data = {"paths": [logging_uri]}
    websocket_obj.send(json.dumps(data))
    qprint_timen("Registered for websocket monitoring: " + logging_uri)


def open_socket(openbmc_host, openbmc_username, openbmc_password):
    """
    Open a long-running websocket to the BMC.

    Description of argument(s):
    openbmc_host      The BMC host name or IP address.
    openbmc_username  The userid for the open BMC system.
    openbmc_password  The Password for the open BMC system.
    """

    websocket.enableTrace(False)
    failedConCount = 0
    qprint_dashes()
    qprint_executing()
    for i in range(3):
        my_session = my_login(openbmc_host, openbmc_username, openbmc_password, True)
        # if not isinstance(my_session,basestring):
        if not isinstance(my_session, str):
            break
        else:
            failedConCount += 1

    if failedConCount >= 3:
        print_error("Failed to connect to BMC.")
        exit(1)
    else:
        qprint_timen("Registering websocket handlers.")
        cookie = my_session.cookies.get_dict()
        cookieStr = ""
        for key in cookie:
            if cookieStr != "":
                cookieStr = cookieStr + ";"
            cookieStr = cookieStr + key + "=" + cookie[key]
        # Register the event handlers. When an ESEL is created
        # by the system under test, the on_message() handler will
        # be called.
        websocket_obj = websocket.WebSocketApp("wss://" + openbmc_host + "/subscribe",
                                               on_message=on_message,
                                               on_error=on_error,
                                               on_close=on_close,
                                               on_open=on_open,
                                               cookie=cookieStr)
        qprint_timen("Completed registering of websocket handlers.")
        websocket_obj.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE})


def main():
    gen_get_options(parser, stock_list)
    validate_parms()
    qprint_pgm_header()
    open_socket(openbmc_host, openbmc_username, openbmc_password)


main()
