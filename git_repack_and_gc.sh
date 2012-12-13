#!/bin/bash

# Copyright 2012 Nicolas Bigaouette
# This file is part of repositories_backup.
# https://github.com/nbigaouette/repositories_backup
#
# repositories_backup is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# repositories_backup is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with repositories_backup.  If not, see <http://www.gnu.org/licenses/>


. git_repos.conf
. backup_git_repos_functions.sh

log "Starting packing up git repos on `date`"                                   2>&1 | tee -a ${logfile}
loop_over_all_repos "Packing" "${cmd_pack_all_repos}"
log "Done packing up git repos on `date`"                                       2>&1 | tee -a ${logfile}

