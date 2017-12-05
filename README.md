#openbmc-automation

## Features of OpenBMC Test Automation ##

**Interface Feature List**
* REST
* Out-of-band IPMI
* SSH to BMC and Host OS

**Key Feature List**
* Power on/off
* Reboot Host
* Reset BMC
* Code update BMC and host
* Power management
* HTX bootme
* XCAT execution
* Network

**Debugging Supported List**
* SOL collection
* FFDC collection
* Error injection from host

## Quickstart ##

To run openbmc-automation first you need to install the prerequisite python
packages which will help to invoke tests through tox.  Note that tox
version 2.3.1 or greater is required.

Install the python dependencies for tox
```shell
    $ easy_install tox
    $ easy_install pip
```

Initialize the following environment variable which will be used during testing
```shell
    $ export OPENBMC_HOST=<openbmc machine ip address>
    $ export OPENBMC_PASSWORD=<openbmc password>
    $ export OPENBMC_USERNAME=<openbmc username>
    $ export OPENBMC_MODEL=[./data/Barreleye.py, ./data/Palmetto.py, etc]
    $ export IPMI_COMMAND=<Dbus/External>
    $ export IPMI_PASSWORD=<External IPMI password>
```

There are two different set of test suite existing based on the usage.
The test suites are distinctly separated by directory as under
    tests/
    extended/

`tests`: directory contains the general test cases

`extended`: directory contains the use cases for new IP network testing, PDU,
BIOS and BMC code update.

```shell
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
    $ tox -e default -- -t '"DIMM0 no fault"' tests/test_sensors.robot

    No preset environment variables, default configuration for all supported systems.
    $ OPENBMC_HOST=x.x.x.x tox -e default -- tests

    No preset environment variables, one test case from one test suite
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- -t '"DIMM0 no fault"' tests/test_sensors.robot

    No preset environment variables, one test suite  for a palmetto system
    $ OPENBMC_HOST=x.x.x.x tox -e palmetto -- tests/test_sensors.robot

    No preset environment variables, the entire test suite for a barreleye system
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- tests

    Default CI test bucket list:
    No preset environment variables, the entire test suite excluding test
    cases using argument file.
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- --argumentfile test_lists/skip_test tests

    Exclude test list for supported systems:
    Barrleye:  test_lists/skip_test_barreleye
    Palmetto:  test_lists/skip_test_palmetto
    Witherspoon:  test_lists/skip_test_witherspoon
```

It can also be run by passing variables from the cli...
```shell
    Run one test suite using using pybot
    $  pybot -v OPENBMC_HOST:<ip> -v OPENBMC_USERNAME:root -v OPENBMC_PASSWORD:0penBmc -v OPENBMC_MODEL:<model path> tests/test_time.robot

    Run entire test suite using using pybot
    $  pybot -v OPENBMC_HOST:<ip> -v OPENBMC_USERNAME:root -v OPENBMC_PASSWORD:0penBmc -v OPENBMC_MODEL:<model path> tests

    Run entire test suite using external ipmitool
    $  pybot -v OPENBMC_HOST:<ip> -v OPENBMC_USERNAME:root -v OPENBMC_PASSWORD:0penBmc -v IPMI_COMMAND:External -v IPMI_PASSWORD:PASSW0RD -v OPENBMC_MODEL:<model path> tests
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

    For loop test (Default iteration is 10)
    python -m robot -v OPENBMC_HOST:x.x.x.x -v OPENBMC_SYSTEMMODEL:xxxxxx -v ITERATION:n -v LOOP_TEST_COMMAND:xxxxxx extended/full_suite_regression.robot
    Below is sample command using tox to test only fw version using Barreleye system for 5 times
    OPENBMC_HOST=x.x.x.x  LOOP_TEST_COMMAND="--argumentfile test_lists/skip_test tests/test_fw_version.robot" ITERATION=5  OPENBMC_SYSTEMMODEL=barreleye tox -e barreleye -- ./extended/full_suite_regression.robot
```

Jenkins jobs tox commands
```shell
    HW CI tox command
    Set the preset environment variables, run HW CI test for a barreleye system
    $ OPENBMC_HOST=x.x.x.x tox -e barreleye -- --argumentfile test_lists/HW_CI tests

```

Template to be used to create new stand-alone python programs.
```shell

If you wish to create a new python stand-alone program, please copy bin/python_pgm_template to your new name and then begin your work.  Example:

cd bin
cp python_pgm_template my_new_program

This template has much of your preliminary work done for you and it will help us all follow a similar structure.

Features:
- Help text and argparsing started for you.
- Support for "stock" parameters like quiet, debug, test_mode.
- exit_function and signal_handler defined.
- validate_parms function pre-created.
- main function follows conventional startup:

    if not gen_get_options(parser, stock_list):
        return False

    if not validate_parms():
        return False

    qprint_pgm_header()

    # Your code here.

```

Command to get GitHub issues (any GitHub repository) report in CSV format
Note: On Prompt "Enter your GitHub Password:" enter your GitHub password.
```shell
python ./tools/github_issues_to_csv <github user> <github repo>

Example for getting openbmc issues
python ./tools/github_issues_to_csv <github user>  openbmc/openbmc

Example for getting openbmc-test-automation issues
python ./tools/github_issues_to_csv <github user>  openbmc/openbmc-test-automation
```


Command to generate Robot test cases test documentations

```shell
./tools/generate_test_document <Robot test cases directory path> <test case document file path>

Example for generating tests cases documentation for tests directory
./tools/generate_test_document tests testsdirectoryTCdocs.html

Example for generating tests cases documentation (tests,gui,extended TCs)
# Note: Invoke the tool with out argument
./tools/generate_test_document
```
