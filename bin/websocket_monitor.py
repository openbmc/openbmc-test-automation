#!/usr/bin/env python

r"""
This module opens a websocket session on a remote openBMC.
When an eSEL is created on that BMC at the logging_uri defined
below, the on_message() handler is called.
"""

import json
import sys
import os
import time
import datetime
import websocket
import ssl
import requests

save_path_0 = sys.path[0]
del sys.path[0]

from gen_print import *
from gen_arg import *
from gen_plug_in import *

# Restore sys.path[0].
sys.path.insert(0, save_path_0)


# URI of the logging interface.
# This should end with the word "logging" with
# no / character at the end.
logging_uri = '/xyz/openbmc_project/logging'

# String to print when an eSEL has been received.
esel_received = 'eSEL received over websocket interface.'


parser = argparse.ArgumentParser(
    description="This module opens a websocket session on a remote openBMC. "
                + "When an eSEL is created on that BMC, this program will receive "
                + "notice over websocket that the eSEL was created "
                + "and print a message.")
parser.add_argument("bmc_ipaddr")
parser.add_argument("bmc_userid")
parser.add_argument("bmc_passwd")
args = parser.parse_args()


def exit_function(signal_number=0,
                  frame=None):
    r"""
    Execute whenever the program ends normally or with the signals that we
    catch (i.e. TERM, INT).
    """

    print ("IN EXIT FN")

    dprint_executing()

    dprint_var(signal_number)

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

    # Calling exit prevents us from returning to the code that was running
    # when the signal was received.
    exit(0)


def validate_parms():
    r"""
    Validate program parameters, etc.  Return True or False (i.e. pass/fail)
    accordingly.
    """

    gen_post_validation(exit_function, signal_handler)


validate_parms()

bmcHostname = args.bmc_ipaddr
bmcUser = args.bmc_userid
bmcPassword = args.bmc_passwd


def mylogin(host, username, pw, jsonFormat):
    """
    Log into the BMC and create a session.  The session object is returned.

    Description of argument(s):
    host          String, the hostname or IP address of the bmc to log into.
    username      The user name used to login into the BMC host.
    pw            The Password for the specified username.
    JasonFormat   Boolean, flag that will allow relevant data
                  to be displayed,   This function becomes silent
                  when set to True.
    """

    if jsonFormat is False:
        print("Attempting login...")
    httpHeader = {'Content-Type': 'application/json'}
    mysess = requests.session()
    try:
        r = mysess.post('https://' + host + '/login', headers=httpHeader,
                        json={"data": [username, pw]},
                        verify=False, timeout=30)
        loginMessage = json.loads(r.text)
        if (loginMessage['status'] != "ok"):
            print(loginMessage["data"]["description"].encode('utf-8'))
            sys.exit(1)
        return mysess
    except(requests.exceptions.Timeout):
        return (connectionErrHandler(jsonFormat, "Timeout", None))
    except(requests.exceptions.ConnectionError) as err:
        return (connectionErrHandler(jsonFormat, "ConnectionError", err))


def on_message(ws, message):
    """
        Websocket message handler.  Close the websocket if the
        message is an eSEL message.
    """

    print ("---------------- ON_MESSAGE:begin --------------------")

    # A typical message:
    # {"event":"PropertiesChanged","interface":"xyz.openbmc_
    # project.Logging.Entry","path":"/xyz/openbmc_project/lo
    # gging/entry/24","properties":{"Id":24}}

    print(message)
    has_esel_message = logging_uri + '/entry' in message
    has_id = 'Id' in message
    if has_esel_message and has_id:
        # Print that an eSEL was received.
        print (esel_received)
        print ("Closing websocket. Expecting to receive 'NoneType' object.")
        ws.close()
    print ("---------------- ON_MESSAGE:end --------------------")
    # Flush is required when running in a Robot Framework
    # environment otherwise program output may not show up.
    sys.stdout.flush()


def on_error(ws, wserror):
    """
        Websocket error handler.
    """

    print ("--------------------- ON_ERROR:begin -------------------------")

    # It is normal to receive this message when websocked closes:
    # 'NoneType' object has no attribute 'connected'.

    global bmcHostname
    print ("ERROR:  Websocket error: {bmc}: {err}".format(bmc=bmcHostname,
           err=wserror))
    print ("--------------------- ON_ERROR:end -------------------------")
    sys.stdout.flush()


def on_close(ws):
    """
        Websocket close event handler.
    """

    global bmcHostname
    print ("---------------- ON_CLOSE:begin --------------------")
    print ("       {bmc} websocket closed.".format(bmc=bmcHostname))
    print ("---------------- ON_CLOSE:end --------------------")
    sys.stdout.flush()


def on_open(ws):
    """
        Send the filters needed to listen to the logging interface.
    """

    print ("---------------- ON_OPEN:begin ----------------------")
    data = {"paths": [logging_uri]}
    ws.send(json.dumps(data))
    print ("Registered for monitoring via websocket: " + logging_uri)
    print ("---------------- ON_OPEN:end -------------------------")
    sys.stdout.flush()


def openSocket(hostname, username, password):
    """
        Open a long-running websocket to the specified OpenBMC.
    """

    global bmcHostname
    bmcHostname = hostname
    websocket.enableTrace(False)
    failedConCount = 0
    for i in range(3):
        mysession = mylogin(hostname, username, password, True)
        # if not isinstance(mysession,basestring):
        if not isinstance(mysession, str):
            break
        else:
            failedConCount += 1

    if failedConCount >= 3:
        print ("------------- FAIL_CONNECT TO BMC -------------------")
        sys.stdout.flush()
    else:
        print ("--------- Registering websocket handlers ----------- ")
        sys.stdout.flush()
        cookie = mysession.cookies.get_dict()
        cookieStr = ""
        for key in cookie:
            if cookieStr != "":
                cookieStr = cookieStr + ";"
            cookieStr = cookieStr + key + "=" + cookie[key]
        # Register the event handlers. When an ESEL is created
        # by the system under test, the on_message() handler will
        # be called.
        ws = websocket.WebSocketApp("wss://" + hostname + "/subscribe",
                                    on_message=on_message,
                                    on_error=on_error,
                                    on_close=on_close,
                                    cookie=cookieStr)
        ws.on_open = on_open
        ws.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE})


def main():
    print ("Starting " + sys.argv[0] + " " + bmcHostname + " " + bmcUser
           + " ********")
    openSocket(bmcHostname, bmcUser, bmcPassword)
    return True


# Main.

if not main():
    exit(1)
