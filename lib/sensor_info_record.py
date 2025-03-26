"""
sensor_info_record.py

This module provides functions for retrieving and validating sensor information
from D-Bus and Redfish endpoints. It includes functionalities for:
- Validating sensor threshold values according to IPMI specifications.
- Checking sensor reading value lengths.
- Converting sensor names to a 16-byte format as required by IPMI.
- Creating a list of sensors that do not have a single threshold value.
These functions support automated sensor validations as part of the Robot
Framework tests in an OpenBMC environment.
"""


import gen_print as gp
from robot.libraries.BuiltIn import BuiltIn


def validate_threshold_values(sensor_threshold_values, sensor_id):
    r"""
    Validate sensor thresholds per IPMI spec:
      Lower thresholds: lnr < lcr < lnc
      Upper thresholds: unc > ucr > unr

    Description of arguments:
    sensor_threshold_values: Dictionary of threshold values.
    sensor_id: Sensor identifier (e.g. "fan_1").
    """
    # Validate lower thresholds
    if not (
        float(sensor_threshold_values["lnr"])
        < float(sensor_threshold_values["lcr"])
        < float(sensor_threshold_values["lnc"])
    ):
        error_msg = (
            f"{sensor_id}: Lower thresholds violate IPMI spec\n"
            f"lnr={sensor_threshold_values['lnr']} "
            f"lcr={sensor_threshold_values['lcr']} "
            f"lnc={sensor_threshold_values['lnc']}"
        )
        BuiltIn().fail(error_msg)

    # Validate upper thresholds
    if not (
        float(sensor_threshold_values["unc"])
        > float(sensor_threshold_values["ucr"])
        > float(sensor_threshold_values["unr"])
    ):
        error_msg = (
            f"{sensor_id}: Upper thresholds violate IPMI spec\n"
            f"unc={sensor_threshold_values['unc']} "
            f"ucr={sensor_threshold_values['ucr']} "
            f"unr={sensor_threshold_values['unr']}"
        )
        BuiltIn().fail(error_msg)


def check_reading_value_length(sensor_reading, sensor_id, sensor_unit):
    r"""
    Validate sensor reading length per IPMI spec.

    Description of arguments:
    sensor_reading: Reading value (e.g. "1234.567").
    sensor_id: Sensor identifier (e.g. "temp_ambient").
    sensor_unit: Sensor unit (e.g. "RPM").
    """
    max_int_len = 6 if sensor_unit == "RPM" else 4
    max_frac_len = 3 if sensor_unit == "RPM" else 4

    if "." in sensor_reading:
        integer_part, fractional_part = sensor_reading.split(".", 1)
    else:
        integer_part = sensor_reading
        fractional_part = ""

    if len(integer_part) > max_int_len:
        BuiltIn().fail( 
            f"{sensor_id}: Integer part exceeds {max_int_len} digits "
            f"({integer_part})"
        )

    if len(fractional_part) > max_frac_len:
        BuiltIn().fail(  
            f"{sensor_id}: Fractional part exceeds {max_frac_len} digits "
            f"({fractional_part})"
        )


def convert_sensor_name_as_per_ipmi_spec(sensor_name):
    r"""
    Convert sensor name to 16-byte IPMI-compliant format.

    Description of arguments:
    sensor_name: Original sensor name.

    Example:
    Input: "very_long_sensor_name_12345"
    Output: "very_long_sensor" (16-byte truncated UTF-8)
    """
    READING_VALUE_BYTE_LIMIT = 16
    encoded = sensor_name.encode("utf-8")
    truncated = encoded[:READING_VALUE_BYTE_LIMIT]
    padded = truncated.ljust(READING_VALUE_BYTE_LIMIT, b"\x00")
    return padded.decode("utf-8", errors="ignore")


def create_sensor_list_not_having_single_threshold(
    ipmi_sensor_response, threshold_sensor_list
):
    r"""
    Identify sensors with no valid thresholds.

    Description of arguments:
    ipmi_sensor_response: Raw IPMI sensor output.
    threshold_sensor_list: List of expected threshold sensors.

    Example IPMI response line:
    "fan_1 | 1000 RPM | ok | 200.000 | 500.000 | 600.000 | 700.000 | "
    "800.000 | 900.000 | na |"
    - Splitting by "|" gives parts where `parts[4:10]` are thresholds:
      [500.000, 600.000, 700.000, 800.000, 900.000, na]
    - If any threshold is not "na", thresholds exist for that sensor.
    """
    sensor_ids_missing_threshold = []

    for sensor_id in threshold_sensor_list:
        thresholds_exist = False
        for line in ipmi_sensor_response.splitlines():
            if sensor_id in line:
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 10:
                    thresholds = parts[4:10]
                    if any(t != "na" for t in thresholds):
                        thresholds_exist = True
                        break
        if not thresholds_exist:
            sensor_ids_missing_threshold.append(sensor_id)

    return sensor_ids_missing_threshold
