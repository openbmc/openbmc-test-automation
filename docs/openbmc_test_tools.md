## Tools used in OpenBMC Test Automation ##

## IPMItool considerations: ##

IPMItool version 1.8.18 or later.
```
    $ ipmitool -V
    ipmitool version 1.8.18
```

## Hardware Test Executive (HTX): ##

HTX is a suite of test tools for stressing system hardware. It is routinely
used by the test suites under `systest/`. Refer to [README](https://github.com/open-power/HTX)

## Remote Logging via Rsyslog ##

Refer to [README](https://github.com/openbmc/phosphor-logging/blob/master/README.md#remote-logging-via-rsyslog)

## Converting SELs to readable format: ##

Pre-requisite: A Power Linux system is required.

* Obtain the SEL (System Error Log) parser tools:
    - Go to https://openpower.xyz/job/openpower-op-build/
    - Click the link for the BMC system of interest (e.g. witherspoon)
    - Click the "host_fw_debug.tar" link in order to download the tar file.
    - On your Power Linux system, untar the file with the following command:
    ```
    $ tar -xvf host_fw_debug.tar
    ```

    - Rename the untarred files with:
    ```
    $ for file_name in host_fw_debug* ; do mv $file_name ${file_name#host_fw_debug} ; done
    ```

    The files of interest are:
    eSEL.pl
    hbotStringFile
    hbicore.syms

* The error log binary parser is also required:
    - Go to https://sourceforge.net/projects/linux-diag/files/ppc64-diag/
    - Download the latest release version of the source tar zipped.
    - Extract the tarball and compile. Refer to README in the source.
    - On successful compilation, get `opal-elog-parse` binary.

* To generate a readable error log from binary SEL data:

   Create a directory and copy the binary files there.  Next,

    ```
    $ export PATH=$PATH:<path to directory>
    ```
   And run
    ```
    $ eSEL.pl -l SEL_data -p decode_obmc_data --op
    ```
    where `SEL_data` is the file containing SEL binary data and option "--op"
    will refer "opal-elog-parse" instead or errl.

    The output file `SEL_data.txt` contains the readable error log (SEL) data.


## The opal-prd Tool: ##
opal-prd is a tool used by the Energy Scale and RAS tests.  It should be
installed on the OS of the system under test before running those tests.

opal-prd may be installed on Ubuntu with:
    ```
    apt install opal-prd
    ```
    and on RedHat with:
    ```
    yum install opal-prd
    ```


## Obtain a copy of GitHub issues in CSV format: ##

Note: You will be prompted to enter your GitHub password.

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


## Generate Documentation for Robot Test Cases: ##

Usage:
```
$ ./tools/generate_test_document <Robot test directory path> <test case document file path>
```

Example for generating tests cases documentation for tests directory:
```
$ ./tools/generate_test_document tests testsdirectoryTCdocs.html
```

Example for generating tests cases documentation:
Note: Invoke the tool without arguments:
```
$ ./tools/generate_test_document
```


## Non-Volatile Memory Express Command Line Interface (nvme-cli): ##

nvme-cli is a linux command line tool for accessing Non-Volatile Storage (NVM) media attached via PCIe bus.

Source: https://github.com/linux-nvme/nvme-cli

To install nvme-cli on RedHat:
```
yum install name-cli
```
To install nvme-cli on Ubuntu:
```
sudo apt-get install nvme-cli
```

* Obtaining the PPA for Ubuntu
    - Add the sbates PPA to your sources: https://launchpad.net/~sbates/+archive/ubuntu/ppa


## The Hdparm tool: ##

hdparm is a command line utility for setting and viewing hardware parameters of hard disk drives.

To install hdparm on RedHat:
```
yum install hdparm
```
To install hdparm on Ubuntu:
```
sudo apt-get update
sudo apt-get install hdparm
```

## OpenSSL tool:
OpenSSL is an open-source command line tool that is commonly used to generate certificates and private keys, create CSRs and identify certificate information.

To generate a self-signed certificate with a private key:

```
openssl req -x509 -sha256 -newkey rsa:2048 -nodes -days <number of days a certificate is valid for> -keyout <certificate filename> -out <certificate filename> -subj "/O=<Organization Name>/CN=<Common Name>"
```

_Example:_
```
openssl req -x509 -sha256 -newkey rsa:2048 -nodes -days 365 -keyout certificate.pem -out certificate.pem -subj "/O=XYZ Corporation /CN=www.xyz.com"
```

To view installed certificates on a OpenBMC system:
```
openssl s_client -connect <BMC_IP>:443 -showcerts
```

Refer to the [OpenSSL manual](https://www.openssl.org/docs/manmaster/man1/req.html) for more details.


## Steps to create and install CA signed certificate

To create and install a CA signed server certificate, follow these steps:

A. Create your own SSL certificate authority
B. Generate CSR for server certificate
C. Create CA signed server certificate using CSR request
D. Install CA signed server certificate

**Create your own SSL certificate authority**

1. Create private key for certificate authority(CA).


```openssl genrsa -des3 -out rootCA.key 2048```

Note: You will be prompted to give a password for private key. This password will be used whenever the private key is used.


2. Create a root CA certificate using the private key created in step 1.

```openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem```

This will start an interactive script to enter information that will be incorporated into your certificate request.

```
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:Oregon
Locality Name (eg, city) []:Portland
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Overlords
Organizational Unit Name (eg, section) []:IT
Common Name (eg, YOUR name) []:Data Center Overlords
Email Address []:none@none.com
```

**Generate CSR for server certificate**

1. Create CSR request file (csr_file.json) with all of the following fields.

```
{
    "City": <City Name>,
    "CertificateCollection": {
        "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
    },
    "CommonName": "<BMC_IP>",
    "Country": <Country Name>,
    "Organization": <Organization Name>,
    "OrganizationalUnit": <Organization Unit Name>,
    "State": <State Name>,
    "KeyPairAlgorithm": <RSA/EC>
}
```

Example:
```
{
    "City": "Austin",
    "CertificateCollection": {
        "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
    },
    "CommonName": "9.3.111.222",
    "Country": "US",
    "Organization": "IBM",
    "OrganizationalUnit": "ISL",
    "State": "AU",
    "KeyPairAlgorithm": "RSA"
}
```

2. Generate CSR request using the following Redfish command.

```
bash-4.1$ curl -c cjar -b cjar -k -H "X-Auth-Token: $bmc_token" -X POST https://${BMC_IP}/redfish/v1/CertificateService/Actions/CertificateService.GenerateCSR/ -d @csr_file.json
{
  "CSRString": "-----BEGIN CERTIFICATE REQUEST-----\nMIIBZzCCARECAQEwgasxJTAjBgNVHREMHHdzYm1jMDE1LmF1cy5zdGdsYWJzLmli\nbS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UEA  wwJOS4zLjIxLjU1MQ8wDQYD\nVQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYEKw4DAgwDUlNBMRUwEwYDVR0P\nDAxLZXlBZ3JlZW1lbnQxDDAKBgNVBA  oMA0lCTTELMAkGA1UECAwCQVUwXDANBgkq\nhkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobpT646Ssn7QmcxLeoWnCIulyP3hKR2f\n4E8Cy3FdO/j3HlrlKxJ  ijB8eBDmdB0zR8CnVUipUcknj4QIDAQABoAAwDQYJKoZI\nhvcNAQELBQADQQBcKCRdSZxqKoH7h4uta27Qchna88ljrJwX3PLqNES5nyCUaacx\ne8Xqddi9  iG7FcnULE9VLzhpr86UTZV4393+s\n-----END CERTIFICATE REQUEST-----\n",
  "CertificateCollection": {
    "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/"
  }
}
```

4. Convert response into .csr file (device.csr)

```
bash-4.1$ cat device.csr
-----BEGIN CERTIFICATE REQUEST-----
MIIBZzCCARECAQEwgasxJTAjBgNVHREMHHdzYm1jMDE1LmF1cy5zdGdsYWJzLmli
bS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UEAwwJOS4zLjIxLjU1MQ8wDQYD
VQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYEKw4DAgwDUlNBMRUwEwYDVR0P
DAxLZXlBZ3JlZW1lbnQxDDAKBgNVBAoMA0lCTTELMAkGA1UECAwCQVUwXDANBgkq
hkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobpT646Ssn7QmcxLeoWnCIulyP3hKR2f
4E8Cy3FdO/j3HlrlKxJijB8eBDmdB0zR8CnVUipUcknj4QIDAQABoAAwDQYJKoZI
hvcNAQELBQADQQBcKCRdSZxqKoH7h4uta27Qchna88ljrJwX3PLqNES5nyCUaacx
e8Xqddi9iG7FcnULE9VLzhpr86UTZV4393+s
-----END CERTIFICATE REQUEST-----
```

**Create CA signed server certificate using CSR request**

1. Use BMC generated CSR request (device.csr) to generate CA signed certificate (device.crt).
```
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 500 -sha256
```


2. Create JSON file (certificate.json) with the device.crt file created in step 1.

```
bash-4.1$ cat certificate.json
{
    "CertificateString": "-----BEGIN CERTIFICATE-----\nMIIC+TCCAeECCQCk+dNJDXfI1jANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMC\nSU4xDjAMBgNVBAgMBURFTEhJMQ4wDAYDVQQHD  AVERUxISTEeMBwGA1UECgwVQ0VS\nVElGSUNBVEUgQVVUSE9SSVRZMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVRGF0YSBD\nZW50ZXIgT3ZlcmxvcmRzMRwwGg  YJKoZIhvcNAQkBFg1ub25lQG5vbmUuY29tMB4X\nDTE5MDYyNzExMTczNloXDTIwMTEwODExMTczNlowgasxJTAjBgNVHREMHHdzYm1j\nMDE1LmF1cy5zdGd  sYWJzLmlibS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UE\nAwwJOS4zLjIxLjU1MQ8wDQYDVQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYE\nKw4D  AgwDUlNBMRUwEwYDVR0PDAxLZXlBZ3JlZW1lbnQxDDAKBgNVBAoMA0lCTTEL\nMAkGA1UECAwCQVUwXDANBgkqhkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobp  T646S\nsn7QmcxLeoWnCIulyP3hKR2f4E8Cy3FdO/j3HlrlKxJijB8eBDmdB0zR8CnVUipU\ncknj4QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAcYmkbcznF  fOm9bDuIeXHzNSus\nEwOhAberTXWvPMtjbDTmbVH5dRPU+DmgS+LEl2jhYC414R89EUApjrXmk1PzlBrN\nXEnBf9+OHOHOH7H4AIni3diw9PRzEdW5ENHUi  OIVoq7LxWP+RknSHGl8AfOghX/3\n6eRgtpIp+fTYwJkGdZaKb9cI5XXk0Eh1cZZ3W43PNsKbuv1BGLGjJVRRaswF9nb1\ng2M4iZLtVXltdkyHW/Z6TUWvG+  9+TYuKingixv0toaWyRGexjC1CeRORGhyYW8Dz\niGipRCWmVo97MC5sWtQjVAshB1TY6rUqipxzW9SqyjplBD+AHySY/IqGM+wU\n-----END CERTIFICATE-----\n",
    "CertificateType": "PEM",
    "CertificateUri":
    {
        "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1"
    }
}
```


**Install CA signed server certificate**

Replace server certificate using JSON file (above) with CA signed certificate details (certificate.json).

```
bash-4.1$ curl -c cjar -b cjar -k -H "X-Auth-Token: $bmc_token" -X POST https://${BMC_IP}/redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate/ -d @certificate.json
{
  "@odata.context": "/redfish/v1/$metadata#Certificate.Certificate",
  "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1",
  "@odata.type": "#Certificate.v1_0_0.Certificate",
  "CertificateString": "-----BEGIN CERTIFICATE-----\nMIIC+TCCAeECCQCk+dNJDXfI1jANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMC\nSU4xDjAMBgNVBAgMBURFTEhJMQ4wDAYDVQQHD  AVERUxISTEeMBwGA1UECgwVQ0VS\nVElGSUNBVEUgQVVUSE9SSVRZMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVRGF0YSBD\nZW50ZXIgT3ZlcmxvcmRzMRwwGg  YJKoZIhvcNAQkBFg1ub25lQG5vbmUuY29tMB4X\nDTE5MDYyNzExMTczNloXDTIwMTEwODExMTczNlowgasxJTAjBgNVHREMHHdzYm1j\nMDE1LmF1cy5zdGd  sYWJzLmlibS5jb20xDzANBgNVBAcMBkF1c3RpbjESMBAGA1UE\nAwwJOS4zLjIxLjU1MQ8wDQYDVQQpDAZteW5hbWUxCzAJBgNVBAYTAlVTMQ0wCwYE\nKw4D  AgwDUlNBMRUwEwYDVR0PDAxLZXlBZ3JlZW1lbnQxDDAKBgNVBAoMA0lCTTEL\nMAkGA1UECAwCQVUwXDANBgkqhkiG9w0BAQEFAANLADBIAkEAwY9eVEdOobp  T646S\nsn7QmcxLeoWnCIulyP3hKR2f4E8Cy3FdO/j3HlrlKxJijB8eBDmdB0zR8CnVUipU\ncknj4QIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAcYmkbcznF  fOm9bDuIeXHzNSus\nEwOhAberTXWvPMtjbDTmbVH5dRPU+DmgS+LEl2jhYC414R89EUApjrXmk1PzlBrN\nXEnBf9+OHOHOH7H4AIni3diw9PRzEdW5ENHUi  OIVoq7LxWP+RknSHGl8AfOghX/3\n6eRgtpIp+fTYwJkGdZaKb9cI5XXk0Eh1cZZ3W43PNsKbuv1BGLGjJVRRaswF9nb1\ng2M4iZLtVXltdkyHW/Z6TUWvG+  9+TYuKingixv0toaWyRGexjC1CeRORGhyYW8Dz\niGipRCWmVo97MC5sWtQjVAshB1TY6rUqipxzW9SqyjplBD+AHySY/IqGM+wU\n-----END CERTIFICATE-----\n",
  "Description": "HTTPS certificate",
  "Id": "1",
  "Issuer": {
    "City": "DELHI",
    "CommonName": "Data Center Overlords",
    "Country": "IN",
    "Organization": "CERTIFICATE AUTHORITY",
    "OrganizationalUnit": "IT",
    "State": "DELHI"
  },
  "KeyUsage": [],
  "Name": "HTTPS certificate",
  "Subject": {
    "City": "Austin",
    "CommonName": "9.3.111.222",
    "Country": "US",
    "Organization": "IBM",
    "State": "AU"
  },
  "ValidNotAfter": "2020-11-07T23:17:36+00:00",
  "ValidNotBefore": "2019-06-26T23:17:36+00:00"
}
```
