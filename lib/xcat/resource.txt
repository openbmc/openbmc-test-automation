*** Variables ***

# XCAT related parameters

${XCAT_HOST}      ${EMPTY}
${XCAT_USERNAME}  ${EMPTY}
${XCAT_PASSWORD}  ${EMPTY}
${XCAT_PORT}      22
${XCAT_DIR_PATH}  /opt/xcat/bin/
${GROUP}          openbmc

# Default BMC nodes config file.

${NODE_CFG_FILE_PATH}  ../lib/xcat/bmc_nodes.cfg
