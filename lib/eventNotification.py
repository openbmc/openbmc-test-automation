import urllib3
import requests
import websocket
import json
from websocket import create_connection
import ssl

class eventNotification():
    # Constants
    failedToEstablish = 1

    def __init__(self, bmcIp, username, password):
        self.host = bmcIp
        self.user = username
        self.password = password

    def establish_session(self):
        httpHeader = {'Content-Type':'application/json'}
        mySession = requests.session()

        try:
            postRequest = mySession.post('https://'+self.host+'/login',
                                         headers=httpHeader,
                                         json = {"data": [self.user, self.password]},
                                         verify=False, timeout=30)
            loginMessage = json.loads(postRequest.text)
        except (requests.exceptions.ConnectionError,
                urllib3.exceptions.MaxRetryError) as e:
            print("Failed to establish session. Reason: " +str(e))
            return eventNotification.failedToEstablish
        if (loginMessage['status'] != "ok"):
            print(loginMessage["data"]["description"].encode('utf-8'))
            print("Unable to login")
            return eventNotification.failedToEstablish
        else:
            print(loginMessage)

        return mySession

    def subscribe(self, data, loopCount=1, enableTrace=False):
        session = self.establish_session()
        if session == eventNotification.failedToEstablish:
            return eventNotification.failedToEstablish

        cookie= session.cookies.get_dict()
        cookieStr = ""
        for key in cookie:
            if cookieStr != "":
                cookieStr = cookieStr + ";"
            cookieStr = cookieStr + key +"=" + cookie[key]

        if enableTrace:
            websocket.enableTrace(True)


        ws = create_connection("wss://{host}/subscribe".format(host=self.host),
                               sslopt={"cert_reqs": ssl.CERT_NONE},
                               cookie = cookieStr)
        print(data)
        result = []
        for iter in range(loopCount):
            ws.send(json.dumps(data))
            result.append(json.loads(ws.recv()))
        print(result)
        ws.close()
        return result

