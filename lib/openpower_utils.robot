*** Settings ***

Documentation  OpenPower/PNOR-specific utility keywords.

Resource       ../lib/common_utils.robot

*** Variables ***

${PFLASH_CMD}             /usr/sbin/pflash -r /dev/stdout -P VERSION
${TOTAL_PNOR_RO_FILE_SYSTEM_CMD}=  df -h | grep /media/pnor-ro | wc -l

*** Keywords ***

Verify PNOR Update
    [Documentation]  Verify that the PNOR is not corrupted.

    # Example:
    # FFS: Flash header not found. Code: 100
    # Error 100 opening ffs !

    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  /usr/sbin/pflash -h | egrep -q skip
    ...  ignore_err=${1}
    ${PFLASH_CMD}=  Set Variable If  ${rc} == ${0}  ${PFLASH_CMD} --skip=4096
    ...  ${PFLASH_CMD}
    ${pnor_info}=  BMC Execute Command  ${PFLASH_CMD}
    Should Not Contain Any  ${pnor_info}  Flash header not found  Error


Get PNOR Version
    [Documentation]  Returns the PNOR version from the BMC.

    ${pnor_attrs}=  Get PNOR Attributes

    RETURN  ${pnor_attrs['version']}


Get PNOR Attributes
    [Documentation]  Return PNOR software attributes as a dictionary.

    # This keyword parses /var/lib/phosphor-software-manager/pnor/ro/pnor.toc
    # into key/value pairs.

    ${outbuf}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /var/lib/phosphor-software-manager/pnor/ro/pnor.toc
    ${pnor_attrs}=  Key Value Outbuf To Dict  ${outbuf}  delim==

    RETURN  ${pnor_attrs}


GET BMC PNOR Version
    [Documentation]  Return BMC & PNOR version from openbmc shell.

    ${bmc_version}=  GET BMC Version
    ${pnor_version}=  GET PNOR Version
    Log  ${bmc_version}
    Rprint Vars  bmc_version
    Log  ${pnor_version}
    Rprint Vars  pnor_version

    RETURN  ${bmc_version}  ${pnor_version}
