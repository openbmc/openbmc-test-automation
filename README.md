#openbmc-automation

Quickstart
----------

To run openbmc-automation first you need to install the prerequisite python
packages which will help to invoke tests through tox.  Note that tox
version 2.3.1 or greater is required.

Install the python dependencies for tox
```shell
    $ easy_install tox
    $ easy_install pip
```

Initilize the following environment variable which will used while testing
```shell
    $ export OPENBMC_HOST=<openbmc machine ip address>
    $ export OPENBMC_PASSWORD=<openbmc username>
    $ export OPENBMC_USERNAME=<openbmc password>
    $ export OPENBMC_MODEL=[./data/Barreleye.py, ./data/Palmetto.py, etc]

There are two different set of test suite existing based on the usage.
The test suites are distinctly separated by directory as under
    test/
    extended/

tests/ directory contain the general test cases
extended/ directory contains the use cases for new IP network testin, PDU, BIOS
and BMC code update

Use Following Variables for networking test cases
===========================================================
    $export NEW_BMC_IP=<openbmc machine ip address>
    $export NEW_SUBNET_MASK=<openbmc new subnet mask>
    $export NEW_GATEWAY=<openbmc new gateway>
==========================================================

    Use following parameters for PDU:
    $ export PDU_IP=<PDU IP address>
    $ export PDU_USERNAME=<PDU username>
    $ export PDU_PASSWORD=<PDU password>
    $ export PDU_TYPE=<PDU type>
    $ export PDU_SLOT_NO=<SLOT number>

    for PDU_TYPE we support only synaccess at the moment

Use following variables for syslog test cases
==========================================================
    $ export SYSLOG_IP_ADDRESS=<remote syslog system ip>
    $ export SYSLOG_PORT=<remote syslog system port>

Use the following variables for Qemu test run
==========================================================
    $ export SSH_PORT=<ssh port number>
    $ export HTTPS_PORT=<https port number>

Use the following variables for BIOS update testing
==========================================================
    $ export PNOR_IMAGE_PATH=<path to>/<machine>.pnor

```

Run tests
```shell
    $ tox -e tests
```

How to test individual test
```shell
    One specific test
    $ tox -e custom -- -t '"DIMM0 no fault"' tests/test_sensors.robot

    No preset environment variables, one test case from one test suite
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- -t '"DIMM0 no fault"' tests/test_sensors.robot

    No preset environment variables, one test suite  for a palmetto system
    $ OPENBMC_HOST=x.x.x.x tox -e palmetto -- tests/test_sensors.robot

    No preset environment variables, the entire test suite for a barreleye system
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- tests
```

It can also be run by pasing variables from the cli...
```shell
    $  pybot -v OPENBMC_HOST:<ip> -v OPENBMC_USERNAME:root -v OPENBMC_PASSWORD:0penBmc -v OPENBMC_MODEL:<model path>
```

```
Run extended tests
```shell
    Set the preset environment variables, run test suite for a barreleye system
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- extended/test_power_restore.robot

    Similarly for Network, PDU and update BIOS

    For BMC code update, download the system type *.all.tar image from https://openpower.xyz
    and run as follows:

    For Barreleye system
    python -m robot -v OPENBMC_HOST:x.x.x.x -v FILE_PATH:downloaded_path/barreleye-xxxx.all.tar  extended/code_update/update_bmc.robot
```
