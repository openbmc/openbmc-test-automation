#!/usr/bin/env python3 -u

r"""

${OPENBMC_MODEL}  - Open BMC server model should be declared in resource.robot

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
