# OpenBMC Test Automation

## Features of OpenBMC Test Automation

### Interface Feature List

- DMTF Redfish
- Out-of-band IPMI
- SSH to BMC and Host OS
- [Legacy REST](https://github.com/openbmc/openbmc-test-automation/releases/tag/v4.0-stable)

### Key Feature List

- Power on/off
- Reboot Host
- Reset BMC
- Code update for BMC and host
- Power management
- Fan controller
- HTX bootme
- XCAT execution
- Network
- IPMI support (generic and DCMI compliant)
- Factory reset
- RAS (Reliability, Availability, and Serviceability)
- Web UI testing
- Secure boot
- SNMP (Simple Network Management Protocol)
- Remote logging via Rsyslog
- LDAP (Lightweight Directory Access Protocol)
- Certificate management
- Local user management (Redfish/IPMI)
- DateTime
- Event logging
- PLDM (Platform Level Data Model) via pldmtool

### Debugging Support List

- SOL collection
- FFDC collection
- Error injection from host

## Installation Setup Guide

### Prerequisites

- [Robot Framework Install Instructions](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)

**Note:** If using Python 3.x, use the corresponding `pip3` to install packages.
Python 2.x is no longer actively supported.

### Installing Required Dependencies

Install the required packages and their dependencies via `pip`:

```bash
$ pip install -r requirements.txt
```

### Optional Packages

Optional packages required for `redfish/dmtf_tools/`:

```bash
$ pip install -r requirements_optional.txt
```

You'll find these files once you clone the openbmc-test-automation repository.

### Web UI (GUI) Testing Setup

For Web UI (GUI) testing setup, please follow the instructions in the
[OpenBMC GUI Test Setup Guide](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/gui_setup_reference.md).

**Note:** GUI test cases under `gui/` will not work without completing the setup
in your environment.

### Installing Tox

```bash
$ pip install -U tox
```

### Installing Expect (Ubuntu Example)

```bash
$ sudo apt-get install expect
```

## OpenBMC Test Development

These documents contain details on developing OpenBMC test code and debugging:

- [MAINTAINERS](OWNERS): OpenBMC test code maintainers information
- [CONTRIBUTING.md](CONTRIBUTING.md): Coding guidelines
- [Code Check Tools](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/code_standards_check.md):
  Check common code misspellings, syntax, and standard checks
- [Redfish Coding Guidelines](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/redfish_coding_guidelines.md):
  Redfish coding guidelines reference
- [REST Cheat Sheet](https://github.com/openbmc/docs/blob/master/REST-cheatsheet.md):
  Quick reference for common curl commands required for legacy REST testing
- [REDFISH Cheat Sheet](https://github.com/openbmc/docs/blob/master/REDFISH-cheatsheet.md):
  Quick reference for common curl commands required for Redfish testing
- [Web UI README](https://github.com/openbmc/webui-vue/blob/master/README.md):
  Web UI setup reference
- [Redfish Request Via mTLS](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/redfish_request_via_mTLS.md):
  Reference for Redfish requests via mTLS
- [Corporate CLA and Individual CLA](https://github.com/openbmc/docs/blob/master/CONTRIBUTING.md#submitting-changes-via-gerrit-server):
  Submitting changes via Gerrit server

## OpenBMC Test Documentation

- [OpenBMC Test Architecture](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/openbmc_test_architecture.md):
  Reference for OpenBMC test architecture
- [Tools](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/openbmc_test_tools.md):
  Reference information for helper tools
- [Code Update](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/code_update.md):
  Currently supported BMC and PNOR updates
- [Certificate Generate](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/certificate_generate.md):
  Steps to create and install CA-signed certificates
- [Boot Test](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/boot_test.md):
  Boot test for OpenBMC

## Supported System Architectures

OpenBMC test infrastructure is proven capable of running on:

- POWER
- x86 systems running OpenBMC firmware stack

## Testing Setup Steps

To verify the installation setup is complete and ready to execute:

1. Download the openbmc-test-automation repository:

   ```bash
   $ git clone https://github.com/openbmc/openbmc-test-automation
   $ cd openbmc-test-automation
   ```

2. Execute basic setup test run:

   ```bash
   $ robot -v OPENBMC_HOST:xx.xx.xx.xx templates/test_openbmc_setup.robot
   ```

   Where `xx.xx.xx.xx` is the BMC hostname or IP address.

## Test Layout

The openbmc-test-automation base directory contains several sub-directories with
test suites, tools, templates, etc. These sub-directories are classified as
follows:

- **`docs/`**: Documentation related to OpenBMC
- **`redfish/`**: General test cases for OpenBMC stack functional verification
- **`systest/`**: Test cases for HTX bootme testing
- **`xcat/`**: Test cases for XCAT automation
- **`gui/test/`**: Test cases for testing the web-based interface built on
  AngularJS
- **`gui/gui_test/`**: Test cases for testing the web-based user interface built
  on Vue.js
- **`pldm/`**: Test cases for platform management subsystem (base, BIOS, FRU,
  platform, OEM)
- **`snmp/`**: Test cases for SNMP (Simple Network Management Protocol)
  configuration testing
- **`openpower/`**: Test cases for OpenPOWER-based systems
- **`tools/`**: Various tools
- **`templates/`**: Sample code examples and setup testing
- **`test_list/`**: Argument files used for skipping test cases (e.g.,
  "skip_test", "skip_test_extended") or grouping them (e.g., "HW_CI",
  "CT_basic_run")

## Redfish Test Layout

OpenBMC is moving steadily towards DMTF Redfish, an open industry standard
specification and schema that meets end-user expectations for simple, modern,
and secure management of scalable platform hardware.

- **`redfish/`**: Test cases for DMTF Redfish-related features supported on
  OpenBMC
- **`redfish/extended/`**: Test cases for combined DMTF Redfish-related features
  supported on OpenBMC (some tests will be deprecated)

**Note:** Work-in-progress test development parameter `-v REDFISH_SUPPORT_TRANS_STATE:1` forces test suites to execute in Redfish mode only.

## Quickstart

To run openbmc-automation, first install the prerequisite Python packages to invoke tests through tox (Note: tox version 2.3.1 or greater is required) or via Robot CLI command.

### Robot Command Line

#### Execute All Test Suites

Execute all test suites for `redfish/` and `ipmi/`:

```bash
$ robot -v OPENBMC_HOST:xx.xx.xx.xx redfish ipmi
```

#### Execute a Single Test Suite

```bash
$ robot -v OPENBMC_HOST:xx.xx.xx.xx redfish/extended/test_basic_ci.robot
```

### Initialize Test Variables

Test variables can be initialized in two ways:

#### Option 1: Environment Variables

```bash
$ export OPENBMC_HOST=<openbmc machine IP address/hostname>
$ export OPENBMC_USERNAME=<openbmc username>
$ export OPENBMC_PASSWORD=<openbmc password>
$ export IPMI_COMMAND=<Dbus/External>
```

#### Option 2: Robot Variables (CLI)

```bash
-v OPENBMC_HOST:<openbmc machine IP address/hostname>
-v OPENBMC_USERNAME:<openbmc username>
-v OPENBMC_PASSWORD:<openbmc password>
```

### Testing in QEMU

Set extra environment variables:

```bash
$ export SSH_PORT=<ssh port number>
$ export HTTPS_PORT=<https port number>
```

Run the QEMU CI test suite:

```bash
$ OPENBMC_HOST=xx.xx.xx.xx SSH_PORT=<port number> HTTPS_PORT=<port number> robot -A test_lists/QEMU_CI redfish/ ipmi/
```

### Running Tests

#### Run an Individual Test

```bash
$ OPENBMC_HOST=xx.xx.xx.xx tox -e default -- --include Test_SSH_And_IPMI_Connections redfish/extended/test_basic_ci.robot
```

#### Run CI and CT Bucket Tests

Default CI test bucket list:

```bash
$ OPENBMC_HOST=xx.xx.xx.xx tox -e default -- --argumentfile test_lists/HW_CI redfish/ ipmi/
```

Default CI smoke test bucket list:

```bash
$ OPENBMC_HOST=xx.xx.xx.xx tox -e default -- --argumentfile test_lists/CT_basic_run redfish/ ipmi/
```

### Exclude Test Lists for Supported Systems

**Witherspoon:** `test_lists/skip_test_witherspoon`

Using the exclude lists (example for Witherspoon):

```bash
$ robot -v OPENBMC_HOST:xx.xx.xx.xx -A test_lists/skip_test_witherspoon redfish/ ipmi/
```

### Run IPMI Tests via Robot CLI

#### Running Only Out-of-Band IPMI Tests

```bash
$ robot -v IPMI_COMMAND:External -v OPENBMC_HOST:xx.xx.xx.xx --argumentfile test_lists/witherspoon/skip_inband_ipmi ipmi/
```

#### Running Only In-Band IPMI Tests

```bash
$ robot -v IPMI_COMMAND:Inband -v OPENBMC_HOST:xx.xx.xx.xx -v OS_HOST:xx.xx.xx.xx -v OS_USERNAME:xxxx -v OS_PASSWORD:xxxx --argumentfile test_lists/witherspoon/skip_oob_ipmi ipmi/
```

### Run GUI Tests via Robot CLI

By default, GUI runs with Firefox browser in headless mode. Example with Chrome browser and header mode:

```bash
$ robot -v OPENBMC_HOST:xx.xx.xx.xx -v GUI_BROWSER:gc -v GUI_MODE:header gui/test/
```

Run GUI default CI test bucket:

```bash
$ robot -v OPENBMC_HOST:xx.xx.xx.xx --argumentfile test_lists/BMC_WEB_CI gui/test/
```

### Run LDAP Tests via Robot CLI

Before using LDAP test functions, ensure appropriate LDAP user(s) and group(s) have been created on your LDAP server.

**Note:** There are multiple ways to create LDAP users/groups depending on your LDAP server:
- **OpenLDAP:** Use `ldapadd`/`ldapmodify` (refer to [ldapadd man page](https://linux.die.net/man/1/ldapadd))
- **ldapsearch:** Refer to [ldapsearch man page](https://linux.die.net/man/1/ldapsearch)
- **Microsoft ADS:** Refer to [Microsoft Active Directory Domain Services](https://searchwindowsserver.techtarget.com/definition/Microsoft-Active-Directory-Domain-Services-AD-DS)

The format to invoke LDAP tests is as follows:

```bash
$ cd redfish/account_service/
$ robot -v OPENBMC_HOST:xx.xx.xx.xx \
  -v LDAP_SERVER_URI:<ldap(s)//LDAP Hostname / IP> \
  -v LDAP_BIND_DN:<LDAP Bind DN> \
  -v LDAP_BASE_DN:<LDAP Base DN> \
  -v LDAP_BIND_DN_PASSWORD:<LDAP Bind password> \
  -v LDAP_SEARCH_SCOPE:<LDAP search scope> \
  -v LDAP_SERVER_TYPE:<LDAP server type> \
  -v LDAP_USER:<LDAP user-id> \
  -v LDAP_USER_PASSWORD:<LDAP PASSWORD> \
  -v GROUP_NAME:<Group Name> \
  -v GROUP_PRIVILEGE:<Privilege> \
  ./test_ldap_configuration.robot
```

### Host CPU Architecture

By default, the openbmc-test-automation framework assumes the host CPU is based on the POWER architecture. If your host CPU is x86, add the `-v PLATFORM_ARCH_TYPE:x86` variable setting to your CLI commands or set an environment variable:

```bash
$ export PLATFORM_ARCH_TYPE=x86
```

## Jenkins Jobs Tox Commands

### HW CI Tox Command

```bash
$ OPENBMC_HOST=xx.xx.xx.xx tox -e default -- --argumentfile test_lists/HW_CI redfish/ ipmi/
```

## Contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.
