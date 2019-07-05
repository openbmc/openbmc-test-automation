#  OpenBMC Functional Verification Test Specification for all content which includes Release 2.7

[https://github.com/openbmc/openbmc/labels/Release2.7](https://github.com/openbmc/openbmc/labels/Release2.7)

Version: 0.1
15 Mar 2019
Owner: Sivas SRR
Email:sivas.srr@in.ibm.com


##  Objective of OpenBMC FVT

The goal of functional verification test is to identify and fix problems that
would ensure usability of the OpenBMC based servers. These functionality tests
are focused on the basic hardware and firmware(OpenBMC) functionality to ensure
that code development and job execution functions meet the essential
requirements for working on Intel / Power / AMD based servers.

This doc is focused on testing the IBM Witherspoon system which is
[OpenPower](https://openpowerfoundation.org/) based.

## Assumptions

 - unit test performed by contributors
 - function test performed by testers
 - regression tests, largely performed by our automated test cases from
 [https://github.com/openbmc/openbmc-test-automation](https://github.com/openbmc/openbmc-test-automation)

##  Functional Verification Test (FVT) Pre-requisite Requirements

 - POWER chip based server to test with both OpenBMC and PNOR image
 - Testable functionality available with unit test completion by contributors
 - Ipmitool
 - openbmctool ( This is for IBM Power system specific )
 - HTX tool
 - LDAP server setup

## Phases of FVT

Functional Test Cycle (FTC):

A test phase to ensure the function implementation meets architectural
specification (i.e. the requirements, the assumptions, etc) as documented in
the design document. In this test phase, Function owners work with test owners
to define and execute tests to prove individual functions meet functional
requirements.

The main objective of FTC is to catch coverage and variation type of defects
in a simple operating environment with limited system workload.

FVT Regression Phase:

In this phase, all test cases or higher priority test cases which was
identified in FTC cycle will be tested. Some times along with other functions
which can help us to identify more bugs.

For eg. Run HTX on host OS and do BMC reset functional testing.

## Functional Verification Test Scope

Any feature which is newly introduced in OpenBMC will be in part of functional
verification test scope. That includes feature which includes in all the
interface (Redfish (Not sure about complete removal of REST), IPMI with
IPMI 2.0 support, GUI).

Feature should be used by end user.

Some function like secureboot which starts from BMC to HOST, may need to test
from end to end (E2E) perspective. Basically whichever feature / function of
POWER server touches BMC then it will be included.

If function is purely host firmware / host related then it wouldn’t be come
under the scope of OpenBMC FVT test scope.

List of features of BMC currently in scope:

 - BMC Reset
 - BMC Network related (both IPV4 / IPV6)
 - Factory reset
 - Code  update OpenBMC / PNOR
 - HOST Power on / Power off
 - Power Management
 - Fan Speed Controller
 - IPMI (including DCMI compliant)
 - OpenBMC GUI Testing includes KVM Over IP
 - Secureboot
 - SNMP – Simple Network Management Protocol
 - Remote Logging via Rsyslog
 - Certificates LDAP – Lightweight Directory Access Protocol
 - openbmctool

Extended Scope:

 - HTX Soft bootme –  OS continuous boot
 - HTX Hard bootme – Whole system power cycle and boot all the way to OS and
   run HTX
 - GPU / IO related test  - Depend on availability of adequate HW

Exclusion:

Features which is related to testing using OpenBMC command like busctl,
systemctl etc. is considered as out of scope.

Those should be covered part of development unit test.

# Test Methodology

 - Interface Test
 - Functional Test
 - HOST Test
 - Stress Test - Bootme

**Entry Criteria for test:**

The inputs to _FTC_ and the corresponding _FTC_ entry criteria are addressed on a
function by function basis. Different functions may start their test efforts at
different times, so long as the entry criteria is met for that function. The
following general requirements must be satisfied in order for the _FTC_ testing
to formally begin:

 - The function content should be clearly defined. The high level design is
   complete for test plan and test cases development
 - The target driver is identified; the test plan(s) and/or test matrix are
   approved by the functional owner/developer.
 - All new code for the tested function has been integrated into the target
   driver
 - The function is unit test complete.
 - For pervasive functions, all subsystem _FTC_ activities have been completed
 - The test environment is ready for test execution (required HW configuration
   is available, and setup, etc)
 - The _FTC_ result tracking mechanism is setup (execution records defined)
 - In the event of staged entry, the complete integration plan must include
   all key interim milestones (clearly identify the sub-function/component
   that is _FTC_ ready)In addition to the above general entry criteria, the
   individual functional test plans should also identify specific measures
   to evaluate the readiness of the function, such as basic function
   operating scenarios, related component defect backlog, etc. before entering
   _FTC_ .

**Exit Criteria for test:**

The general exit criteria include: All (100%) test cases have been attempted
according to each test plan.

 - All (100%) test execution is complete. Completion of test execution is
   defined as:
 - the test case execution results match the expect function behaviors without
   any defect- or - **defect(s) were opened due to the test case execution
   results did not match the expect function behaviors. However, all defects
   have been effectively addressed. One or a combination of the following
   actions may be considered as effectively addressing a defect:
     - A redesign and/or code implementation correct the misbehavior. The
       defect is then verified with an official build and closed.
     - With the OpenBMC community approval, document the new behavior for
       the end user (customer) as the expected behavior.
     - Defect verification and test case re-execution may not use sandbox
       build or firmware patch. All defect fixes have been integrated, built,
       and verified with an officially released driver.
 - All test execution and results have been documented, reported and archived.
   Below is the repository of previous release.



Previous 2.6 release test result @  [https://drive.google.com/drive/folders/1eBTVYVa6tOhzKlZg5iK10Y323UsJve8A](https://drive.google.com/drive/folders/1eBTVYVa6tOhzKlZg5iK10Y323UsJve8A)


## Continuous Test Environments:


Whole Automation code is located at
[https://github.com/openbmc/openbmc-test-automation](https://github.com/openbmc/openbmc-test-automation)

Base Automation Test code available at
[https://github.com/openbmc/openbmc-test-automation/tree/master/tests](https://github.com/openbmc/openbmc-test-automation/tree/master/tests)

Redfish Automation Test code available at
[https://github.com/openbmc/openbmc-test-automation/tree/master/redfish](https://github.com/openbmc/openbmc-test-automation/tree/master/redfish)

Dependencies:

 - POWER server / other chip based server to test with both OpenBMC and
   PNOR image
 - Testable functionality available with unit test completion
 - Ipmitool
 - openbmctool
 - HTX tool
 - LDAP server setup

## Functional Verification Test Areas

|--------------------|---------------------------|------------|
|**Functional Area**  | **Test Case Description** |**Remarks** |
|Base Infrastructure – Yocto Refresh| Ability to stop at Uboot, check printenv/setenv and boot with kernel,
Kernel stability |
|Aspeed host p2a bridge driver|Test communication between the host and BMC to coordinate communications over the P2A bridge|No direct test, unit test will get covered.|
|NVMe-MI over SMBus|Ability to turn the fault LED on/off for each NVMe drives,Capability of communication over hardware channel I2C to NVMe drives.|Test owner to be checked with “tony.lee@quantatw.com|
|Redfish Interface|Verify basic  Redfish CURD operations|Make sure we get return code as 200|
|Codeupdate| BMC codeupdate via curl from N+1 level|Via TFTP or upload|
|Codeupdate|PNOR codeupdate via curl from N+1 level |Via TFTP or upload (through Redfish/GUI)|
|Codeupdate|BMC/PNOR code downgrade to N level |Verify able to move back to older version|
|Network Interface|Configure BMC / List configuration with multiple ipv4 configuration, ipv6 configuration, update host name, DNS, MAC address | Include DHCP like customer way and static (lab way) |
|IPMI |IPMI inband and out of band way Sensor data, SEL |Try IPMI 2.0 commands to verify each connection and also IPMI DCMI Compliance |
|System Boot |Make sure able to power on and host processor runs and loads OS |Indirectly checking HOST side of IPL functionalities |
|System Boot | Make sure able to power off from BMC / OS System Reset and BMC reset |Indirectly checking HOST side of IPL functionalities |
|Inventory |Once host is booted and ensure all inventories of system listed properly |CPUs / DIMMs, GPUs, Power Supply, Sensors are main things to watch |
|Sensors |Verify fan sensors, system ambient temperature, PCIe sensors, voltage, VDN, VCS sensors |Verify at both BMC standby / Running  of host state as well |
|LED test |Verify LED Groups like CPU, DIMM, GPU, Power |Try various options like on / off / blink. |
|Energy Scale Test |Check Turbo mode can be enabled / disabled | |
|Energy Scale Test |Ability to set Power capping | |
|Certifications |Web (SSL) / LDAP certification |Verify capable of upload and view certificates |
|User Management |Local user management via Redfish / IPMI – Default single use (root) – Password change |Verify all privileges (admin/user) of users |
|User Management |LDAP based user management |Verify all privileges (admin/user)  of users |
|RAS Test |Inject host checkstop and ensure BMC not getting rebooted |For all RAS test ensure equivalent event log is observed |
|RAS Test  |OCC Error Handling |For all RAS test ensure equivalent event log is observed |
|RAS Test |Fan fault detection |For all RAS test ensure equivalent event log is observed|
|RAS Test |Concurrent repair of Fan |For all RAS test ensure equivalent event log is observed |
|RAS Test |Fan fault detection |For all RAS test ensure equivalent event log is observed |
|RAS Test |Concurrent repair of Power Supply |For all RAS test ensure equivalent event log is observed |
|RAS Test |Brick protection |Ensure able to recover the system |
|RAS Test |Clock test |For all RAS test ensure equivalent event log is observed |
|RAS Test |BMC Dump |Create an error and ensure BMC dump generated |
|GUI / OpenBMC web |Ability to login, Check for system overview, Power Operations, Event logs, Inventory, Sensors, Code update,  User Managments functionality, Serial Over LAN |Test with all supported browser like firefox, chrome, safari. Currently IE is not supported |
|Remote Logging |Test remote logging interface and configuration. Verify rsyslog functionality like
Journald is synced with remote logging server, boot sequence synced with remote logging server. | |
|SNMP |Configure SNMP manager with various port (Alpha/Negative) |Recommend to check with multiple SNMP configurations |
|VGA |Using VGA adapter check video display |Ensure it displays boot progress during system boot and works as the system console at petitboot |
|Security Test |Security scan test on OpenBMC interface using industry standard tool like Qualys, Nessus |Qualys is highly recommended |
|Cooling / Thermal zone |Fan related test and water cooling test |Ensure when system is up and running, fan rpms are in right value |
|Factory Reset |Network reset / Host reset |Network should go to default config, Host boot settings also should move to default |
|Boot devices |Over the network, harddisk |Capability of installing / loading OS |
|Time / Date |Capability of setting DateTime and retrieving it using Redfish commands | |
|BMC Reset |Verify capability of BMC reset both host power off and power on |Ensure no impact to host when host is up and running |
|Serial Port Test |Ability to connect to serial port and login, type commands using serial port | |
|Base Infrastructure – Yacto Refresh |Ability to stop at Uboot, check printenv/setenv and boot with kernel,

Kernel stability | |
| **Communication between BMC and HOST** |
|PLDM/MCTP |Actually there is no direct test, But planning to use pldm tool to test this as of now. MCTP cant be test directly but via PLDM it can be tested | |
|Aspeed host p2a bridge driver |Test communication between the host and BMC to coordinate communications over the P2A bridge |No direct test, unit test will get covered. |
|NVMe-MI over SMBus |Ability to turn the fault LED on/off for each NVMe drives,Capability of communication over hardware channel I2C to NVMe drives. |Test owner to be checked with “tony.lee@quantatw.com” |
|--------------------|---------------------------|------------|
