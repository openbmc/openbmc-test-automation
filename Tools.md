## Tools used in OpenBMC Test Automation ##

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
OpenSSL is an open-source command line tool that is commonly used to generate certificate, private keys, create CSRs, and identify certificate information.

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
