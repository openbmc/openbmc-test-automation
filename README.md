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
* IPMI support
* Factory reset
* RAS (Reliability, availability and serviceability)
* Web UI testing

**Debugging Supported List**
* SOL collection
* FFDC collection
* Error injection from host

## Installation Setup Guide ##
* [Robot Framework Install Instruction](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)

* Miscelleneous
Packages required to be installed for OpenBmc Automation.
Install the packages and it's dependencies via `pip`

    REST base packages:
    ```
    $ pip install -U requests
    $ pip install -U robotframework-requests
    ```
    SSH and SCP base packages:
    For more detailed installation instructions see [robotframework-sshlibrary](https://pypi.python.org/pypi/robotframework-sshlibrary)
    ```
    $ pip install robotframework-sshlibrary
    $ pip install robotframework-scplibrary
    ```

## OpenBMC Test Development ##

These documents contain details on developing OpenBMC test code and debugging.

 - [CONTRIBUTING.md](CONTRIBUTING.md): Coding guidelines.
 - [REST-cheatsheet.md](https://github.com/openbmc/docs/blob/master/REST-cheatsheet.md): Quick reference for some common
   curl commands required for testing.
 - [README.md](https://github.com/openbmc/phosphor-webui/blob/master/README.md): Web UI setup reference.

## Testing Setup Steps ##

To verify the installation setup is completed and ready to execute.

* Download the openbmc-test-automation repository:
    ```
    $ git clone https://github.com/openbmc/openbmc-test-automation
    $ cd openbmc-test-automation
    ```
* Execute basic setup test run:
    ```
    $ robot -v OPENBMC_HOST:xx.xx.xx.xx templates/test_openbmc_setup.robot
    ```
    where xx.xx.xx.xx is the BMC hostname or IP.

## Test Layout ##

There are several sub-directories within the openbmc-test-automation base which
contain test suites, tools, templates, etc. These sub-directories are
classified as follows:

`tests/`: Contains the general test cases for OpenBMC stack functional
          verification.

`extended/`: Contains test cases for boot testing, network testing,
             code update testing etc.

`systest/`: Contains test cases for HTX bootme.

`xcat/`: Contains test cases for XCAT automation.

`ras/`: Contains test cases for RAS (Reliability, availability and
        serviceability).

`gui/`: Contains test cases for web UI and security scanning tool automation.

`tools/`: Contains various tools.

`templates/`: Contains sample code examples and setup testing.
`

## Quickstart ##
To run openbmc-automation first you need to install the prerequisite Python
packages which will help to invoke tests through tox (Note that tox
version 2.3.1 or greater is required) or via Robot CLI command.

**Robot Command Line**

* Execute all test suites for `tests/`:
    ```
    $ robot -v OPENBMC_HOST:xx.xx.xx.xx  tests
    ```
* Execute a test suite:
    ```
    $ robot -v OPENBMC_HOST:xx.xx.xx.xx  tests/test_basic_poweron.robot
    ```
**Tox Command Line**

* Install the python dependencies for tox:
    ```
    $ easy_install tox
    $ easy_install pip
    ```

* Initialize the following environment variables which will be used during testing:
    ```
    $ export OPENBMC_HOST=<openbmc machine ip address>
    $ export OPENBMC_PASSWORD=<openbmc password>
    $ export OPENBMC_USERNAME=<openbmc username>
    $ export OPENBMC_MODEL=[./data/Barreleye.py, ./data/Palmetto.py, etc]
    $ export IPMI_COMMAND=<Dbus/External>
    $ export IPMI_PASSWORD=<External IPMI password>
    ```
* For tests requiring PDU, set the following environment variables as well:
    ```
    $ export PDU_IP=<PDU IP address>
    $ export PDU_USERNAME=<PDU username>
    $ export PDU_PASSWORD=<PDU password>
    $ export PDU_TYPE=<PDU type>
    $ export PDU_SLOT_NO=<SLOT number>
    ```
    Note: For PDU_TYPE we support only synaccess at the moment.

* For QEMU tests, set the following environment variables as well:
    ```
    $ export SSH_PORT=<ssh port number>
    $ export HTTPS_PORT=<https port number>
    ```
* For BIOS tests, set the following environment variables as well:
    ```
    $ export PNOR_IMAGE_PATH=<path to>/<machine>.pnor
    ```

* Run tests:
    ```
    $ tox -e tests
    ```

* How to run individual test:

    One specific test:
    ```
    $ tox -e default -- --include Power_On_Test  tests/test_basic_poweron.robot
    ```
    No preset environment variables, default configuration for all supported
    systems:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- tests
    ```
    No preset environment variables, one test case from a test suite:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --include Power_On_Test tests/test_basic_poweron.robot
    ```
    No preset environment variables, the entire test suite:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- tests
    ```

    No preset environment variables, the entire test suite excluding test
    cases using argument file:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/skip_test tests
    ```

    Exclude test list for supported systems:
    ```
    Barrleye:  test_lists/skip_test_barreleye
    Palmetto:  test_lists/skip_test_palmetto
    Witherspoon:  test_lists/skip_test_witherspoon
    ```

* How to run CI and CT bucket test:

    Default CI test bucket list:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/HW_CI tests
    ```

    Default CI smoke test bucket list:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/CT_basic_run tests
    ```

* Run extended tests:

    For BMC code update, download the system type *.all.tar image from https://openpower.xyz
    and run as follows:

    For Barreleye system:
    ```
    $ robot -v OPENBMC_HOST:x.x.x.x -v FILE_PATH:downloaded_path/barreleye-xxxx.all.tar  extended/code_update/update_bmc.robot
    ```
    For loop test (default iteration is 10):
    ```
    $ robot -v OPENBMC_HOST:x.x.x.x -v OPENBMC_SYSTEMMODEL:xxxxxx -v ITERATION:n -v LOOP_TEST_COMMAND:xxxxxx extended/full_suite_regression.robot
    ```
    Example using tox testing a test suite for 5 times:
    ```
    OPENBMC_HOST=x.x.x.x  LOOP_TEST_COMMAND="--argumentfile test_lists/skip_test tests/test_fw_version.robot" ITERATION=5  OPENBMC_SYSTEMMODEL=barreleye tox -e barreleye -- ./extended/full_suite_regression.robot
    ```

**Jenkins jobs tox commands**
* HW CI tox command:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/HW_CI tests
    ```

**Tools**

* Github script:

    Command to get GitHub issues (any GitHub repository) report in CSV format:

    Note: On Prompt "Enter your GitHub Password:" enter your GitHub password.

    Usage:
    ```
    $ cd tools/
    $ python github_issues_to_csv <github user> <github repo>
    ```
    Example for getting openbmc issues:
    ```
    $ python github_issues_to_csv <github user>  openbmc/openbmc
    ```
    Example for getting openbmc-test-automation issues:
    ```
    $ python github_issues_to_csv <github user>  openbmc/openbmc-test-automation
    ```

* Generate Robot test cases documentation:

    Usage:
    ```
    $ ./generate_test_document <Robot test directory path> <test case document file path>
    ```

    Example for generating tests cases documentation for tests directory:
    ```
    $ ./generate_test_document tests testsdirectoryTCdocs.html
    ```

    Example for generating tests cases documentation (tests, gui, extended TCs):
    Note: Invoke the tool without argument:
    ```
    $ ./generate_test_document
    ```
