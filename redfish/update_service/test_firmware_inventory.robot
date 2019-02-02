*** Settings ***
Resource         ../../lib/resource.txt
Resource         ../../lib/bmc_redfish_resource.robot

*** Test Cases ***

Verify Update Service Enabled
    [Documentation]  Verify "ServiceEnabled" is enabled.
    [Tags]  Verify_Update_Service_Enabled

    # Example:
    # "HttpPushUri": "/redfish/v1/UpdateService",
    # "Id": "UpdateService",
    # "Name": "Update Service",
    # "ServiceEnabled": true

    redfish.Login
    ${resp}=  redfish.Get  /redfish/v1/UpdateService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    Should Be Equal As Strings  ${resp.dict["ServiceEnabled"]}  ${True}
    redfish.Logout


Verify Software Inventory Collection
    [Documentation]  Verify software inventory collection member and object entries.
    [Tags]  Verify_Software_Inventory_Collection

    # Example:
    # {
    #    "@odata.type": "#SoftwareInventoryCollection.SoftwareInventoryCollection",
    #    "Members": [
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/a3522998"
    #      },
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/a7c79f71"
    #      },
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/ace821ef"
    #      }
    #   ],
    #   "Members@odata.count": 3,
    #   "Name": "Software Inventory Collection"
    # }

    redfish.Login
    ${resp}=  redfish.Get  /redfish/v1/UpdateService/FirmwareInventory
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    Should Be True  ${resp.dict["Members@odata.count"]} >= ${1}
    Length Should Be  ${resp.dict["Members"]}  ${resp.dict["Members@odata.count"]}
    redfish.Logout


Software Inventory Status Check
    [Documentation]  Get firmware inventory entries and do health check status.
    [Tags]  Software_Inventory-Status_Check

    redfish.Login
    ${resp}=  redfish.Get  /redfish/v1/UpdateService/FirmwareInventory
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    # Entries "Members@odata.count": 3,
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a3522998'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a7c79f71'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/ace821ef'}

    :FOR  ${entry}  IN RANGE  0  ${resp.dict["Members@odata.count"]}
    \  ${resp_resource}=  redfish.Get  ${resp.dict["Members"][${entry}]["@odata.id"]}
    \  Should Be Equal As Strings  ${resp_resource.status}  ${HTTP_OK}
    # Example:
    # "Status": {
    #     "Health": "OK",
    #     "HealthRollup": "OK",
    #     "State": "Enabled"
    # },
    \  Should Be Equal As Strings  ${resp_resource.dict["Status"]["Health"]}  OK
    \  Should Be Equal As Strings  ${resp_resource.dict["Status"]["HealthRollup"]}  OK
    \  Should Be Equal As Strings  ${resp_resource.dict["Status"]["State"]}  Enabled
