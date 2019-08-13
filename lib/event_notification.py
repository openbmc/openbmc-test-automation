import urllib3
import requests
import websocket
import json
from websocket import create_connection
import ssl


class event_notification():
    r"""
    Main class to subscribe and receive event notifications.
    """
    # Constants
    failed_to_establish = 1

    def __init__(self, bmcIp, username, password):
        r"""
        Initialize instance variables.
        """
        self.host = bmcIp
        self.user = username
        self.password = password

    def login(self):
        r"""
        Return session token.

        Authenticate and return token for the session.
        """
        http_header = {'Content-Type': 'application/json'}
        my_session = requests.session()

        try:
            post_request = my_session.post('https://' + self.host + '/login',
                                           headers=http_header,
                                           json={"data": [self.user, self.password]},
                                           verify=False, timeout=30)
            login_msg = json.loads(post_request.text)
        except (requests.exceptions.ConnectionError,
                urllib3.exceptions.MaxRetryError) as e:
            print("Failed to establish session. Reason: " + str(e))
            return event_notification.failed_to_establish
        if (login_msg['status'] != "ok"):
            print(login_msg["data"]["description"].encode('utf-8'))
            print("Unable to login")
            return event_notification.failed_to_establish
        else:
            print(login_msg)

        return my_session

    def subscribe(self, event_path, event_count=1, enable_trace=False):
        r"""
        Return event notifications in list format.

        Subscribe to the given path and return event notifications.

        Description of argument(s):
        event_path              The subcribing event's path (e.g.
                                {"paths": ["/xyz/openbmc_project/sensors"]}).
        event_count             Number of times the event is requested.
        enable_trace            Enable or disable trace.
        """
        session = self.login()
        if session == event_notification.failed_to_establish:
            return event_notification.failed_to_establish

        cookie = session.cookies.get_dict()
        cookieStr = ""
        for key in cookie:
            if cookieStr != "":
                cookieStr = cookieStr + ";"
            cookieStr = cookieStr + key + "=" + cookie[key]

        if enable_trace:
            websocket.enable_trace(True)

        ws = create_connection("wss://{host}/subscribe".format(host=self.host),
                               sslopt={"cert_reqs": ssl.CERT_NONE},
                               cookie=cookieStr)
        print(event_path)
        result = []
        for iter in range(event_count):
            ws.send(json.dumps(event_path))
            result.append(json.loads(ws.recv()))
        print(result)
        ws.close()
        return result
