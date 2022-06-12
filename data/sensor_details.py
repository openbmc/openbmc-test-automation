#!/usr/bin/env python3 -u

r"""

${OPENBMC_MODEL}  - Server Model which going to be declared on resource.robot that needs to be given.

For example,
Take server model as romulus.


create dictionary like below:
sensor_info_map = {
    "romulus":{
        "HOST_BMC_SENSORS":[
            "sensor_id_0",
            ...
            ]
        }
    }
"""