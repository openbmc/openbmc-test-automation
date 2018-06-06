## Tools available in OpenBMC Test Automation ##

**Hardware Test Executive (HTX):**

HTX is a suite of test tools for stressing system hardware. It is routinely
used by the test suites under `systest/`. Refer to [README](https://github.com/open-power/HTX)

* SEL to error log conversion procedure:

    Pre-requisite: A Power Linux system is required to build the tools.

    ** Obtaining SEL parser tools: **
    - Go to https://openpower.xyz/job/openpower-op-build/
    - Click the link for the BMC system of interest (e.g. witherspoon)
    - Download the host_fw_debug.tar
    - Untar the tarball with the following command:
      ```
      $ tar -xvf host_fw_debug.tar
      ```

    - Execute the following command:
      ```
      $ for file_name in host_fw_debug* ; do mv $file_name ${file_name#host_fw_debug} ; done
      ```

    The following files should exist:
    eSEL.pl
    hbotStringFile
    hbicore.syms

    An error log binary parser is also required:
    - Go to https://sourceforge.net/projects/linux-diag/files/ppc64-diag/
    - Download the latest release version of the source tar zipped.
    - Extract the file and compile. Refer README in the source.
    - On successful compilation, get `opal-elog-parse` binary.

    **Generating error log from SEL binary data:**

    Run the following command:

    Create a directory and copy all the required binaries and script.

    ```
    $ export PATH=$PATH:<path to directory>
    ```

    ```
    $ eSEL.pl -l SEL_data -p decode_obmc_data --op
    ```
    where `SEL_data` is the file containing SEL binary data and option "--op"
    will refer "opal-elog-parse" instead or errl.

    This command will generate a SEL_data.txt file.


**This document describes the tools available in the /tools directory.**

* Obtain a copy of GitHub issues in CSV format:

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

* Generate Robot test cases documentation:

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
