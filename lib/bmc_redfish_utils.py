#!/usr/bin/env python3

r"""
BMC redfish utility functions.
"""

import json
import re
from robot.libraries.BuiltIn import BuiltIn
import gen_print as gp
from redfish.rest.v1 import RetriesExhaustedError

MTLS_ENABLED = BuiltIn().get_variable_value("${MTLS_ENABLED}")
pending_enumeration = set()
enumerated_resources = set()
result = {}

class bmc_redfish_utils(object):

    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'
    

    def __init__(self):
        r"""
        Initialize the bmc_redfish_utils object.
        """
        # Obtain a reference to the global redfish object.
        self.__inited__ = False
        self._redfish_ = BuiltIn().get_library_instance('redfish')

        if MTLS_ENABLED == 'True':
            self.__inited__ = True
        else:
            # There is a possibility that a given driver support both redfish and
            # legacy REST.
            self._redfish_.login()
            self._rest_response_ = \
                self._redfish_.get("/xyz/openbmc_project/", valid_status_codes=[200, 404])

            # If REST URL /xyz/openbmc_project/ is supported.
            if self._rest_response_.status == 200:
                self.__inited__ = True

        BuiltIn().set_global_variable("${REDFISH_REST_SUPPORTED}", self.__inited__)
        self._pending_enum = set()

    @classmethod    
    def get_request(cls, resource, retry_exhaust):
        
        p = cls()
        try:
            _rest_response_ = \
                      p._redfish_.get(resource, valid_status_codes=[200, 404, 405, 500])
        except RetriesExhaustedError as e:
            BuiltIn().log_to_console("Retry exception")
            BuiltIn().log_to_console(resource)  
            retry_exhaust.append(resource)
            return {}          
            
        # Enumeration is done for available resources ignoring the
        # ones for which response is not obtained.
        if _rest_response_.status != 200:
            return {}
        else:
            return _rest_response_.dict
    @classmethod      
    def walk_nested_dict(cls, data, url_collection=''):
        #url = url.rstrip('/')
        if not(url_collection):
            url_collection = set()
            BuiltIn().log_to_console("Initialize set")
        
        
        
        for key, value in data.items():
            # Recursion if nested dictionary found.
            if isinstance(value, dict):
                cls.walk_nested_dict(value,url_collection)
                BuiltIn().log_to_console("Calling myself")
            else:
                # Value contains a list of dictionaries having member data.
                if 'Members' == key:
                    if isinstance(value, list):
                        for memberDict in value:
                            if isinstance(memberDict, str):
                                url_collection.add(memberDict)
                                BuiltIn().log_to_console(memberDict)
                                BuiltIn().log_to_console("Mem added")
                                                      
                            else:
                                url_collection.add(memberDict['@odata.id'])
                                BuiltIn().log_to_console(memberDict['@odata.id'])
                                BuiltIn().log_to_console("data id added")
     
                elif '@odata.id' == key:
                    value = value.rstrip('/')
                    url_collection.add(value)
                    BuiltIn().log_to_console("url collection")
            BuiltIn().log_to_console("Next key " + str(key))
        BuiltIn().log_to_console("Returning:" + str(url_collection))   
        return url_collection
               
    @classmethod
    def get_request_and_walk(cls, uri, final_output,returning_output, retry_exhaust):
        BuiltIn().log_to_console("In method")
        BuiltIn().log_to_console(uri)
        response = cls.get_request(uri, retry_exhaust)
        BuiltIn().log_to_console(response)
        BuiltIn().log_to_console("Step2")
        
        final_output[uri] = response    
        if not(response):
            return ("","")
        BuiltIn().log_to_console("Step3")
        returning_output.extend(list(cls.walk_nested_dict(response)))
    
    @classmethod  
    def enumerate_multi_proc_request(cls, uri): 
        try:
            from multiprocessing import Pool, Queue, Manager
            from itertools import repeat
            from datetime import datetime 
            start_time = datetime.now() 
            #
            m = Manager()
            q = m.Queue()
            #final_output = m.Queue()
            
            final_output = m.dict()
            to_be_enumerated = m.list()
            retry_exhaust = m.list()
            to_be_enumerated.append(uri)
            returning_urls = m.list()
            BuiltIn().log_to_console("Step1")
            exclusion_uri = {'JsonSchemas', 'SessionService',              
                             'PostCodes', 'Registries',
                             'Journal', '#', 'MetricDefinitions'}
            while to_be_enumerated:
                to_be_enumerated = [uri for uri in to_be_enumerated 
                                    if not(set(uri.split('/'))).intersection(exclusion_uri)]
                BuiltIn().log_to_console(to_be_enumerated)
                BuiltIn().log_to_console("Entering pool")
                if not(to_be_enumerated):
                    BuiltIn().log_to_console("Breaking out")
                    break
                val = len(to_be_enumerated)
                with Pool() as pool:
                    try:
                        pool.starmap(cls.get_request_and_walk, 
                                                zip(to_be_enumerated, 
                                                repeat(final_output, val),
                                                repeat(returning_urls, val),
                                                repeat(retry_exhaust, val)))
                        BuiltIn().log_to_console(returning_urls)
                        BuiltIn().log_to_console("Caught above")                        
                    except (ValueError, IndexError) as e:
                        BuiltIn().log_to_console(pool.starmap(cls.get_request_and_walk, 
                                                zip(to_be_enumerated, 
                                                repeat(final_output, val),
                                                repeat(returning_urls, val),
                                                repeat(retry_exhaust, val))))
                        BuiltIn().log_to_console("JUST PRINTING")
                            
                    BuiltIn().log_to_console("out pool")                  
                BuiltIn().log_to_console("Looping next ")              
                BuiltIn().log_to_console(type(result))              
                to_be_enumerated = list(returning_urls[:])
                to_be_enumerated = [uri for uri in to_be_enumerated 
                                    if uri not in final_output.keys()]
                to_be_enumerated = [uri for uri in to_be_enumerated if uri not in 
                                    retry_exhaust]
                BuiltIn().log_to_console("To be enumerated:" + str(to_be_enumerated))                     
            data = json.dumps(final_output.copy(), sort_keys=True,
                                  indent=4, separators=(',', ': ')) 
            time_elapsed = datetime.now() - start_time                                  
            BuiltIn().log_to_console('Time elapsed (hh:mm:ss.ms) ' + str(time_elapsed))  
                                               
            BuiltIn().log_to_console("Final output:") 
            BuiltIn().log_to_console(data)  
            BuiltIn().log_to_console("Retry exhaust")             
            BuiltIn().log_to_console(retry_exhaust)              
            return data                         
        except (ValueError, IndexError, TypeError) as e:
            import sys, os
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            BuiltIn().log_to_console(exc_type, fname, exc_tb.tb_lineno)
            BuiltIn().log_to_console(exc_tb.tb_lineno)
            BuiltIn().log_to_console(str(e))            
            BuiltIn().log_to_console("ABOVE")            
        