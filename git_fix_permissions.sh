#!/bin/bash

# Written by Nicolas Bigaouette
# nbigaouette@gmail.com
# June 2012
# v0.2

. git_repos.conf
. backup_git_repos_functions.sh

log "Starting fixing git repos' permissions on `date`"                                   2>&1 | tee -a ${logfile}
loop_over_all_repos "Fixing permissions" "${cmd_fix_permissions}"
log "Done fixing git repos' permissions on `date`"                                       2>&1 | tee -a ${logfile}

