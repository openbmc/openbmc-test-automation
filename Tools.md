## Tools available in OpenBMC Test Automation ##

**This document describes the tools available in the /tools directory.**

* SEL to an error log conversion procedure:

    Pre-requisite: Power Linux system to build tools required.

    **SEL parser needed binaries:**
    From host boot build https://openpower.xyz/job/openpower-op-build/, find
    the host_fw_debug.tar for the given system and download the debug tar file.

    Example: Witherspoon debug tar file
    https://openpower.xyz/job/openpower-op-build/target=witherspoon/lastSuccessfulBuild/artifact/images/host_fw_debug.tar

    Extract tarball and get the following needed files:
    eSEL.pl
    hbotStringFile
    hbicore.syms

    You can refer the eSEL.py parser from https://github.com/open-power/hostboot/blob/master/src/build/debug/eSEL.pl

    An error log binary parser is needed which you can download the source from
    https://sourceforge.net/projects/linux-diag/files/ppc64-diag/ and compile.
    Choose the latest release version of the source tar zipped.

    On successful compilation, get `opal-elog-parse` binary.

    Modify eSEL.pl file string "errl" with "opal-elog-parse".

    Example:
    ```
    $cmd = "$cd_syms_dir $fspt_path $errl_path/errl --file=$bin_file_name $string_file -d 2>&1";
    ```

    ```
    $cmd = "$cd_syms_dir $fspt_path $errl_path/opal-elog-parse -f $bin_file_name -a 2>&1";
    ```

    **Generating error log from SEL binary data:**

    Using the eSEL.pl script, execute

    ```
    $ eSEL.pl -l SEL_data -p decode_obmc_data
    ```
    where `SEL_data` is the file containing SEL binaries data. It would
    generate error log text file SEL_data.txt



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
