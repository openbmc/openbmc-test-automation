#!/usr/bin/env python

import requests
import websocket
import json
import ssl
import sys
import os

# Note: Set the importing path in PYTHONPATH
import gen_valid as gv
import gen_print as gp


class event_notification():
    r"""
    Main class to subscribe and receive event notifications.
    """

    def __init__(self, host, username, password):
        r"""
        Initialize instance variables.
        """
        self.__host = host
        self.__user = username
        self.__password = password

    def __del__(self):
        try:
            self.__websocket.close()
        except AttributeError:
            pass

    def login(self):
        r"""
        Login and return session token.
        """
        #qprintn(self.__host)
        gp.qprint_varx("host", self.__host)
        http_header = {'Content-Type': 'application/json'}
        session = requests.session()
        response = session.post('https://' + self.__host + '/login',
                                headers=http_header,
                                json={"data": [self.__user, self.__password]},
                                verify=False, timeout=30)
        gv.valid_value(response.status_code, valid_values=[200])
        login_response = json.loads(response.text)
        gp.qprint_var(login_response)
        gv.valid_value(login_response['status'], valid_values=['ok'])
        return session

    def subscribe(self, dbus_path, enable_trace=False):

        r"""
        Subscribe to the given path and return a list of event notifications.
        For more details on "subscribe" and "events" go to
        https://github.com/openbmc/docs/blob/master/rest-api.md#event-subscription-protocol

        Example robot code:
        ${result}=  Subscribe  /xyz/openbmc_project/sensors
        Rprint Vars  result

        Example output:
        event_notifications:
          [0]:
            [interface]:             xyz.openbmc_project.Sensor.Value
            [path]:                  /xyz/openbmc_project/sensors/temperature/ambient
            [event]:                 PropertiesChanged
            [properties]:
              [Value]:               23813

        Description of argument(s):
        dbus_path              The subcribing event's path (e.g.
                               "/xyz/openbmc_project/sensors").
        enable_trace           Enable or disable trace.
        """

        session = self.login()
        cookies = session.cookies.get_dict()
        # Convert from dictionary to a string of the following format:
        # key=value;key=value...
        cookies = gp.sprint_var(cookies, fmt=gp.no_header() | gp.strip_brackets(),
                                col1_width=0, trailing_char="",
                                delim="=").replace("\n", ";")

        websocket.enableTrace(enable_trace)
        self.__websocket = websocket.create_connection("wss://{host}/subscribe".format(host=self.__host),
                                                       sslopt={"cert_reqs": ssl.CERT_NONE},
                                                       cookie=cookies)
        dbus_path = [path.strip() for path in dbus_path.split(',')]
        dbus_path = {"paths": dbus_path}

        self.__websocket.send(json.dumps(dbus_path))
        event_notifications = json.loads(self.__websocket.recv())
        self.__websocket.close()
        return event_notifications