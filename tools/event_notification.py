#!/usr/bin/env python

import requests
import websocket
import json
import ssl
import getopt
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "../lib"))

import gen_valid as gv
import gen_print as gp


def usage():
    print("Usage: %s   <one or more parameters>" % os.path.basename(__file__))
    print("  Subscribe and receive event notifications when properties change for given dbus path.")
    print("  Parameters:")
    print("     -h | --help")
    print("     -H | --host")
    print("     -U | --username")
    print("     -P | --password")
    print("     -D | --dbus_path")
    print("     -T | --enable_trace  default value is False (optional)")
    print("  Example:  %s -H xxx -U xxx -P xxx -D \"{'paths': "
          + "'/xyz/openbmc_project/control/host0/power_cap'}\" -T" % os.path.basename(__file__))


def main(argv):
    host = ""
    username = ""
    password = ""
    dbus_path = ""
    enable_trace = False

    if len(sys.argv) == 1:
        usage()
        sys.exit()
    try:
        opts, args = getopt.getopt(
            argv, "hH:U:P:D:TL", [
                "help", "host=", "username=", "password=", "dbus_path=", "enable_trace"])

    except getopt.GetoptError:
        usage()
        sys.exit()
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt in ("-H", "--host"):
            host = arg
        elif opt in ("-U", "--username"):
            username = arg
        elif opt in ("-P", "--password"):
            password = arg
        elif opt in ("-D", "--dbus_path"):
            # String enclosed in single quote is changed to double quote
            # to make it json compatible.
            json_compatible_format = arg.replace("'", "\"")
            dbus_path = json.loads(json_compatible_format)
        elif opt in ("-T", "--trace"):
            enable_trace = True

    eN = event_notification(host, username, password)
    output = eN.subscribe(dbus_path, enable_trace)
    gp.qprint_var(output)


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

    def login(self):
        r"""
        Login and return session token.
        """
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
        ${result}=  Subscribe  ${data}
        Rprint Vars  result

        Example output:
        result:
          [0]:
            [interface]:             xyz.openbmc_project.Sensor.Value
            [path]:                  /xyz/openbmc_project/sensors/temperature/ambient
            [event]:                 PropertiesChanged
            [properties]:
              [Value]:               23813

        Description of argument(s):
        dbus_path              The subcribing event's path (e.g.
                                {"paths": ["/xyz/openbmc_project/sensors"]}).
        enable_trace            Enable or disable trace.
        """

        session = self.login()

        cookies = session.cookies.get_dict()
        # Convert from dictionary to a string of the following format:
        # key=value;key=value...
        cookies = gp.sprint_var(cookies, fmt=gp.no_header() | gp.strip_brackets(),
                                col1_width=0, trailing_char="",
                                delim="=").replace("\n", ";")

        websocket.enableTrace(enable_trace)

        my_websocket = websocket.create_connection("wss://{host}/subscribe".format(host=self.__host),
                                                   sslopt={"cert_reqs": ssl.CERT_NONE},
                                                   cookie=cookies)

        try:
            my_websocket.send(json.dumps(dbus_path))
            result = json.loads(my_websocket.recv())
            my_websocket.close()
        except (websocket.WebSocketConnectionClosedException) as e:
            print(str(e))
            raise

        return result


if __name__ == "__main__":
    main(sys.argv[1:])
