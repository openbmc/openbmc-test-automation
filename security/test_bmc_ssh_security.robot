*** Settings ***
Documentation    Test BMC SSH security.

Resource         ../lib/resource.robot
Resource         ../lib/openbmc_ffdc_methods.robot

*** Variables ***

@{allowed_shell_rcs}   ${255}
${ignore_err}          ${0}

# Left anchor for this regex is either a space or a comma.
${left_anchor}         [ ,]
# Right anchor for this regex is either a comma or end-of-line.
${right_anchor}        (,|$)

${weak_key_regex}   ${left_anchor}(group1_sha1|DES-CBC3|CBC mode|group1|SHA1)${right_anchor}
${mac_key_regex}    ${left_anchor}(MD5|96-bit MAC algorithms)${right_anchor}

*** Test Cases ***

Verify BMC SSH Weak Cipher And Algorithm
    [Documentation]  Connect to BMC and verify no weak cipher and algorithm is
    ...              supported.
    [Tags]  Verify_BMC_SSH_Weak_Cipher_And_Algorithm

    # The following is a sample of output from ssh -vv:
    # This test requires OpenSSH and depends on output format of ssh -vv.
    # debug2: KEX algorithms: curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,
    #         ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,
    #         diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256,
    #         diffie-hellman-group14-sha1
    # debug2: host key algorithms: rsa-sha2-512,rsa-sha2-256,ssh-rsa
    # debug2: ciphers ctos: chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,
    #         aes128-gcm@openssh.com,aes256-gcm@openssh.com
    # debug2: ciphers stoc: chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,
    #         aes128-gcm@openssh.com,aes256-gcm@openssh.com
    # debug2: MACs ctos: umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,
    #         hmac-sha2-512-etm@openssh.com,hmac-sha1-etm@openssh.com,
    #         umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-sha1
    # debug2: MACs stoc: umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,
    #         hmac-sha2-512-etm@openssh.com,hmac-sha1-etm@openssh.com,
    #         umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-sha1

    # Example of weak algorithms to check:
    # - encryption: triple-DES ("DES-CBC3").
    # - encryption: CBC mode
    # - MAC: MD5 and 96-bit MAC algorithms
    # - KEX: diffie-hellman-group1(any) , (any) SHA1

    Printn
    ${ssh_cmd_buf}=  Catenate  ssh -o NumberOfPasswordPrompts=0 UserKnownHostsFile=/dev/null
    ...  StrictHostKeyChecking=no -vv ${OPENBMC_HOST} 2>&1
    Shell Cmd  ! ${ssh_cmd_buf} | egrep -- "${weak_key_regex}"
    Shell Cmd  ! ${ssh_cmd_buf} | egrep -- "${mac_key_regex}"
