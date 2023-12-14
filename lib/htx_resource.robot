
*** Variables ***

# Default duration and interval of HTX exerciser to run.
${HTX_DURATION}      2 hours
${HTX_INTERVAL}      15 min

# Default hardbootme loop times HTX exerciser to run.
${HTX_LOOP}          4

# User-defined halt on error.
${HTX_KEEP_RUNNING}  ${0}

# Default MDT profile.
${HTX_MDT_PROFILE}   mdt.bu

# HTX bootme_period:
#        1 - every 20 minutes
#        2 - every 30 minutes
#        3 - every hour
#        4 - every midnight
${BOOTME_PERIOD}    1

