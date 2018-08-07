#!/usr/bin/env python

r"""
Redfish function for traversing the resource model.
"""

def get_url_list(json_data, base_uri="/redfish/v1/"):
    r"""
    Returns fully qualified URI path.

    Description of argument(s):
    json_data        Dictionary data from "GET" request.
    base_uri         Base path from which the resource needed to identify.

    Example: JSON response data input
    {
        "@odata.context": "/redfish/v1/$metadata#ServiceRoot.ServiceRoot",
        "@odata.id": "/redfish/v1/",
        "@odata.type": "#ServiceRoot.v1_1_1.ServiceRoot",
        "AccountService": {
            "@odata.id": "/redfish/v1/AccountService"
        },
        "Chassis": {
            "@odata.id": "/redfish/v1/Chassis"
        },
        "Id": "RootService",
        "Links": {
            "Sessions": {
                "@odata.id": "/redfish/v1/SessionService/Sessions"
            }
        },
        "Managers": {
            "@odata.id": "/redfish/v1/Managers"
        },
        "Name": "Root Service",
        "RedfishVersion": "1.1.0",
        "SessionService": {
            "@odata.id": "/redfish/v1/SessionService/"
        },
        "Systems": {
            "@odata.id": "/redfish/v1/Systems"
        },
        "UUID": "00000000-0000-0000-0000-000000000000",
        "UpdateService": {
            "@odata.id": "/redfish/v1/UpdateService"
        }
    }

    Returns list of URI's ['/redfish/v1/Managers',
                           '/redfish/v1/Links',
                           '/redfish/v1/AccountService',
                           '/redfish/v1/UpdateService',
                           '/redfish/v1/Chassis',
                           '/redfish/v1/Systems',
                           '/redfish/v1/SessionService']
    """

    qualified_uri_list = []
    # Example of non root child resource object schema.
    # {
    #    "@odata.context": "/redfish/v1/$metadata#ChassisCollection.ChassisCollection",
    #    "@odata.id": "/redfish/v1/Chassis",
    #    "@odata.type": "#ChassisCollection.ChassisCollection",
    #    "Members": [
    #     {
    #        "@odata.id": "/redfish/v1/Chassis/motherboard"
    #     },
    #     {
    #        "@odata.id": "/redfish/v1/Chassis/system"
    #     }
    #     ],
    #     "Members@odata.count": 2,
    #     "Name": "Chassis Collection"
    # }

    # If non root resource schema.
    if "Members" in json_data:
        for members in range(json_data["Members@odata.count"]):
            for k,v in json_data["Members"][members].items():
                qualified_uri = base_uri + str(v)
                qualified_uri_list.append(qualified_uri)
        return qualified_uri_list

    # Example of non root and end resource schema.
    # {
    #     "@odata.context": "/redfish/v1/$metadata#Chassis.Chassis",
    #     "@odata.id": "/redfish/v1/Chassis",
    #     "@odata.type": "#Chassis.v1_4_0.Chassis",
    #     "BuildDate": "1996-01-01 - 00:00:00",
    #     "ChassisType": "RackMount",
    #     "Id": "motherboard",
    #     "Manufacturer": "0000000000000000",
    #     "Model": "",
    #     "Name": "motherboard",
    #     "PartNumber": "00VK525         ",
    #     "SerialNumber": "Y130UF72700J    ",
    #     "Thermal": {
    #         "@odata.id": "/redfish/v1/Chassis/motherboard/Thermal"
    #     }
    # }

    # If non root but the end resource schema.
    if base_uri != "/redfish/v1/":
        return qualified_uri_list

    # If rooti "/redfish/v1/" resource schema.
    for k, v in json_data.items():
        # Find if the dictionary contains nested dict.
        # The instance existence indicates a sub-uri hold by that dictionary
        # value is a resource object for sub tree elements.
        if isinstance(v,dict):
            # Example : 'Managers', 'Links', 'AccountService' etc.
            # into qualified URI '/redfish/v1/Managers'
            qualified_uri = base_uri + str(k)
            qualified_uri_list.append(qualified_uri)

    return qualified_uri_list
