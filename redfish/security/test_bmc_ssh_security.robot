*** Settings ***
Documentation    Test BMC SSH security.

Resource         ../../lib/resource.robot
Resource         ../../lib/openbmc_ffdc_methods.robot

*** Variables ***

@{allowed_shell_rcs}   ${255}
${ignore_err}          ${0}

# Left anchor for this regex is either a space or a comma.
${left_anchor}         [ ,]
# Right anchor for this regex is either a comma or end-of-line.
${right_anchor}        (,|$)

${weak_key_regex}   group1_sha1|DES-CBC3|CBC mode|group1|SHA1
${mac_key_regex}    MD5|96-bit MAC algorithms

*** Test Cases ***

Verify BMC SSH Weak Cipher And Algorithm
    [Documentation]  Connect to BMC and verify no weak cipher and algorithm is
    ...              supported.
    [Tags]  Verify_BMC_SSH_Weak_Cipher_And_Algorithm

    # Example of weak algorithms to check:
    # - encryption: triple-DES ("DES-CBC3").
    # - encryption: CBC mode
    # - MAC: MD5 and 96-bit MAC algorithms
    # - KEX: diffie-hellman-group1(any) , (any) SHA1

    Shell Cmd  ! ssh -o NumberOfPasswordPrompts=0 -vvv ${OPENBMC_HOST} 2>&1 | egrep -- "${left_anchor}(${weak_key_regex})${right_anchor}"
    Shell Cmd  ! ssh -o NumberOfPasswordPrompts=0 -vvv ${OPENBMC_HOST} 2>&1 | egrep -- "${left_anchor}(${mac_key_regex})${right_anchor}"

*** Keywords ***

