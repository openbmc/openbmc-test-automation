#!/usr/bin/env python

"""
 Copyright 2017 IBM Corporation

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
"""
import argparse
import requests
import getpass
import json
import os
import urllib3
import time, datetime
import binascii
import subprocess
import platform
import zipfile

def hilight(textToColor, color, bold):
    """
         Used to add highlights to various text for displaying in a terminal
           
         @param textToColor: string, the text to be colored
         @param color: string, used to color the text red or green
         @param bold: boolean, used to bold the textToColor
         @return: Buffered reader containing the modified string. 
    """ 
    if(sys.platform.__contains__("win")):
        if(color == "red"):
            os.system('color 04')
        elif(color == "green"):
            os.system('color 02')
        else:
            os.system('color') #reset to default
        return textToColor
    else:
        attr = []
        if(color == "red"):
            attr.append('31')
        elif(color == "green"):
            attr.append('32')
        else:
            attr.append('0')
        if bold:
            attr.append('1')
        else:
            attr.append('0')
        return '\x1b[%sm%s\x1b[0m' % (';'.join(attr),textToColor)

   
def connectionErrHandler(jsonFormat, errorStr, err):
    """
         Error handler various connection errors to bmcs
           
         @param jsonFormat: boolean, used to output in json format with an error code. 
         @param errorStr: string, used to color the text red or green
         @param err: string, the text from the exception 
    """ 
    if errorStr == "Timeout":
        if not jsonFormat:
            return("FQPSPIN0000M: Connection timed out. Ensure you have network connectivity to the bmc")
        else:
            errorMessageStr = ("{\n\t\"event0\":{\n" +
            "\t\t\"CommonEventID\": \"FQPSPIN0000M\",\n"+
            "\t\t\"sensor\": \"N/A\",\n"+
            "\t\t\"state\": \"N/A\",\n" +
            "\t\t\"additionalDetails\": \"N/A\",\n" +
            "\t\t\"Message\": \"Connection timed out. Ensure you have network connectivity to the BMC\",\n" +
            "\t\t\"LengthyDescription\": \"While trying to establish a connection with the specified BMC, the BMC failed to respond in adequate time. Verify the BMC is functioning properly, and the network connectivity to the BMC is stable.\",\n" +
            "\t\t\"Serviceable\": \"Yes\",\n" +
            "\t\t\"CallHomeCandidate\": \"No\",\n" +
            "\t\t\"Severity\": \"Critical\",\n" +
            "\t\t\"EventType\": \"Communication Failure/Timeout\",\n" +
            "\t\t\"VMMigrationFlag\": \"Yes\",\n" +
            "\t\t\"AffectedSubsystem\": \"Interconnect (Networking)\",\n" +
            "\t\t\"timestamp\": \""+str(int(time.time()))+"\",\n" +
            "\t\t\"UserAction\": \"Verify network connectivity between the two systems and the bmc is functional.\"" +
            "\t\n}, \n" +
            "\t\"numAlerts\": \"1\" \n}");
            return(errorMessageStr)
    elif errorStr == "ConnectionError":
        if not jsonFormat:
            return("FQPSPIN0001M: " + str(err))
        else:
            errorMessageStr = ("{\n\t\"event0\":{\n" +
            "\t\t\"CommonEventID\": \"FQPSPIN0001M\",\n"+
            "\t\t\"sensor\": \"N/A\",\n"+
            "\t\t\"state\": \"N/A\",\n" +
            "\t\t\"additionalDetails\": \"" + str(err)+"\",\n" +
            "\t\t\"Message\": \"Connection Error. View additional details for more information\",\n" +
            "\t\t\"LengthyDescription\": \"A connection error to the specified BMC occurred and additional details are provided. Review these details to resolve the issue.\",\n" +
            "\t\t\"Serviceable\": \"Yes\",\n" +
            "\t\t\"CallHomeCandidate\": \"No\",\n" +
            "\t\t\"Severity\": \"Critical\",\n" +
            "\t\t\"EventType\": \"Communication Failure/Timeout\",\n" +
            "\t\t\"VMMigrationFlag\": \"Yes\",\n" +
            "\t\t\"AffectedSubsystem\": \"Interconnect (Networking)\",\n" +
            "\t\t\"timestamp\": \""+str(int(time.time()))+"\",\n" +
            "\t\t\"UserAction\": \"Correct the issue highlighted in additional details and try again\"" +
            "\t\n}, \n" +
            "\t\"numAlerts\": \"1\" \n}");
            return(errorMessageStr)
    else:
        return("Unknown Error: "+ str(err))


def setColWidth(keylist, numCols, dictForOutput, colNames):
    """
         Sets the output width of the columns to display
           
         @param keylist: list, list of strings representing the keys for the dictForOutput 
         @param numcols: the total number of columns in the final output
         @param dictForOutput: dictionary, contains the information to print to the screen
         @param colNames: list, The strings to use for the column headings, in order of the keylist
         @return: A list of the column widths for each respective column. 
    """
    colWidths = []
    for x in range(0, numCols):
        colWidths.append(0)
    for key in dictForOutput:
        for x in range(0, numCols):
            colWidths[x] = max(colWidths[x], len(str(dictForOutput[key][keylist[x]])))
    
    for x in range(0, numCols):
        colWidths[x] = max(colWidths[x], len(colNames[x])) +2
    
    return colWidths

def loadPolicyTable(pathToPolicyTable):
    """
         loads a json based policy table into a dictionary
           
         @param value: boolean, the value to convert
         @return: A string of "Yes" or "No"
    """ 
    policyTable = {}
    if(os.path.exists(pathToPolicyTable)):
        with open(pathToPolicyTable, 'r') as stream:
            try:
                contents =json.load(stream)
                policyTable = contents['events']
            except Exception as err:
                print(err)
    return policyTable


def boolToString(value):
    """
         converts a boolean value to a human readable string value
           
         @param value: boolean, the value to convert
         @return: A string of "Yes" or "No"
    """ 
    if(value):
        return "Yes"
    else:
        return "No"


def tableDisplay(keylist, colNames, output):
    """
         Logs into the BMC and creates a session
           
         @param keylist: list, keys for the output dictionary, ordered by colNames
         @param colNames: Names for the Table of the columns
         @param output: The dictionary of data to display
         @return: Session object
    """
    colWidth = setColWidth(keylist, len(colNames), output, colNames)
    row = ""
    outputText = ""
    for i in range(len(colNames)):
        if (i != 0): row = row + "| "
        row = row + colNames[i].ljust(colWidth[i])
    outputText += row + "\n"

    for key in sorted(output.keys()):
        row = ""
        for i in range(len(output[key])):
            if (i != 0): row = row + "| "
            row = row + output[key][keylist[i]].ljust(colWidth[i])
        outputText += row + "\n"
    
    return outputText

def login(host, username, pw,jsonFormat):
    """
         Logs into the BMC and creates a session
           
         @param host: string, the hostname or IP address of the bmc to log into
         @param username: The user name for the bmc to log into
         @param pw: The password for the BMC to log into
         @param jsonFormat: boolean, flag that will only allow relevant data from user command to be display. This function becomes silent when set to true. 
         @return: Session object
    """
    if(jsonFormat==False):
        print("Attempting login...")
    httpHeader = {'Content-Type':'application/json'}
    mysess = requests.session()
    try:
        r = mysess.post('https://'+host+'/login', headers=httpHeader, json = {"data": [username, pw]}, verify=False, timeout=30)
        loginMessage = json.loads(r.text)
        if (loginMessage['status'] != "ok"):
            print(loginMessage["data"]["description"].encode('utf-8')) 
            sys.exit(1)
#         if(sys.version_info < (3,0)):
#             urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
#         if sys.version_info >= (3,0):
#             requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)
        return mysess
    except(requests.exceptions.Timeout):
        print(connectionErrHandler(jsonFormat, "Timeout", None))
        sys.exit(1)
    except(requests.exceptions.ConnectionError) as err:
        print(connectionErrHandler(jsonFormat, "ConnectionError", err))
        sys.exit(1)

   
def logout(host, username, pw, session, jsonFormat):
    """
         Logs out of the bmc and terminates the session
           
         @param host: string, the hostname or IP address of the bmc to log out of
         @param username: The user name for the bmc to log out of
         @param pw: The password for the BMC to log out of
         @param session: the active session to use
         @param jsonFormat: boolean, flag that will only allow relevant data from user command to be display. This function becomes silent when set to true. 
    """ 
    httpHeader = {'Content-Type':'application/json'}
    try:
        r = session.post('https://'+host+'/logout', headers=httpHeader,json = {"data": [username, pw]}, verify=False, timeout=10)
    except(requests.exceptions.Timeout):
        print(connectionErrHandler(jsonFormat, "Timeout", None))
    
    if(jsonFormat==False):
        if('"message": "200 OK"' in r.text):
            print('User ' +username + ' has been logged out')

 
def fru(host, args, session):
    """
         prints out the system inventory. deprecated see fruPrint and fruList
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """  
    #url="https://"+host+"/org/openbmc/inventory/system/chassis/enumerate"
    
    #print(url)
    #res = session.get(url, headers=httpHeader, verify=False)
    #print(res.text)
    #sample = res.text
    
    #inv_list = json.loads(sample)["data"]
    
    url="https://"+host+"/xyz/openbmc_project/inventory/enumerate"
    httpHeader = {'Content-Type':'application/json'}
    try:
        res = session.get(url, headers=httpHeader, verify=False, timeout=40)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
        
    sample = res.text
#     inv_list.update(json.loads(sample)["data"])
#     
#     #determine column width's
#     colNames = ["FRU Name", "FRU Type", "Has Fault", "Is FRU", "Present", "Version"]
#     colWidths = setColWidth(["FRU Name", "fru_type", "fault", "is_fru", "present", "version"], 6, inv_list, colNames)
#    
#     print("FRU Name".ljust(colWidths[0])+ "FRU Type".ljust(colWidths[1]) + "Has Fault".ljust(colWidths[2]) + "Is FRU".ljust(colWidths[3])+ 
#           "Present".ljust(colWidths[4]) + "Version".ljust(colWidths[5]))
#     format the output
#     for key in sorted(inv_list.keys()):
#         keyParts = key.split("/")
#         isFRU = "True" if (inv_list[key]["is_fru"]==1) else "False"
#         
#         fruEntry = (keyParts[len(keyParts) - 1].ljust(colWidths[0]) + inv_list[key]["fru_type"].ljust(colWidths[1])+
#                inv_list[key]["fault"].ljust(colWidths[2])+isFRU.ljust(colWidths[3])+
#                inv_list[key]["present"].ljust(colWidths[4])+ inv_list[key]["version"].ljust(colWidths[5]))
#         if(isTTY):
#             if(inv_list[key]["is_fru"] == 1):
#                 color = "green"
#                 bold = True
#             else:
#                 color='black'
#                 bold = False
#             fruEntry = hilight(fruEntry, color, bold)
#         print (fruEntry)
    return sample

def fruPrint(host, args, session):  
    """
         prints out all inventory
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
         @return returns the total fru list. 
    """  
    url="https://"+host+"/xyz/openbmc_project/inventory/enumerate"
    httpHeader = {'Content-Type':'application/json'}
    try:
        res = session.get(url, headers=httpHeader, verify=False, timeout=40)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))


#     print(res.text)
    frulist = res.text
    url="https://"+host+"/xyz/openbmc_project/software/enumerate"
    try:
        res = session.get(url, headers=httpHeader, verify=False, timeout=40)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
#     print(res.text)
    frulist = frulist +"\n" + res.text
    
    return frulist


def fruList(host, args, session):
    """
         prints out all inventory or only a specific specified item
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    if(args.items==True):
        return fruPrint(host, args, session)
    else:
        return fruPrint(host, args, session)


       
def fruStatus(host, args, session):
    """
         prints out the status of all FRUs
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """  
    url="https://"+host+"/xyz/openbmc_project/inventory/enumerate"
    httpHeader = {'Content-Type':'application/json'}
    try:
        res = session.get(url, headers=httpHeader, verify=False)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
#     print(res.text)
    frulist = json.loads(res.text)['data']
    frus = {}
    for key in frulist:
        component = frulist[key]
        isFru = False
        present = False
        func = False
        hasSels = False
        keyPieces = key.split('/')
        fruName = keyPieces[-1]
        if 'core' in fruName: #associate cores to cpus
            fruName = keyPieces[-2] + '-' + keyPieces[-1]
        if 'Functional' in component:
            if('Present' in component):
                
                if 'FieldReplaceable' in component:
                    if component['FieldReplaceable'] == 1:
                        isFru = True
                if "fan" in fruName:
                    isFru = True;
                if component['Present'] == 1:
                    present = True
                if component['Functional'] == 1:
                    func = True
                if ((key + "/fault") in frulist):
                    hasSels = True;
                if args.verbose:
                    if hasSels:
                        loglist = []
                        faults = frulist[key+"/fault"]['endpoints']
                        for item in faults:
                            loglist.append(item.split('/')[-1])
                        frus[fruName] = {"compName": fruName, "Functional": boolToString(func), "Present":boolToString(present), "IsFru": boolToString(isFru), "selList": ', '.join(loglist).strip() }
                    else:
                        frus[fruName] = {"compName": fruName, "Functional": boolToString(func), "Present":boolToString(present), "IsFru": boolToString(isFru), "selList": "None" }
                else:
                    frus[fruName] = {"compName": fruName, "Functional": boolToString(func), "Present":boolToString(present), "IsFru": boolToString(isFru), "hasSEL": boolToString(hasSels) }
        elif "power_supply" in fruName:
            if component['Present'] ==1:
                present = True
            isFru = True
            if ((key + "/fault") in frulist):
                hasSels = True;
            if args.verbose:
                if hasSels:
                    loglist = []
                    faults = frulist[key+"/fault"]['endpoints']
                    for key in faults:
                        loglist.append(faults[key].split('/')[-1])
                    frus[fruName] = {"compName": fruName, "Functional": "No", "Present":boolToString(present), "IsFru": boolToString(isFru), "selList": ', '.join(loglist).strip() }
                else:
                    frus[fruName] = {"compName": fruName, "Functional": "Yes", "Present":boolToString(present), "IsFru": boolToString(isFru), "selList": "None" }
            else:
                frus[fruName] = {"compName": fruName, "Functional": boolToString(not hasSels), "Present":boolToString(present), "IsFru": boolToString(isFru), "hasSEL": boolToString(hasSels) }
    if not args.json:
        if not args.verbose:
            colNames = ["Component", "Is a FRU", "Present", "Functional", "Has Logs"]
            keylist = ["compName", "IsFru", "Present", "Functional", "hasSEL"]
        else:
            colNames = ["Component", "Is a FRU", "Present", "Functional", "Assoc. Log Number(s)"]
            keylist = ["compName", "IsFru", "Present", "Functional", "selList"]
        return tableDisplay(keylist, colNames, frus)
    else:
        return str(json.dumps(frus, sort_keys=True, indent=4, separators=(',', ': '), ensure_ascii=False))
      
def sensor(host, args, session):
    """
         prints out all sensors
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the sensor sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """  
    httpHeader = {'Content-Type':'application/json'}
    url="https://"+host+"/xyz/openbmc_project/sensors/enumerate"
    try:
        res = session.get(url, headers=httpHeader, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
    
    #Get OCC status
    url="https://"+host+"/org/open_power/control/enumerate"
    try:
        occres = session.get(url, headers=httpHeader, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
    if not args.json:
        colNames = ['sensor', 'type', 'units', 'value', 'target']
        sensors = json.loads(res.text)["data"]
        output = {}
        for key in sensors:
            senDict = {}
            keyparts = key.split("/")
            senDict['sensorName'] = keyparts[-1]
            senDict['type'] = keyparts[-2]
            try:
                senDict['units'] = sensors[key]['Unit'].split('.')[-1]
            except KeyError:
                print('Key Error: '+ key)
            if('Scale' in sensors[key]): 
                scale = 10 ** sensors[key]['Scale'] 
            else: 
                scale = 1
            senDict['value'] = str(sensors[key]['Value'] * scale)
            if 'Target' in sensors[key]:
                senDict['target'] = str(sensors[key]['Target'])
            else:
                senDict['target'] = 'N/A'
            output[senDict['sensorName']] = senDict
        
        occstatus = json.loads(occres.text)["data"]
        if '/org/open_power/control/occ0' in occstatus:
            occ0 = occstatus["/org/open_power/control/occ0"]['OccActive']
            if occ0 == 1: 
                occ0 = 'Active' 
            else: 
                occ0 = 'Inactive'
            output['OCC0'] = {'sensorName':'OCC0', 'type': 'Discrete', 'units': 'N/A', 'value': occ0, 'target': 'Active'}
            occ1 = occstatus["/org/open_power/control/occ1"]['OccActive']
            if occ1 == 1: 
                occ1 = 'Active' 
            else: 
                occ1 = 'Inactive'
            output['OCC1'] = {'sensorName':'OCC1', 'type': 'Discrete', 'units': 'N/A', 'value': occ0, 'target': 'Active'}
        else:
            output['OCC0'] = {'sensorName':'OCC0', 'type': 'Discrete', 'units': 'N/A', 'value': 'Inactive', 'target': 'Inactive'}
            output['OCC1'] = {'sensorName':'OCC1', 'type': 'Discrete', 'units': 'N/A', 'value': 'Inactive', 'target': 'Inactive'}
        keylist = ['sensorName', 'type', 'units', 'value', 'target']

        return tableDisplay(keylist, colNames, output)
    else:
        return res.text + occres.text
  
def sel(host, args, session):
    """
         prints out the bmc alerts
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the sel sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """   

    url="https://"+host+"/xyz/openbmc_project/logging/entry/enumerate"
    httpHeader = {'Content-Type':'application/json'}
    try:
        res = session.get(url, headers=httpHeader, verify=False, timeout=60)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
    return res.text
 
  
def parseESEL(args, eselRAW):
    """
         parses the esel data and gets predetermined search terms
           
         @param eselRAW: string, the raw esel string from the bmc
         @return: A dictionary containing the quick snapshot data unless args.fullEsel is listed then a full PEL log is returned
    """  
    eselParts = {}
    esel_bin = binascii.unhexlify(''.join(eselRAW.split()[16:]))
    #search terms contains the search term as the key and the return dictionary key as it's value
    searchTerms = { 'Signature Description':'signatureDescription', 'devdesc':'devdesc',
                    'Callout type': 'calloutType', 'Procedure':'procedure'}
    
    with open('/tmp/esel.bin', 'wb') as f:
        f.write(esel_bin)
    errlPath = ""
    #use the right errl file for the machine architecture
    arch = platform.machine()
    if(arch =='x86_64' or arch =='AMD64'):
        if os.path.exists('/opt/ibm/ras/bin/x86_64/errl'):
            errlPath = '/opt/ibm/ras/bin/x86_64/errl'
        elif os.path.exists('errl/x86_64/errl'):
            errlPath = 'errl/x86_64/errl'
        else:
            errlPath = 'x86_64/errl'
    elif (platform.machine()=='ppc64le'):
        if os.path.exists('/opt/ibm/ras/bin/ppc64le/errl'):
            errlPath = '/opt/ibm/ras/bin/ppc64le/errl'
        elif os.path.exists('errl/ppc64le/errl'):
            errlPath = 'errl/ppc64le/errl'
        else:
            errlPath = 'ppc64le/errl'
    else:
        print("machine architecture not supported for parsing eSELs")
        return eselParts
    
    if(os.path.exists(errlPath)):
        output= subprocess.check_output([errlPath, '-d', '--file=/tmp/esel.bin']).decode('utf-8')
#         output = proc.communicate()[0]
        lines = output.split('\n')
        
        if(hasattr(args, 'fullEsel')):
            return output
        
        for i in range(0, len(lines)):
            lineParts = lines[i].split(':')
            if(len(lineParts)>1): #ignore multi lines, output formatting lines, and other information
                for term in searchTerms:
                    if(term in lineParts[0]):
                        temp = lines[i][lines[i].find(':')+1:].strip()[:-1].strip()
                        if lines[i+1].find(':') != -1:
                            if (len(lines[i+1].split(':')[0][1:].strip())==0):
                                while(len(lines[i][:lines[i].find(':')].strip())>2):
                                    if((i+1) <= len(lines)):
                                        i+=1
                                    else:
                                        i=i-1
                                        break
                                    temp = temp + lines[i][lines[i].find(':'):].strip()[:-1].strip()[:-1].strip()
                        eselParts[searchTerms[term]] = temp
        os.remove('/tmp/esel.bin')
    else:
        print("errl file cannot be found")
    
    return eselParts                


def sortSELs(events):
    """
         sorts the sels by timestamp, then log entry number
           
         @param events: Dictionary containing events
         @return: list containing a list of the ordered log entries, and dictionary of keys
    """ 
    logNumList = []
    timestampList = []
    eventKeyDict = {} 
    eventsWithTimestamp = {}
    logNum2events = {}
    for key in events:
        if key == 'numAlerts': continue
        if 'callout' in key: continue
        timestamp = (events[key]['timestamp'])
        if timestamp not in timestampList:
            eventsWithTimestamp[timestamp] = [events[key]['logNum']]
        else:
            eventsWithTimestamp[timestamp].append(events[key]['logNum'])
        #map logNumbers to the event dictionary keys
        eventKeyDict[str(events[key]['logNum'])] = key
        
    timestampList = list(eventsWithTimestamp.keys())
    timestampList.sort()
    for ts in timestampList:
        if len(eventsWithTimestamp[ts]) > 1:
            tmplist = eventsWithTimestamp[ts]
            tmplist.sort()
            logNumList = logNumList + tmplist
        else:
            logNumList = logNumList + eventsWithTimestamp[ts]
    
    return [logNumList, eventKeyDict]


def parseAlerts(policyTable, selEntries, args):
    """
         parses alerts in the IBM CER format, using an IBM policy Table
           
         @param policyTable: dictionary, the policy table entries
         @param selEntries: dictionary, the alerts retrieved from the bmc
         @return: A dictionary of the parsed entries, in chronological order
    """ 
    eventDict = {}
    eventNum =""
    count = 0
    esel = ""
    eselParts = {}
    i2cdevice= ""
    
    'prepare and sort the event entries'
    for key in selEntries:
        if 'callout' not in key:
            selEntries[key]['logNum'] = key.split('/')[-1]
            selEntries[key]['timestamp'] = selEntries[key]['Timestamp']
    sortedEntries = sortSELs(selEntries)
    logNumList = sortedEntries[0]
    eventKeyDict = sortedEntries[1]
    
    for logNum in logNumList:
        key = eventKeyDict[logNum]
        hasEsel=False
        i2creadFail = False
        if 'callout' in key:
            continue
        else:
            messageID = str(selEntries[key]['Message'])
            addDataPiece = selEntries[key]['AdditionalData']
            calloutIndex = 0
            calloutFound = False
            for i in range(len(addDataPiece)):
                if("CALLOUT_INVENTORY_PATH" in addDataPiece[i]):
                    calloutIndex = i
                    calloutFound = True
                    fruCallout = str(addDataPiece[calloutIndex]).split('=')[1]
                if("CALLOUT_DEVICE_PATH" in addDataPiece[i]):
                    i2creadFail = True
                    i2cdevice = str(addDataPiece[i]).strip().split('=')[1]
                    i2cdevice = '/'.join(i2cdevice.split('/')[-4:])
                    fruCallout = 'I2C'
                    calloutFound = True
                if("ESEL" in addDataPiece[i]):
                    esel = str(addDataPiece[i]).strip().split('=')[1]
                    if args.devdebug:
                        eselParts = parseESEL(args, esel)
                    hasEsel=True
                if("GPU" in addDataPiece[i]):
                    fruCallout = '/xyz/openbmc_project/inventory/system/chassis/motherboard/gpu' + str(addDataPiece[i]).strip()[-1]
                    calloutFound = True
                if("PROCEDURE" in addDataPiece[i]):
                    fruCallout = str(hex(int(str(addDataPiece[i]).split('=')[1])))[2:]
                    calloutFound = True
                if("RAIL_NAME" in addDataPiece[i]):
                    calloutFound=True
                    fruCallout = str(addDataPiece[i]).split('=')[1].strip()
                if("INPUT_NAME" in addDataPiece[i]):
                    calloutFound=True
                    fruCallout = str(addDataPiece[i]).split('=')[1].strip()
                if("SENSOR_TYPE" in addDataPiece[i]):
                    calloutFound=True
                    fruCallout = str(addDataPiece[i]).split('=')[1].strip()
                    
            if(calloutFound):
                policyKey = messageID +"||" +  fruCallout
            else:
                policyKey = messageID
            event = {}
            eventNum = str(count)
            if policyKey in policyTable:
                for pkey in policyTable[policyKey]:
                    if(type(policyTable[policyKey][pkey])== bool):
                        event[pkey] = boolToString(policyTable[policyKey][pkey])
                    else:
                        if (i2creadFail and pkey == 'Message'):
                            event[pkey] = policyTable[policyKey][pkey] + ' ' +i2cdevice
                        else:
                            event[pkey] = policyTable[policyKey][pkey]
                event['timestamp'] = selEntries[key]['Timestamp']
                event['resolved'] = bool(selEntries[key]['Resolved'])
                if(hasEsel):
                    if args.devdebug:
                        event['eselParts'] = eselParts
                    event['raweSEL'] = esel
                event['logNum'] = key.split('/')[-1]
                eventDict['event' + eventNum] = event
                
            else:
                severity = str(selEntries[key]['Severity']).split('.')[-1]
                if severity == 'Error':
                    severity = 'Critical'
                eventDict['event'+eventNum] = {}
                eventDict['event' + eventNum]['error'] = "error: Not found in policy table: " + policyKey
                eventDict['event' + eventNum]['timestamp'] = selEntries[key]['Timestamp']
                eventDict['event' + eventNum]['Severity'] = severity
                if(hasEsel):
                    if args.devdebug:
                        eventDict['event' +eventNum]['eselParts'] = eselParts
                    eventDict['event' +eventNum]['raweSEL'] = esel
                eventDict['event' +eventNum]['logNum'] = key.split('/')[-1]
                eventDict['event' +eventNum]['resolved'] = bool(selEntries[key]['Resolved'])
            count += 1
    return eventDict


def selDisplay(events, args):
    """
         displays alerts in human readable format
           
         @param events: Dictionary containing events
         @return: 
    """ 
    activeAlerts = []
    historyAlerts = []
    sortedEntries = sortSELs(events)
    logNumList = sortedEntries[0]
    eventKeyDict = sortedEntries[1]
    keylist = ['Entry', 'ID', 'Timestamp', 'Serviceable', 'Severity','Message']
    if(args.devdebug):
        colNames = ['Entry', 'ID', 'Timestamp', 'Serviceable', 'Severity','Message',  'eSEL contents']
        keylist.append('eSEL')
    else:
        colNames = ['Entry', 'ID', 'Timestamp', 'Serviceable', 'Severity', 'Message']
    for log in logNumList:
        selDict = {}
        alert = events[eventKeyDict[str(log)]]
        if('error' in alert):
            selDict['Entry'] = alert['logNum']
            selDict['ID'] = 'Unknown'
            selDict['Timestamp'] = datetime.datetime.fromtimestamp(int(alert['timestamp']/1000)).strftime("%Y-%m-%d %H:%M:%S")
            msg = alert['error']
            polMsg = msg.split("policy table:")[0]
            msg = msg.split("policy table:")[1]
            msgPieces = msg.split("||")
            err = msgPieces[0]
            if(err.find("org.open_power.")!=-1):
                err = err.split("org.open_power.")[1]
            elif(err.find("xyz.openbmc_project.")!=-1):
                err = err.split("xyz.openbmc_project.")[1]
            else:
                err = msgPieces[0]
            callout = ""
            if len(msgPieces) >1:
                callout = msgPieces[1]
                if(callout.find("/org/open_power/")!=-1):
                    callout = callout.split("/org/open_power/")[1]
                elif(callout.find("/xyz/openbmc_project/")!=-1):
                    callout = callout.split("/xyz/openbmc_project/")[1]
                else:
                    callout = msgPieces[1]
            selDict['Message'] = polMsg +"policy table: "+ err +  "||" + callout
            selDict['Serviceable'] = 'Unknown'  
            selDict['Severity'] = alert['Severity']
        else:
            selDict['Entry'] = alert['logNum']
            selDict['ID'] = alert['CommonEventID']
            selDict['Timestamp'] = datetime.datetime.fromtimestamp(int(alert['timestamp']/1000)).strftime("%Y-%m-%d %H:%M:%S")
            selDict['Message'] = alert['Message'] 
            selDict['Serviceable'] = alert['Serviceable']  
            selDict['Severity'] = alert['Severity']
        
               
        eselOrder = ['refCode','signatureDescription', 'eselType', 'devdesc', 'calloutType', 'procedure']
        if ('eselParts' in alert and args.devdebug):
            eselOutput = ""
            for item in eselOrder:
                if item in alert['eselParts']:
                    eselOutput = eselOutput + item + ": " + alert['eselParts'][item] + " | "
            selDict['eSEL'] = eselOutput
        else:
            if args.devdebug:
                selDict['eSEL'] = "None"
        
        if not alert['resolved']:
            activeAlerts.append(selDict)
        else:
            historyAlerts.append(selDict)
    mergedOutput = activeAlerts + historyAlerts
    colWidth = setColWidth(keylist, len(colNames), dict(enumerate(mergedOutput)), colNames) 
    
    output = ""
    if(len(activeAlerts)>0):
        row = ""   
        output +="----Active Alerts----\n"
        for i in range(0, len(colNames)):
            if i!=0: row =row + "| "
            row = row + colNames[i].ljust(colWidth[i])
        output += row + "\n"
    
        for i in range(0,len(activeAlerts)):
            row = ""
            for j in range(len(activeAlerts[i])):
                if (j != 0): row = row + "| "
                row = row + activeAlerts[i][keylist[j]].ljust(colWidth[j])
            output += row + "\n"
    
    if(len(historyAlerts)>0): 
        row = ""   
        output+= "----Historical Alerts----\n"   
        for i in range(len(colNames)):
            if i!=0: row =row + "| "
            row = row + colNames[i].ljust(colWidth[i])
        output += row + "\n"
    
        for i in range(0, len(historyAlerts)):
            row = ""
            for j in range(len(historyAlerts[i])):
                if (j != 0): row = row + "| "
                row = row + historyAlerts[i][keylist[j]].ljust(colWidth[j])
            output += row + "\n"
#         print(events[eventKeyDict[str(log)]])
    return output        


def selPrint(host, args, session):
    """
         prints out all bmc alerts
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    if(args.policyTableLoc is None):
        if os.path.exists('policyTable.json'):
            ptableLoc = "policyTable.json"
        elif os.path.exists('/opt/ibm/ras/lib/policyTable.json'):
            ptableLoc = '/opt/ibm/ras/lib/policyTable.json'
        else:
            ptableLoc = 'lib/policyTable.json'
    else:
        ptableLoc = args.policyTableLoc
    policyTable = loadPolicyTable(ptableLoc)
    rawselEntries = ""
    if(hasattr(args, 'fileloc') and args.fileloc is not None):
        if os.path.exists(args.fileloc):
            with open(args.fileloc, 'r') as selFile:
                selLines = selFile.readlines()
            rawselEntries = ''.join(selLines)
        else:
            print("Error: File not found")
            sys.exit(1) 
    else:
        rawselEntries = sel(host, args, session)
    loadFailed = False
    try:
        selEntries = json.loads(rawselEntries)
    except ValueError:
        loadFailed = True
    if loadFailed:
        cleanSels = json.dumps(rawselEntries).replace('\\n', '')
        #need to load json twice as original content was string escaped a second time
        selEntries = json.loads(json.loads(cleanSels))
    selEntries = selEntries['data']

    if 'description' in selEntries:
        if(args.json):
            return("{\n\t\"numAlerts\": 0\n}")
        else:
            return("No log entries found")
        
    else:
        if(len(policyTable)>0):
            events = parseAlerts(policyTable, selEntries, args)
            if(args.json):
                events["numAlerts"] = len(events)
                retValue = str(json.dumps(events, sort_keys=True, indent=4, separators=(',', ': '), ensure_ascii=False))
                return retValue
            elif(hasattr(args, 'fullSel')):
                return events
            else:
                #get log numbers to order event entries sequentially
                return selDisplay(events, args)
        else:
            if(args.json):
                return selEntries
            else:
                print("error: Policy Table not found.")
                return selEntries
    
def selList(host, args, session):
    """
         prints out all all bmc alerts, or only prints out the specified alerts
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    return(sel(host, args, session))

     
def selClear(host, args, session):
    """
         clears all alerts
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    url="https://"+host+"/xyz/openbmc_project/logging/action/deleteAll"
    httpHeader = {'Content-Type':'application/json'}
    data = "{\"data\": [] }"
    
    try:
        res = session.post(url, headers=httpHeader, data=data, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
    if res.status_code == 200:
        return "The Alert Log has been cleared. Please allow a few minutes for the action to complete."
    else:
        print("Unable to clear the logs, trying to clear 1 at a time")
        sels = json.loads(sel(host, args, session))['data']
        for key in sels:
            if 'callout' not in key:
                logNum = key.split('/')[-1]
                url = "https://"+ host+ "/xyz/openbmc_project/logging/entry/"+logNum+"/action/Delete"
                try:
                    session.post(url, headers=httpHeader, data=data, verify=False, timeout=30)
                except(requests.exceptions.Timeout):
                    return connectionErrHandler(args.json, "Timeout", None)
                    sys.exit(1)
                except(requests.exceptions.ConnectionError) as err:
                    return connectionErrHandler(args.json, "ConnectionError", err)
                    sys.exit(1)
        return ('Sel clearing complete')

def selSetResolved(host, args, session):
    """
         sets a sel entry to resolved
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    url="https://"+host+"/xyz/openbmc_project/logging/entry/" + str(args.selNum) + "/attr/Resolved"
    httpHeader = {'Content-Type':'application/json'}
    data = "{\"data\": 1 }"
    try:
        res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return(connectionErrHandler(args.json, "Timeout", None))
    if res.status_code == 200:
        return "Sel entry "+ str(args.selNum) +" is now set to resolved"
    else:
        return "Unable to set the alert to resolved"

def selResolveAll(host, args, session):
    """
         sets a sel entry to resolved
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    rawselEntries = sel(host, args, session)
    loadFailed = False
    try:
        selEntries = json.loads(rawselEntries)
    except ValueError:
        loadFailed = True
    if loadFailed:
        cleanSels = json.dumps(rawselEntries).replace('\\n', '')
        #need to load json twice as original content was string escaped a second time
        selEntries = json.loads(json.loads(cleanSels))
    selEntries = selEntries['data']

    if 'description' in selEntries:
        if(args.json):
            return("{\n\t\"selsResolved\": 0\n}")
        else:
            return("No log entries found")
    else:
        d = vars(args)
        successlist = []
        failedlist = []
        for key in selEntries:
            if 'callout' not in key:
                d['selNum'] = key.split('/')[-1]
                resolved = selSetResolved(host,args,session)
                if 'Sel entry' in resolved:
                    successlist.append(d['selNum'])
                else:
                    failedlist.append(d['selNum'])
        output = ""
        successlist.sort()
        failedlist.sort()
        if len(successlist)>0:
            output = "Successfully resolved: " +', '.join(successlist) +"\n"
        if len(failedlist)>0:
            output += "Failed to resolve: " + ', '.join(failedlist) + "\n"
        return output

def chassisPower(host, args, session):
    """
         called by the chassis function. Controls the power state of the chassis, or gets the status
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    if(args.powcmd == 'on'):
        print("Attempting to Power on...:")
        url="https://"+host+"/xyz/openbmc_project/state/host0/attr/RequestedHostTransition"
        httpHeader = {'Content-Type':'application/json',}
        data = '{"data":"xyz.openbmc_project.State.Host.Transition.On"}'
        try:
            res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        return res.text
    elif(args.powcmd == 'softoff'):
        print("Attempting to Power off gracefully...:")
        url="https://"+host+"/xyz/openbmc_project/state/host0/attr/RequestedHostTransition"
        httpHeader = {'Content-Type':'application/json'}
        data = '{"data":"xyz.openbmc_project.State.Host.Transition.Off"}'
        try:
            res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        return res.text
    elif(args.powcmd == 'hardoff'):
        print("Attempting to Power off immediately...:")
        url="https://"+host+"/xyz/openbmc_project/state/chassis0/attr/RequestedPowerTransition"
        httpHeader = {'Content-Type':'application/json'}
        data = '{"data":"xyz.openbmc_project.State.Chassis.Transition.Off"}'
        try:
            res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        return res.text
    elif(args.powcmd == 'status'):
        url="https://"+host+"/xyz/openbmc_project/state/chassis0/attr/CurrentPowerState"
        httpHeader = {'Content-Type':'application/json'}
#         print(url)
        try:
            res = session.get(url, headers=httpHeader, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        chassisState = json.loads(res.text)['data'].split('.')[-1]
        url="https://"+host+"/xyz/openbmc_project/state/host0/attr/CurrentHostState"
        try:
            res = session.get(url, headers=httpHeader, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        hostState = json.loads(res.text)['data'].split('.')[-1]
        url="https://"+host+"/xyz/openbmc_project/state/bmc0/attr/CurrentBMCState"
        try:
            res = session.get(url, headers=httpHeader, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        bmcState = json.loads(res.text)['data'].split('.')[-1]
        if(args.json):
            outDict = {"Chassis Power State" : chassisState, "Host Power State" : hostState, "BMC Power State":bmcState}
            return json.dumps(outDict, sort_keys=True, indent=4, separators=(',', ': '), ensure_ascii=False)
        else:
            return "Chassis Power State: " +chassisState + "\nHost Power State: " + hostState + "\nBMC Power State: " + bmcState
    else:
        return "Invalid chassis power command"


def chassisIdent(host, args, session):
    """
         called by the chassis function. Controls the identify led of the chassis. Sets or gets the state
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """
    if(args.identcmd == 'on'):
        print("Attempting to turn identify light on...:")
        url="https://"+host+"/xyz/openbmc_project/led/groups/enclosure_identify/attr/Asserted"
        httpHeader = {'Content-Type':'application/json',}
        data = '{"data":true}'
        try:
            res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        return res.text
    elif(args.identcmd == 'off'):
        print("Attempting to turn identify light off...:")
        url="https://"+host+"/xyz/openbmc_project/led/groups/enclosure_identify/attr/Asserted"
        httpHeader = {'Content-Type':'application/json'}
        data = '{"data":false}'
        try:
            res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        return res.text
    elif(args.identcmd == 'status'):
        url="https://"+host+"/xyz/openbmc_project/led/groups/enclosure_identify"
        httpHeader = {'Content-Type':'application/json'}
        try:
            res = session.get(url, headers=httpHeader, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return(connectionErrHandler(args.json, "Timeout", None))
        status = json.loads(res.text)['data']
        if(args.json):
            return status
        else:
            if status['Asserted'] == 0:
                return "Identify light is off"
            else:
                return "Identify light is blinking"
    else:
        return "Invalid chassis identify command"


def chassis(host, args, session):
    """
         controls the different chassis commands
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fru sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    if(hasattr(args, 'powcmd')):
        result = chassisPower(host,args,session)
    elif(hasattr(args, 'identcmd')):
        result = chassisIdent(host, args, session)
    else:
        return "to be completed"
    return result

def bmcDumpRetrieve(host, args, session):
    """
         Downloads a dump file from the bmc
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the collectServiceData sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """
    httpHeader = {'Content-Type':'application/json'}
    dumpNum = args.dumpNum
    if (args.dumpSaveLoc is not None):
        saveLoc = args.dumpSaveLoc
    else:
        saveLoc = '/tmp'
    url ='https://'+host+'/download/dump/' + str(dumpNum)
    try:
        r = session.get(url, headers=httpHeader, stream=True, verify=False, timeout=30)
        if (args.dumpSaveLoc is not None):
            if os.path.exists(saveLoc):
                if saveLoc[-1] != os.path.sep:
                    saveLoc = saveLoc + os.path.sep
                filename = saveLoc + host+'-dump' + str(dumpNum) + '.tar.xz'
                
            else:
                return 'Invalid save location specified'
        else:
            filename = '/tmp/' + host+'-dump' + str(dumpNum) + '.tar.xz'

        with open(filename, 'wb') as f:
                    for chunk in r.iter_content(chunk_size =1024):
                        if chunk:
                            f.write(chunk)
        return 'Saved as ' + filename
        
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
        
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)

def bmcDumpList(host, args, session): 
    """
         Lists the number of dump files on the bmc
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the collectServiceData sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """   
    httpHeader = {'Content-Type':'application/json'}
    url ='https://'+host+'/xyz/openbmc_project/dump/list'
    try:
        r = session.get(url, headers=httpHeader, verify=False, timeout=20)
        dumpList = json.loads(r.text)
        return r.text
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
        
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)        
 
def bmcDumpDelete(host, args, session):
    """
         Deletes BMC dump files from the bmc
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the collectServiceData sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """
    httpHeader = {'Content-Type':'application/json'}
    dumpList = []
    successList = []
    failedList = []
    if args.dumpNum is not None:
        if isinstance(args.dumpNum, list):
            dumpList = args.dumpNum
        else:
            dumpList.append(args.dumpNum)
        for dumpNum in dumpList:
            url ='https://'+host+'/xyz/openbmc_project/dump/entry/'+str(dumpNum)+'/action/Delete'
            try:
                r = session.post(url, headers=httpHeader, json = {"data": []}, verify=False, timeout=30)
                if r.status_code == 200:
                    successList.append(str(dumpNum))
                else:
                    failedList.append(str(dumpNum))
            except(requests.exceptions.Timeout):
                return connectionErrHandler(args.json, "Timeout", None)
            except(requests.exceptions.ConnectionError) as err:
                return connectionErrHandler(args.json, "ConnectionError", err)
        output = "Successfully deleted dumps: " + ', '.join(successList)
        if(len(failedList)>0):
            output+= '\nFailed to delete dumps: ' + ', '.join(failedList)
        return output
    else:
        return 'You must specify an entry number to delete'

def bmcDumpDeleteAll(host, args, session):
    """
         Deletes All BMC dump files from the bmc
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the collectServiceData sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """
    dumpResp = bmcDumpList(host, args, session)
    if 'FQPSPIN0000M' in dumpResp or 'FQPSPIN0001M'in dumpResp:
        return dumpResp
    dumpList = json.loads(dumpResp)['data']
    d = vars(args)
    dumpNums = []
    for dump in dumpList:
        if '/xyz/openbmc_project/dump/internal/manager' not in dump:
            dumpNums.append(int(dump.strip().split('/')[-1]))
    d['dumpNum'] = dumpNums
    
    return bmcDumpDelete(host, args, session)
    

def bmcDumpCreate(host, args, session):
    """
         Creates a bmc dump file
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the collectServiceData sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """
    httpHeader = {'Content-Type':'application/json'}
    url = 'https://'+host+'/xyz/openbmc_project/dump/action/CreateDump'
    try:
        r = session.post(url, headers=httpHeader, json = {"data": []}, verify=False, timeout=30)
        if('"message": "200 OK"' in r.text and not args.json):
            return ('Dump successfully created')
        else:
            return ('Failed to create dump')
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)
        
   
    

def collectServiceData(host, args, session):
    """
         Collects all data needed for service from the BMC
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the collectServiceData sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """
    #create a bmc dump
    dumpcount = len(json.loads(bmcDumpList(host, args, session))['data'])
    try:
        dumpcreated = bmcDumpCreate(host, args, session)
    except Exception as e:
        print('failed to create a bmc dump')
    
    
    #Collect Inventory
    try:
        args.silent = True
        myDir = '/tmp/' + host + "--" + datetime.datetime.now().strftime("%Y-%m-%d_%H.%M.%S")
        os.makedirs(myDir)
        filelist = []
        frulist = fruPrint(host, args, session)
        with open(myDir +'/inventory.txt', 'w') as f:
            f.write(frulist)
        print("Inventory collected and stored in " + myDir + "/inventory.txt")
        filelist.append(myDir+'/inventory.txt')
    except Exception as e:
        print("Failed to collect inventory")
    
    #Read all the sensor and OCC status
    try:
        sensorReadings = sensor(host, args, session)
        with open(myDir +'/sensorReadings.txt', 'w') as f:
            f.write(sensorReadings)
        print("Sensor readings collected and stored in " +myDir + "/sensorReadings.txt")
        filelist.append(myDir+'/sensorReadings.txt')
    except Exception as e:
        print("Failed to collect sensor readings")
    
    #Collect all of the LEDs status
    try:
        url="https://"+host+"/xyz/openbmc_project/led/enumerate"
        httpHeader = {'Content-Type':'application/json'}
        leds = session.get(url, headers=httpHeader, verify=False, timeout=20)
        with open(myDir +'/ledStatus.txt', 'w') as f:
            f.write(leds.text)
        print("System LED status collected and stored in "+myDir +"/ledStatus.txt")
        filelist.append(myDir+'/ledStatus.txt')
    except Exception as e:
        print("Failed to collect LED status")
    
    #Collect the bmc logs
    try:
        sels = selPrint(host,args,session)
        with open(myDir +'/SELshortlist.txt', 'w') as f:
            f.write(str(sels))
        print("sel short list collected and stored in "+myDir +"/SELshortlist.txt")
        filelist.append(myDir+'/SELshortlist.txt')
        time.sleep(2)
        
        d = vars(args)
        d['json'] = True
        d['fullSel'] = True
        parsedfullsels = json.loads(selPrint(host, args, session))
        d['fullEsel'] = True
        sortedSELs = sortSELs(parsedfullsels)
        with open(myDir +'/parsedSELs.txt', 'w') as f:
            for log in sortedSELs[0]:
                esel = ""
                parsedfullsels[sortedSELs[1][str(log)]]['timestamp'] = datetime.datetime.fromtimestamp(int(parsedfullsels[sortedSELs[1][str(log)]]['timestamp']/1000)).strftime("%Y-%m-%d %H:%M:%S")
                if ('raweSEL' in parsedfullsels[sortedSELs[1][str(log)]] and args.devdebug):
                    esel = parsedfullsels[sortedSELs[1][str(log)]]['raweSEL'] 
                    del parsedfullsels[sortedSELs[1][str(log)]]['raweSEL'] 
                f.write(json.dumps(parsedfullsels[sortedSELs[1][str(log)]],sort_keys=True, indent=4, separators=(',', ': ')))
                if(args.devdebug and esel != ""):
                    f.write(parseESEL(args, esel))
        print("fully parsed sels collected and stored in "+myDir +"/parsedSELs.txt")
        filelist.append(myDir+'/parsedSELs.txt')
    except Exception as e:
        print("Failed to collect system event logs")
        print(e)
    
    #collect RAW bmc enumeration
    try:    
        url="https://"+host+"/xyz/openbmc_project/enumerate"
        print("Attempting to get a full BMC enumeration")
        fullDump = session.get(url, headers=httpHeader, verify=False, timeout=120)
        with open(myDir +'/bmcFullRaw.txt', 'w') as f:
            f.write(fullDump.text)
        print("RAW BMC data collected and saved into "+myDir +"/bmcFullRaw.txt")
        filelist.append(myDir+'/bmcFullRaw.txt')
    except Exception as e:
        print("Failed to collect bmc full enumeration")
     
    #collect the dump files 
    waitingForNewDump = True
    count = 0;
    while(waitingForNewDump):   
        dumpList = json.loads(bmcDumpList(host, args, session))['data']
        if len(dumpList) > dumpcount:
            waitingForNewDump = False
            break;
        elif(count>30):
            print("Timed out waiting for bmc to make a new dump file. Dump space may be full.")
            break;
        else:
            time.sleep(2)
        count += 1
    try:    
        print('Collecting bmc dump files')
        d['dumpSaveLoc'] = myDir
        dumpList = json.loads(bmcDumpList(host, args, session))['data']
        for dump in dumpList:
            if '/xyz/openbmc_project/dump/internal/manager' not in dump:
                d['dumpNum'] = int(dump.strip().split('/')[-1])
                print('retrieving dump file ' + str(d['dumpNum']))
                filename = bmcDumpRetrieve(host, args, session).split('Saved as ')[-1]
                filelist.append(filename)
                time.sleep(2)
    except Exception as e:
        print("Failed to collect bmc dump files")
        print(e)
        
    #create the zip file
    try:    
        filename = myDir.split('/tmp/')[-1] + '.zip'
        zf = zipfile.ZipFile(myDir+'/' + filename, 'w')
        for myfile in filelist:
            zf.write(myfile, os.path.basename(myfile))
        zf.close()
    except Exception as e:
        print("Failed to create zip file with collected information")
    return "data collection complete"


def healthCheck(host, args, session):
    """
         runs a health check on the platform
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the bmc sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    #check fru status and get as json to easily work through
    d = vars(args)
    useJson = d['json']
    d['json'] = True
    d['verbose']= False
    
    frus = json.loads(fruStatus(host, args, session))
    
    hwStatus= "OK"
    performanceStatus = "OK"
    for key in frus:
        if frus[key]["Functional"] == "No" and frus[key]["Present"] == "Yes":
            hwStatus= "Degraded"
            if("power_supply" in key):
                gpuCount =0;
                frulist = json.loads(fruList(host, args, session))
                for comp in frulist:
                    if "gv100card" in comp:
                        gpuCount +=1
                if gpuCount > 4:
                    hwStatus = "Critical"
                    performanceStatus="Degraded"
                    break;
            elif("fan" in key):
                hwStatus = "Degraded"
            else:
                performanceStatus = "Degraded"
    if useJson:
        output = {"Hardware Status": hwStatus, "Performance": performanceStatus}
        output = json.dumps(output, sort_keys=True, indent=4, separators=(',', ': '), ensure_ascii=False)
    else:
        output = ("Hardware Status: " + hwStatus +
                  "\nPerformance: " +performanceStatus )
        
        
    #SW407886: Clear the duplicate entries
    #collect the dups
    d['devdebug'] = False
    sels = json.loads(selPrint(host, args, session))
    logNums2Clr = []
    oldestLogNum={"logNum": "bogus" ,"key" : ""}
    count = 0
    if sels['numAlerts'] > 0:
        for key in sels:
            if "numAlerts" in key:
                continue
            try:
                if "slave@00:00/00:00:00:06/sbefifo1-dev0/occ1-dev0" in sels[key]['Message']:
                    count += 1
                    if count > 1:
                        #preserve first occurrence
                        if sels[key]['timestamp'] < sels[oldestLogNum['key']]['timestamp']:
                            oldestLogNum['key']=key
                            oldestLogNum['logNum'] = sels[key]['logNum']
                    else:
                        oldestLogNum['key']=key
                        oldestLogNum['logNum'] = sels[key]['logNum']
                    logNums2Clr.append(sels[key]['logNum'])
            except KeyError:
                continue
        if(count >0):
            logNums2Clr.remove(oldestLogNum['logNum'])
        #delete the dups
        if count >1:
            httpHeader = {'Content-Type':'application/json'}
            data = "{\"data\": [] }"
            for logNum in logNums2Clr:
                    url = "https://"+ host+ "/xyz/openbmc_project/logging/entry/"+logNum+"/action/Delete"
                    try:
                        session.post(url, headers=httpHeader, data=data, verify=False, timeout=30)
                    except(requests.exceptions.Timeout):
                        deleteFailed = True
                    except(requests.exceptions.ConnectionError) as err:
                        deleteFailed = True
    #End of defect resolve code
    d['json'] = useJson
    return output


        
def bmc(host, args, session):
    """
         handles various bmc level commands, currently bmc rebooting
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the bmc sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    if(args.type is not None):
        return bmcReset(host, args, session)
    if(args.info):
        return "Not implemented at this time"

    

def bmcReset(host, args, session):
    """
         controls resetting the bmc. warm reset reboots the bmc, cold reset removes the configuration and reboots. 
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the bmcReset sub command
         @param session: the active session to use
         @param args.json: boolean, if this flag is set to true, the output will be provided in json format for programmatic consumption 
    """ 
    if(args.type == "warm"):
        print("\nAttempting to reboot the BMC...:")
        url="https://"+host+"/xyz/openbmc_project/state/bmc0/attr/RequestedBMCTransition"
        httpHeader = {'Content-Type':'application/json'}
        data = '{"data":"xyz.openbmc_project.State.BMC.Transition.Reboot"}'
        res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=20)
        return res.text
    elif(args.type =="cold"):
        print("\nAttempting to reboot the BMC...:")
        url="https://"+host+"/xyz/openbmc_project/state/bmc0/attr/RequestedBMCTransition"
        httpHeader = {'Content-Type':'application/json'}
        data = '{"data":"xyz.openbmc_project.State.BMC.Transition.Reboot"}'
        res = session.put(url, headers=httpHeader, data=data, verify=False, timeout=20)
        return res.text
    else:
        return "invalid command"

def gardClear(host, args, session):
    """
         clears the gard records from the bmc
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the gardClear sub command
         @param session: the active session to use
    """ 
    url="https://"+host+"/org/open_power/control/gard/action/Reset"
    httpHeader = {'Content-Type':'application/json'}
    data = '{"data":[]}'
    try:
        
        res = session.post(url, headers=httpHeader, data=data, verify=False, timeout=30)
        if res.status_code == 404:
            return "Command not supported by this firmware version"
        else:
            return res.text
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)

def activateFWImage(host, args, session):
    """
         activates a firmware image on the bmc
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fwflash sub command
         @param session: the active session to use
         @param fwID: the unique ID of the fw image to activate
    """ 
    fwID = args.imageID
    
    #determine the existing versions
    httpHeader = {'Content-Type':'application/json'}
    url="https://"+host+"/xyz/openbmc_project/software/enumerate"
    try:
        resp = session.get(url, headers=httpHeader, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)
    existingSoftware = json.loads(resp.text)['data']
    altVersionID = ''
    versionType = ''
    imageKey = '/xyz/openbmc_project/software/'+fwID
    if imageKey in existingSoftware:
        versionType = existingSoftware[imageKey]['Purpose']
    for key in existingSoftware:
        if imageKey == key:
            continue
        if 'Purpose' in existingSoftware[key]:
            if versionType == existingSoftware[key]['Purpose']:
                altVersionID = key.split('/')[-1]
    
    
    
    
    url="https://"+host+"/xyz/openbmc_project/software/"+ fwID + "/attr/Priority"
    url1="https://"+host+"/xyz/openbmc_project/software/"+ altVersionID + "/attr/Priority"
    data = "{\"data\": 0}" 
    data1 = "{\"data\": 1 }"
    try:
        resp = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
        resp1 = session.put(url1, headers=httpHeader, data=data1, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)
    if(not args.json):
        if resp.status_code == 200 and resp1.status_code == 200:
            return 'Firmware activation completed. Please reboot the BMC for the changes to take effect.'
        else:
            return "Firmware activation failed."
    else:
        return resp.text + resp1.text
    
def fwFlash(host, args, session):
    """
         updates the bmc firmware and pnor firmware
           
         @param host: string, the hostname or IP address of the bmc
         @param args: contains additional arguments used by the fwflash sub command
         @param session: the active session to use
    """ 
    
    if(args.type == 'bmc'):
        purp = 'BMC'
    else:
        purp = 'Host'
    #determine the existing versions
    httpHeader = {'Content-Type':'application/json'}
    url="https://"+host+"/xyz/openbmc_project/software/enumerate"
    try:
        resp = session.get(url, headers=httpHeader, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)
    oldsoftware = json.loads(resp.text)['data']
    
    #upload the file
    httpHeader = {'Content-Type':'application/octet-stream'}
    url="https://"+host+"/upload/image"
    data=open(args.fileloc,'rb').read()
    print("Uploading file to BMC")
    try:
        resp = session.post(url, headers=httpHeader, data=data, verify=False)
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)
    if resp.status_code != 200:
        return "Failed to upload the file to the bmc"
    else:
        print("Upload complete.")
    
    #determine the version number
    software ={}
    for i in range(0, 5):
        httpHeader = {'Content-Type':'application/json'}
        url="https://"+host+"/xyz/openbmc_project/software/enumerate"
        try:
            resp = session.get(url, headers=httpHeader, verify=False, timeout=30)
        except(requests.exceptions.Timeout):
            return connectionErrHandler(args.json, "Timeout", None)
        except(requests.exceptions.ConnectionError) as err:
            return connectionErrHandler(args.json, "ConnectionError", err)
        software = json.loads(resp.text)['data']
        #check if bmc is done processing the new image
        if (len(software.keys()) > len(oldsoftware.keys())):
            break
        else:
            time.sleep(15)
    newversionID = ''
    for key in software:
        if key not in oldsoftware:
            idPart = key.split('/')[-1]
            if idPart == 'inventory': 
                continue
            softPurpose = software['/xyz/openbmc_project/software/' +idPart]['Purpose'].split('.')[-1]
            if(purp in softPurpose):
                newversionID = idPart
                break
    if newversionID == '':
        return('Could not find the new version of the firmware on the bmc, it may already exist.' + 
               "\nRun fru print command and check for the version number. If found, use the firmware activate command to change to using that image.\n"
               "If you are reapplying the same image, reboot the bmc to complete the update. ")

    #activate the new image
    print("Activating new image")
    url="https://"+host+"/xyz/openbmc_project/software/"+ newversionID + "/attr/RequestedActivation"
    data = '{"data":"xyz.openbmc_project.Software.Activation.RequestedActivations.Active"}' 
    try:
        resp = session.put(url, headers=httpHeader, data=data, verify=False, timeout=30)
    except(requests.exceptions.Timeout):
        return connectionErrHandler(args.json, "Timeout", None)
    except(requests.exceptions.ConnectionError) as err:
        return connectionErrHandler(args.json, "ConnectionError", err)
    
    return "Firmware flash completed. Please allow a few minutes for the activation to complete. After the activation is complete you will need to reboot the bmc and the host OS for the changes to take effect. "

def createCommandParser():
    """
         creates the parser for the command line along with help for each command and subcommand
           
         @return: returns the parser for the command line
    """ 
    parser = argparse.ArgumentParser(description='Process arguments')
    parser.add_argument("-H", "--host", help='A hostname or IP for the BMC')
    parser.add_argument("-U", "--user", help='The username to login with')
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-A", "--askpw", action='store_true', help='prompt for password')
    group.add_argument("-P", "--PW", help='Provide the password in-line')
    parser.add_argument('-j', '--json', action='store_true', help='output json data only')
    parser.add_argument('-t', '--policyTableLoc', help='The location of the policy table to parse alerts')
    parser.add_argument('-c', '--CerFormat', action='store_true', help=argparse.SUPPRESS)
    parser.add_argument('-T', '--procTime', action='store_true', help= argparse.SUPPRESS)
    parser.add_argument('-V', '--version', action='store_true', help='Display the version number of the openbmctool')
    subparsers = parser.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    
    #fru command
    parser_inv = subparsers.add_parser("fru", help='Work with platform inventory')
    #fru print
    inv_subparser = parser_inv.add_subparsers(title='subcommands', description='valid inventory actions', help="valid inventory actions", dest='command')
    inv_print = inv_subparser.add_parser("print", help="prints out a list of all FRUs")
    inv_print.set_defaults(func=fruPrint)
    #fru list [0....n]
    inv_list = inv_subparser.add_parser("list", help="print out details on selected FRUs. Specifying no items will list the entire inventory")
    inv_list.add_argument('items', nargs='?', help="print out details on selected FRUs. Specifying no items will list the entire inventory")
    inv_list.set_defaults(func=fruList)
    #fru status
    inv_status = inv_subparser.add_parser("status", help="prints out the status of all FRUs")
    inv_status.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    inv_status.set_defaults(func=fruStatus)
    
    #sensors command
    parser_sens = subparsers.add_parser("sensors", help="Work with platform sensors")
    sens_subparser=parser_sens.add_subparsers(title='subcommands', description='valid sensor actions', help='valid sensor actions', dest='command')
    #sensor print
    sens_print= sens_subparser.add_parser('print', help="prints out a list of all Sensors.")
    sens_print.set_defaults(func=sensor)
    #sensor list[0...n]
    sens_list=sens_subparser.add_parser("list", help="Lists all Sensors in the platform. Specify a sensor for full details. ")
    sens_list.add_argument("sensNum", nargs='?', help="The Sensor number to get full details on" )
    sens_list.set_defaults(func=sensor)
    
    
    #sel command
    parser_sel = subparsers.add_parser("sel", help="Work with platform alerts")
    sel_subparser = parser_sel.add_subparsers(title='subcommands', description='valid SEL actions', help = 'valid SEL actions', dest='command')
    
    #sel print
    sel_print = sel_subparser.add_parser("print", help="prints out a list of all sels in a condensed list")
    sel_print.add_argument('-d', '--devdebug', action='store_true', help=argparse.SUPPRESS)
    sel_print.add_argument('-v', '--verbose', action='store_true', help="Changes the output to being very verbose")
    sel_print.add_argument('-f', '--fileloc', help='Parse a file instead of the BMC output')
    sel_print.set_defaults(func=selPrint)
    #sel list
    sel_list = sel_subparser.add_parser("list", help="Lists all SELs in the platform. Specifying a specific number will pull all the details for that individual SEL")
    sel_list.add_argument("selNum", nargs='?', type=int, help="The SEL entry to get details on")
    sel_list.set_defaults(func=selList)
    
    sel_get = sel_subparser.add_parser("get", help="Gets the verbose details of a specified SEL entry")
    sel_get.add_argument('selNum', type=int, help="the number of the SEL entry to get")
    sel_get.set_defaults(func=selList)
    
    sel_clear = sel_subparser.add_parser("clear", help="Clears all entries from the SEL")
    sel_clear.set_defaults(func=selClear)
    
    sel_setResolved = sel_subparser.add_parser("resolve", help="Sets the sel entry to resolved")
    sel_setResolved.add_argument('-n', '--selNum', type=int, help="the number of the SEL entry to resolve")
    sel_ResolveAll_sub = sel_setResolved.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    sel_ResolveAll = sel_ResolveAll_sub.add_parser('all', help='Resolve all SEL entries')
    sel_ResolveAll.set_defaults(func=selResolveAll)
    sel_setResolved.set_defaults(func=selSetResolved)
    
    parser_chassis = subparsers.add_parser("chassis", help="Work with chassis power and status")
    chas_sub = parser_chassis.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    
    parser_chassis.add_argument('status', action='store_true', help='Returns the current status of the platform')
    parser_chassis.set_defaults(func=chassis)
    
    parser_chasPower = chas_sub.add_parser("power", help="Turn the chassis on or off, check the power state")
    parser_chasPower.add_argument('powcmd',  choices=['on','softoff', 'hardoff', 'status'], help='The value for the power command. on, off, or status')
    parser_chasPower.set_defaults(func=chassisPower)
    
    #control the chassis identify led
    parser_chasIdent = chas_sub.add_parser("identify", help="Control the chassis identify led")
    parser_chasIdent.add_argument('identcmd', choices=['on', 'off', 'status'], help='The control option for the led: on, off, blink, status')
    parser_chasIdent.set_defaults(func=chassisIdent)
    
    #collect service data
    parser_servData = subparsers.add_parser("collect_service_data", help="Collect all bmc data needed for service")
    parser_servData.add_argument('-d', '--devdebug', action='store_true', help=argparse.SUPPRESS)
    parser_servData.set_defaults(func=collectServiceData)
    
    #system quick health check
    parser_healthChk = subparsers.add_parser("health_check", help="Work with platform sensors")
    parser_healthChk.set_defaults(func=healthCheck)
    
    #work with bmc dumps
    parser_bmcdump = subparsers.add_parser("dump", help="Work with bmc dump files")
    bmcDump_sub = parser_bmcdump.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    dump_Create = bmcDump_sub.add_parser('create', help="Create a bmc dump")
    dump_Create.set_defaults(func=bmcDumpCreate)
    
    dump_list = bmcDump_sub.add_parser('list', help="list all bmc dump files")
    dump_list.set_defaults(func=bmcDumpList)
    
    parserdumpdelete = bmcDump_sub.add_parser('delete', help="Delete bmc dump files")
    parserdumpdelete.add_argument("-n", "--dumpNum", nargs='*', type=int, help="The Dump entry to delete")
    parserdumpdelete.set_defaults(func=bmcDumpDelete)
    
    bmcDumpDelsub = parserdumpdelete.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    deleteAllDumps = bmcDumpDelsub.add_parser('all', help='Delete all bmc dump files')
    deleteAllDumps.set_defaults(func=bmcDumpDeleteAll)
    
    parser_dumpretrieve = bmcDump_sub.add_parser('retrieve', help='Retrieve a dump file')
    parser_dumpretrieve.add_argument("dumpNum", type=int, help="The Dump entry to delete")
    parser_dumpretrieve.add_argument("-s", "--dumpSaveLoc", help="The location to save the bmc dump file")
    parser_dumpretrieve.set_defaults(func=bmcDumpRetrieve)
    
    parser_bmc = subparsers.add_parser('bmc', help="Work with the bmc")
    bmc_sub = parser_bmc.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    parser_BMCReset = bmc_sub.add_parser('reset', help='Reset the bmc' )
    parser_BMCReset.add_argument('type', choices=['warm','cold'], help="Warm: Reboot the BMC, Cold: CLEAR config and reboot bmc")
    parser_bmc.add_argument('info', action='store_true', help="Displays information about the BMC hardware, including device revision, firmware revision, IPMI version supported, manufacturer ID, and information on additional device support.")
    parser_bmc.set_defaults(func=bmc)
    
    #add alias to the bmc command
    parser_mc = subparsers.add_parser('mc', help="Work with the management controller")
    mc_sub = parser_mc.add_subparsers(title='subcommands', description='valid subcommands',help="sub-command help", dest='command')
    parser_MCReset = mc_sub.add_parser('reset', help='Reset the bmc' )
    parser_MCReset.add_argument('type', choices=['warm','cold'], help="Reboot the BMC")
    #parser_MCReset.add_argument('cold', action='store_true', help="Reboot the BMC and CLEAR the configuration")
    parser_mc.add_argument('info', action='store_true', help="Displays information about the BMC hardware, including device revision, firmware revision, IPMI version supported, manufacturer ID, and information on additional device support.")
    parser_MCReset.set_defaults(func=bmcReset)
    parser_mc.set_defaults(func=bmc)
    
    #gard clear
    parser_gc = subparsers.add_parser("gardclear", help="Used to clear gard records")
    parser_gc.set_defaults(func=gardClear)
    
    #firmware_flash
    parser_fw = subparsers.add_parser("firmware", help="Work with the system firmware")
    fwflash_subproc = parser_fw.add_subparsers(title='subcommands', description='valid firmware commands', help='sub-command help', dest='command')
    fwflash = fwflash_subproc.add_parser('flash', help="Flash the system firmware")
    fwflash.add_argument('type', choices=['bmc', 'pnor'], help="image type to flash")
    fwflash.add_argument('-f', '--fileloc', required=True, help="The absolute path to the firmware image")
    fwflash.set_defaults(func=fwFlash)
    
    fwActivate = fwflash_subproc.add_parser('activate', help="Active existing image on the bmc")
    fwActivate.add_argument('imageID', help="The image ID to activate from the firmware list. Ex: 63c95399")
    fwActivate.set_defaults(func=activateFWImage)
    
    return parser

def main(argv=None):
    """
         main function for running the command line utility as a sub application  
    """ 
    parser = createCommandParser()
    args = parser.parse_args(argv)
        
    totTimeStart = int(round(time.time()*1000))

    if(sys.version_info < (3,0)):
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    if sys.version_info >= (3,0):
        requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)
    if (args.version):
        print("Version: 1.0")
        sys.exit(0)
    if (hasattr(args, 'fileloc') and args.fileloc is not None and 'print' in args.command):
        mysess = None
        print(selPrint('N/A', args, mysess))
    else: 
        if(hasattr(args, 'host') and hasattr(args,'user')):
            if (args.askpw):
                pw = getpass.getpass()
            elif(args.PW is not None):
                pw = args.PW
            else:
                print("You must specify a password")
                sys.exit()
            logintimeStart = int(round(time.time()*1000))
            mysess = login(args.host, args.user, pw, args.json)
            logintimeStop = int(round(time.time()*1000))
            
            commandTimeStart = int(round(time.time()*1000))  
            output = args.func(args.host, args, mysess)
            commandTimeStop = int(round(time.time()*1000))
            print(output)
            if (mysess is not None):
                logout(args.host, args.user, pw, mysess, args.json)  
            if(args.procTime):     
                print("Total time: " + str(int(round(time.time()*1000))- totTimeStart))
                print("loginTime: " + str(logintimeStop - logintimeStart))
                print("command Time: " + str(commandTimeStop - commandTimeStart))
        else:
            print("usage: openbmctool.py [-h] -H HOST -U USER [-A | -P PW] [-j]\n" +
                      "\t[-t POLICYTABLELOC] [-V]\n" +
                      "\t{fru,sensors,sel,chassis,collect_service_data,health_check,dump,bmc,mc,gardclear,firmware}\n" +
                      "\t...\n" +
                      "openbmctool.py: error: the following arguments are required: -H/--host, -U/--user")
            sys.exit()  

if __name__ == '__main__':
    """
         main function when called from the command line
            
    """ 
    import sys
    
    isTTY = sys.stdout.isatty()
    assert sys.version_info >= (2,7)
    main()
