#!/bin/sh
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Script to generate valid Sensors dbus path list.          #
# To run this script, copy to BMC home or tmp directory     #
# Power on the system to Runtime and then execute:          #
# sh sensor.sh                                              #
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

dbus_obj="xyz.openbmc_project.HwmonTempSensor xyz.openbmc_project.ADCSensor xyz.openbmc_project.VirtualSensor"

for dobj in $dbus_obj
do
    echo DBUS object:$dobj
    dbus_cmd_out=`busctl tree $dobj --list | grep /sensors/`

    for i in $dbus_cmd_out
    do
        exist=`busctl introspect $dobj $i | grep yz.openbmc_project.Sensor.Value`
        if [ ! -z "$exist" ]; then
            cmd_value=` busctl get-property $dobj $i xyz.openbmc_project.Sensor.Value Value`
            echo $i Value=${cmd_value##*d}
        fi
    done
done
