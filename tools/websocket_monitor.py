#!/usr/bin/env python

r"""
This module opens a websocket session on a remote openBMC.
When an eSEL is created on that BMC the on_message()
handler is called.
"""

import json
import sys
import os
import time
import datetime
try:
    import websocket
    import ssl
    import requests
except ImportError as e:
    print ("Missing required import file.")
    if hasattr(e, 'message'):
        print(e.message)
    else:
        print(e)
    sys.exit(3)


# URI of the logging interface.
logging_uri = '/xyz/openbmc_project/logging'

# Print this string if an eSEL was received.
esel_received = 'eSEL received over websocket interface.'

# Print current time for logging purposes.
now = datetime.datetime.now()
print (now)

# Check parameters.
progname = os.path.basename(sys.argv[0])
num_parameters = len(sys.argv)
if num_parameters != 4:
    print ("Usage:  " + progname + "   bmc_ipaddr   bmc_userid   bmc_passwd")
    print ("    example:")
    print ("        " + progname + "   10.0.0.1   root   ******** \n")
    sys.exit(2)

print ("Starting " + sys.argv[0] + " " + sys.argv[1] + " " + sys.argv[2]
       + " ********")

bmcHostname = sys.argv[1]
bmcUser = sys.argv[2]
bmcPassword = sys.argv[3]


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
        print ("Closing websocket.")
        ws.close()
    print ("---------------- ON_MESSAGE:end --------------------")


def on_error(ws, wserror):
    """
        Websocket error handler.  It is normal to receive this wserror
        message when websocket closes:  'NoneType' object has no
        attribute 'connected'.
    """

    print ("--------------------- ON_ERROR:begin -------------------------")

    # It is normal to receive this  message when websocked closes:
    # 'NoneType' object has no attribute 'connected'.

    global bmcHostname
    print ("ERROR:  Websocket error: {bmc}: {err}".format(bmc=bmcHostname,
           err=wserror))
    print ("--------------------- ON_ERROR:end -------------------------")


def on_close(ws):
    """
        Websocket close event handler.
    """

    global bmcHostname
    print ("---------------- ON_CLOSE:begin --------------------")
    print ("       {bmc} websocket closed.".format(bmc=bmcHostname))
    print ("---------------- ON_CLOSE:end --------------------")


def on_open(ws):
    """
        Send the filters needed to listen to the logging interface.
    """

    print ("---------------- ON_OPEN:begin ----------------------")
    data = {"paths": ["/xyz/openbmc_project/logging"]}
    data = {"paths": [logging_uri]}
    ws.send(json.dumps(data))
    print ("---------------- ON_OPEN:end -------------------------")


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
    else:
        print ("--------- Registering websocket handlers ----------- ")
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


# ================ The main program starts here  ==================.
openSocket(bmcHostname, bmcUser, bmcPassword)
