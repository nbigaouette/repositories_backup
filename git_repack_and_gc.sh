#!/bin/bash

# Written by Nicolas Bigaouette
# nbigaouette@gmail.com
# June 2012
# v0.2

. git_repos.conf
. backup_git_repos_functions.sh

log "Starting packing up git repos on `date`"                                   2>&1 | tee -a ${logfile}
loop_over_all_repos "Packing" "${cmd_pack_all_repos}"
log "Done packing up git repos on `date`"                                       2>&1 | tee -a ${logfile}

