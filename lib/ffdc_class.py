#!/usr/bin/env python3

r"""
FFDC Class implements following using multiprocessing module.
# Enumeration of Redfish URIs
"""

import json
import sys
import os
from robot.libraries.BuiltIn import BuiltIn
from redfish.rest.v1 import RetriesExhaustedError
from multiprocessing import Pool, Queue, Manager
from itertools import repeat


class ffdc_class(object):
    BuiltIn().set_log_level("WARN")
    _redfish_ = BuiltIn().get_library_instance('redfish')

    @classmethod
    def get_request(cls, resource_path, include_dead_resources):
        r"""
        Perform a GET request and return available resource paths.

        Description of argument(s):
        resource_path               URI resource absolute path (e.g.
                                    "/redfish/v1/SessionService/Sessions").
        include_dead_resources      Check and return a list of dead/broken/non
                                    responsive URI resources.
        """
        dead_resources = {}
        class_ref = cls()
        try:
            response = class_ref._redfish_.get(resource_path,
                                               valid_status_codes=[200, 404,
                                                                   405, 500])

        except RetriesExhaustedError as e:
            if include_dead_resources:
                dead_resources[resource] = "Hit retries exhausted error"
            return "", dead_resources

        # Enumeration is done for available resources ignoring the
        # ones for which response is not obtained.
        if response.status != 200:
            if include_dead_resources:
                dead_resources[resource] = response.status
            return "", dead_resources
        else:
            return response.dict, dead_resources

    @classmethod
    def walk_nested_dict(cls, data, uri_collection=''):
        r"""
        Parse through data and return all Redfish URIs.

        Description of argument(s):
        data              Redfish URI response in dictionary format.
        uri_collection    Set type Variable to save Redfish URIs found in input
                          data. Not expected to be passed in by the calling
                          method.
        """

        if not(uri_collection):
            uri_collection = set()

        for key, value in data.items():
            # Recursion if nested dictionary found.
            if isinstance(value, dict):
                cls.walk_nested_dict(value, uri_collection)
            else:
                # Value contains a list of dictionaries having member data.
                if 'Members' == key:
                    if isinstance(value, list):
                        for memberDict in value:
                            if isinstance(memberDict, str):
                                uri_collection.add(memberDict)
                            else:
                                uri_collection.add(memberDict['@odata.id'])
                elif '@odata.id' == key:
                    uri_collection.add(value.rstrip('/'))

        return uri_collection

    @classmethod
    def get_response_and_walk(cls, resource, enumerated,
                              to_be_enumerated,
                              dead_resources, include_dead_resources):
        r"""
        Get response for resource and all its children.

        Description of argument(s):
        resource                URI resource absolute path (e.g.
                                "/redfish/v1/SessionService/Sessions").
        enumerated              Variable to store enumerated resources
                                Datatype: multiprocessing manager Dict.
        to_be_enumerated        Variable to store pending enumerating resources
                                Datatype: multiprocessing manager
                                List.
        dead_resources          Variable to store Dead resources
                                Datatype: multiprocessing manager Dict.
        include_dead_resources  Check and return a list of dead/broken/non
                                responsive URI resources.
        """

        response, dead = cls.get_request(resource, include_dead_resources)

        if not(response):
            if include_dead_resources:
                dead_resources.update(dead)
            return
        enumerated[resource] = response
        to_be_enumerated.extend(list(cls.walk_nested_dict(response)))

    @classmethod
    def enumerate_multi_proc_request(cls, resource_path, return_json=1,
                                     include_dead_resources=False):
        r"""
        Perform a GET enumerate request and return available resource paths.

        Description of argument(s):
        resource_path               URI resource absolute path (e.g.
                                    "/redfish/v1/SessionService/Sessions").
        return_json                 Indicates whether the result should be
                                    returned as a json string or as a
                                    dictionary.
        include_dead_resources      Check and return a list of dead/broken/non
                                    responsive URI resources.
        """
        try:
            data_manager = Manager()

            enumerated = data_manager.dict()
            dead_resources = data_manager.dict()

            to_be_enumerated = data_manager.list()
            to_be_enumerated.append(resource_path)

            uri_children = data_manager.list()

            exclusion_uri = {'JsonSchemas', 'SessionService',
                             'PostCodes', 'Registries',
                             'Journal', '#', 'MetricDefinitions'}
            while to_be_enumerated:
                to_be_enumerated = [uri for uri in to_be_enumerated
                                    if not(set(uri.split('/')
                                               )).intersection(exclusion_uri)]

                # Check Whether URIs exist for processing after clean up.
                if not(to_be_enumerated):
                    break

                num = len(to_be_enumerated)

                with Pool(processes=10) as pool:
                    try:
                        pool.starmap(cls.get_response_and_walk,
                                     zip(to_be_enumerated,
                                         repeat(enumerated, num),
                                         repeat(uri_children, num),
                                         repeat(dead_resources, num),
                                         repeat(include_dead_resources)))
                    except (ValueError, IndexError) as e:
                        BuiltIn().log(str(e))
                        raise

                to_be_enumerated = list(uri_children[:])
                to_be_enumerated = [uri for uri in to_be_enumerated
                                    if uri not in enumerated.keys()]
                to_be_enumerated = [uri for uri in to_be_enumerated if uri not
                                    in dead_resources.keys()]

            if return_json:
                enumerated = json.dumps(enumerated.copy(), sort_keys=True,
                                        indent=4, separators=(',', ': '))
            return enumerated

        except (ValueError, IndexError, TypeError) as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            BuiltIn().log(exc_type, fname, exc_tb.tb_lineno)
            BuiltIn().log(exc_tb.tb_lineno)
            BuiltIn().log(str(e))
            raise
