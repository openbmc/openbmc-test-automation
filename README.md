## Features of OpenBMC Test Automation

**Interface Feature List**

- DMTF Redfish
- Out-of-band IPMI
- SSH to BMC and Host OS
- [Legacy REST](https://github.com/openbmc/openbmc-test-automation/releases/tag/v4.0-stable)

**Key Feature List**

- Power on/off
- Reboot Host
- Reset BMC
- Code update BMC and host
- Power management
- Fan controller
- HTX bootme
- XCAT execution
- Network
- IPMI support (generic and DCMI compliant)
- Factory reset
- RAS (Reliability, availability and serviceability)
- Web UI testing
- Secure boot
- SNMP (Simple Network Management Protocol)
- Remote Logging via Rsyslog
- LDAP (Lightweight Directory Access Protocol)
- Certificate
- Local User Management(Redfish/IPMI)
- DateTime
- Event Logging
- PLDM (Platform Level Data Model) via pldmtool

**Debugging Supported List**

- SOL collection
- FFDC collection
- Error injection from host

## Installation Setup Guide

- [Robot Framework Install Instruction](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)

- Miscellaneous Packages required to be installed for OpenBmc Automation.
  Install the packages and it's dependencies via `pip`

If using Python 3.x, use the corresponding `pip3` to install packages. Note:
Older Python 2.x is not actively supported.

Installing requirement dependencies:

```
    $ pip install -r requirements.txt
```

Optional packages but required for `redfish/dmtf_tools/`

```
    $ pip install -r requirements_optional.txt
```

you'll find this file once your clone openbmc-test-automation repository.

For Web UI ( GUI ) Testing setup instructions see
[OpenBMC GUI Test Setup Guide](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/gui_setup_reference.md)

Installing tox:

```
    $ pip install -U tox
```

Installing expect (Ubuntu example):

```
    $ sudo apt-get install expect
```

## OpenBMC Test Development

These documents contain details on developing OpenBMC test code and debugging.

- [MAINTAINERS](OWNERS): OpenBMC test code maintainers information.
- [CONTRIBUTING.md](CONTRIBUTING.md): Coding guidelines.
- [Code Check Tools](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/code_standards_check.md):
  To check common code misspellings, syntax and standard checks.
- [Redfish Coding Guidelines](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/redfish_coding_guidelines.md):
  Refer for Redfish coding guidelines.
- [REST-cheatsheet.md](https://github.com/openbmc/docs/blob/master/REST-cheatsheet.md):
  Quick reference for some common curl commands required for legacy REST
  testing.
- [REDFISH-cheatsheet.md](https://github.com/openbmc/docs/blob/master/REDFISH-cheatsheet.md):
  Quick reference for some common curl commands required for redfish testing.
- [README.md](https://github.com/openbmc/webui-vue/blob/master/README.md): Web
  UI setup reference.
- [Redfish Request Via mTLS](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/redfish_request_via_mTLS.md):
  Reference for Redfish Request Via mTLS .
- [Corporate CLA and Individual CLA](https://github.com/openbmc/docs/blob/master/CONTRIBUTING.md#submitting-changes-via-gerrit-server):
  Submitting changes via Gerrit server

## OpenBMC Test Documentation

- [OpenBMC Test Architecture](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/openbmc_test_architecture.md):
  Reference for OpenBMC Test Architecture.
- [Tools](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/openbmc_test_tools.md):
  Reference information for helper tools.
- [Code Update](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/code_update.md):
  Currently supported BMC and PNOR update.
- [Certificate Generate](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/certificate_generate.md):
  Steps to create and install CA signed certificate.
- [Boot Test](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/boot_test.md):
  Boot test for OpenBMC.

## Supported Systems Architecture

OpenBMC test infrastructure is proven capable of running on:

- POWER
- x86 systems running OpenBMC firmware stack.

## Testing Setup Steps

To verify the installation setup is completed and ready to execute.

- Download the openbmc-test-automation repository:

  ```
  $ git clone https://github.com/openbmc/openbmc-test-automation
  $ cd openbmc-test-automation
  ```

- Execute basic setup test run:

  ```
  $ robot -v OPENBMC_HOST:xx.xx.xx.xx templates/test_openbmc_setup.robot
  ```

  where xx.xx.xx.xx is the BMC hostname or IP.

## Test Layout

There are several sub-directories within the openbmc-test-automation base which
contain test suites, tools, templates, etc. These sub-directories are classified
as follows:

`docs/`: Contains the documentation related to OpenBMC.

`redfish/`: Contains the general test cases for OpenBMC stack functional
verification.

`systest/`: Contains test cases for HTX bootme testing.

`xcat/`: Contains test cases for XCAT automation.

`gui/test/`: Contains test cases for testing web-based interface built on
AngularJS.

`gui/gui_test/`: Contains test cases for testing web-based user interface built
on Vue.js.

`pldm/`: Contains test cases for platform management subsystem (base, bios, fru,
platform, OEM).

`snmp/`: Contains test cases for SNMP (Simple Network Management Protocol)
configuration testing.

`openpower/`: Contains test cases for an OpenPOWER based system.

`tools/`: Contains various tools.

`templates/`: Contains sample code examples and setup testing.

`test_list/`: Contains the argument files used for skipping test cases (e.g
"skip_test", "skip_test_extended", etc.) or grouping them (e.g "HW_CI",
"CT_basic_run", etc.).

## Redfish Test Layout

OpenBMC is moving steadily towards DTMF Redfish, which is an open industry
standard specification and schema that meets the expectations of end users for
simple, modern and secure management of scalable platform hardware.

`redfish/`: Contains test cases for DMTF Redfish-related feature supported on
OpenBMC.

`redfish/extended/`: Contains test cases for combined DMTF Redfish-related
feature supported on OpenBMC. Some of the test will be deprecated.

Note: Work in progress test development parameter
`-v REDFISH_SUPPORT_TRANS_STATE:1` to force the test suites to execute in
redfish mode only.

## Quickstart

To run openbmc-automation first you need to install the prerequisite Python
packages which will help to invoke tests through tox (Note that tox version
2.3.1 or greater is required) or via Robot CLI command.

**Robot Command Line**

- Execute all test suites for `tests/`:

  ```
  $ robot -v OPENBMC_HOST:xx.xx.xx.xx  tests
  ```

- Execute a test suite:

  ```
  $ robot -v OPENBMC_HOST:xx.xx.xx.xx redfish/extended/test_basic_ci.robot
  ```

- Initialize the following test variables which will be used during test
  execution:

  User can forward declare as environment variables:

  ```
  $ export OPENBMC_HOST=<openbmc machine IP address/hostname>
  $ export OPENBMC_USERNAME=<openbmc username>
  $ export OPENBMC_PASSWORD=<openbmc password>
  $ export IPMI_COMMAND=<Dbus/External>
  $ export REST_USERNAME=<REST interface username>
  $ export REST_PASSWORD=<REST interface password>
  ```

  or

  User can input as robot variables as part of the CLI command:

  ```
  -v OPENBMC_HOST:<openbmc machine IP address/hostname>
  -v OPENBMC_USERNAME:<openbmc username>
  -v OPENBMC_PASSWORD:<openbmc password>
  ```

- Testing in qemu:

  Set extra environment variables:

  ```
  $ export SSH_PORT=<ssh port number>
  $ export HTTPS_PORT=<https port number>
  ```

  Run the QEMU CI test suite (not all tests will pass in qemu):

  ```
  $ OPENBMC_HOST=x.x.x.x SSH_PORT=<port number> HTTPS_PORT=<port number> robot -A test_lists/QEMU_CI tests/
  ```

- Run tests:

  ```
  $ tox tests
  ```

- How to run an individual test:

  ```
  $ tox -e default -- --include Power_On_Test  tests/test_basic_poweron.robot
  ```

- No preset environment variables, default configuration for all supported
  systems:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- tests
  ```

- No preset environment variables, one test case from a test suite:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- --include Power_On_Test tests/test_basic_poweron.robot
  ```

- No preset environment variables, the entire test suite:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- tests
  ```

- No preset environment variables, the entire test suite excluding test cases
  using argument file:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/skip_test tests
  ```

- Exclude test list for supported systems:

  ```
  Palmetto:  test_lists/skip_test_palmetto
  Witherspoon:  test_lists/skip_test_witherspoon
  ```

  Using the exclude lists (example for Witherspoon)

  ```
  $ robot -v OPENBMC_HOST:xx.xx.xx.xx -A test_lists/skip_test_witherspoon tests/
  ```

- Run IPMI tests:

  Running only out-of-band IPMI tests:

  ```
  $ robot -v IPMI_COMMAND:External -v OPENBMC_HOST:x.x.x.x --argumentfile test_lists/witherspoon/skip_inband_ipmi tests/ipmi/
  ```

  Running only inband IPMI tests:

  ```
  $ robot -v IPMI_COMMAND:Inband -v OPENBMC_HOST:x.x.x.x -v OS_HOST:x.x.x.x -v OS_USERNAME:xxxx -v OS_PASSWORD:xxxx --argumentfile test_lists/witherspoon/skip_oob_ipmi tests/ipmi/
  ```

- Run GUI tests:

  By default, GUI runs with Firefox browser and headless mode. Example with
  Chrome browser and header mode:

  ```
  $ robot -v OPENBMC_HOST:x.x.x.x -v GUI_BROWSER:gc -v GUI_MODE:header gui/test/
  ```

  Run GUI default CI test bucket:

  ```
  $ robot -v OPENBMC_HOST:x.x.x.x --argumentfile test_lists/BMC_WEB_CI gui/test/
  ```

- Run LDAP tests:

  Before using LDAP test functions, be sure appropriate LDAP user(s) and
  group(s) have been created on your LDAP server. Note: There are multiple ways
  to create LDAP users / groups and all depend on your LDAP server. One common
  way for openldap is ldapadd / ldapmodify refer
  https://linux.die.net/man/1/ldapadd For ldapsearch, refer to
  "https://linux.die.net/man/1/ldapsearch". Microsoft ADS: refer to
  https://searchwindowsserver.techtarget.com/definition/Microsoft-Active-Directory-Domain-Services-AD-DS

  Note: Currently, LDAP test automation for Redfish API is in progress. The
  format to invoke LDAP test is as follows:

  ```
  $ cd redfish/account_service/
  $ robot -v OPENBMC_HOST:x.x.x.x -v LDAP_SERVER_URI:<ldap(s)//LDAP Hostname / IP> -v LDAP_BIND_DN:<LDAP Bind DN> -v LDAP_BASE_DN:<LDAP Base DN> -v LDAP_BIND_DN_PASSWORD:<LDAP Bind password> -v LDAP_SEARCH_SCOPE:<LDAP search scope> -v LDAP_SERVER_TYPE:<LDAP server type> -v LDAP_USER:<LDAP user-id> -v LDAP_USER_PASSWORD:<LDAP PASSWORD> -v GROUP_NAME:<Group Name> -v GROUP_PRIVILEGE:<Privilege>  ./test_ldap_configuration.robot
  ```

- How to run CI and CT bucket test:

  Default CI test bucket list:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/HW_CI tests
  ```

  Default CI smoke test bucket list:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/CT_basic_run tests
  ```

- Run extended tests:

  For-loop test (default iteration is 10):

  ```
  $ robot -v OPENBMC_HOST:x.x.x.x -v OPENBMC_SYSTEMMODEL:xxxxxx -v ITERATION:n -v LOOP_TEST_COMMAND:xxxxxx extended/full_suite_regression.robot
  ```

  Example using tox testing a test suite for 5 iterations "witherspoon":

  ```
  OPENBMC_HOST=x.x.x.x  LOOP_TEST_COMMAND="tests/test_fw_version.robot" ITERATION=5 OPENBMC_SYSTEMMODEL=witherspoon tox -e witherspoon -- ./extended/full_suite_regression.robot
  ```

- Host CPU architecture

  By default openbmc-test-automation framework assumes that host CPU is based on
  the POWER architecture. If your host CPU is x86 add
  `-v PLATFORM_ARCH_TYPE:x86` variable setting to your CLI commands or set an
  environment variable:

  ```
  $ export PLATFORM_ARCH_TYPE=x86
  ```

**Jenkins jobs tox commands**

- HW CI tox command:

  ```
  $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/HW_CI tests
  ```
