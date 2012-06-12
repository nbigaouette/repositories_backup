#!/bin/bash

# Written by Nicolas Bigaouette
# nbigaouette@gmail.com
# June 2012
# v0.2

stars="*********************************************************"
c="\e[36;1m"
n="\e[0m"

s="  "
sudo=""
if [[ "$UID" == "0" ]]; then
    sudo="sudo -u USER"
fi

[[ ! -e "${logdir}" ]] && mkdir -p ${logdir}

prev_permissions_heads=""
prev_permissions_tags=""

cmd_backup_all_repos="backup_repo \${user} \${repo} \${backup_servers[\${i}]} \${backup_servers[\$((\${i}+1))]}"
cmd_pack_all_repos="repack_and_gc \${user} \${repo}"
cmd_fix_permissions="fix_permissions \${user} \${repo}"

log()
{
    echo -e "${c}${@}${n}"
}

list_users()
{
    unset users
    local users
    cd ${repos_path}
    users=(`/bin/ls -d *`)
    echo ${users[@]}
    cd - > /dev/null
}

list_user_repos()
{
    if [[ -z "$1" ]]; then
        echo "Usage: list_user_repos <user>"
        return
    fi
    local_user="$1"

    cd ${repos_path}/${local_user}
    #repos=(`/bin/ls -d *`)
#     repos=(`find . -maxdepth 1 -mindepth 1 -type d | sed "s|./||g"`)
    repos=(`find . -type d -name "*.git" | sed "s|^./||g"`)
    cd - > /dev/null

    #echo "repos (${#repos[@]}) = ${repos[@]}"
    echo ${repos[@]}
}

create_remote_repo()
{
    if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
        echo "Usage: create_remote_repo <local_user> <local_repo> <ssh_server> <remote_location>"
        return
    fi
    local_user="$1"
    local_repo="$2"
    ssh_server="$3"
    remote_location="$4"

    remote_repo="${remote_location}/${local_user}/${local_repo}"

    log "${s}${s}${s}Making sure a bare git repo exist at ${remote_repo} on ${ssh_server}..." \
                                                                                2>&1 | tee -a ${logfile}

    cmd="mkdir -p ${remote_repo} && cd ${remote_repo} && if [[ ! -e 'config' ]]; then git --bare init; fi"
    ssh_cmd="${sudo/USER/${me}} ssh ${ssh_server} ${cmd}"
    #echo "${s}${s}${s}${ssh_cmd}"                                               2>&1 | tee -a ${logfile}
    ${ssh_cmd}
}

setup_repo_for_pushing()
{
    if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then
        echo "Usage: setup_repo_for_pushing <local_user> <local_repo> <ssh_server> <remote_location>"
        return
    fi
    local_user="$1"
    local_repo="$2"
    ssh_server="$3"
    remote_location="$4"

    remote_name="backup_${ssh_server}"

    log "${s}${s}${s}Setting up ${local_user}'s ${local_repo} to push to ${remote_location} on ${ssh_server}..." \
                                                                                2>&1 | tee -a ${logfile}

    cd ${repos_path}/${local_user}/${local_repo}
    remotes=(`${git} remote`)
    remote_present="false"
    for remote in ${remotes[@]}; do
#         # Prune the remote's branches.
#         echo "Pruning..."
#         ${sudo/USER/${local_user}} ${git} remote prune ${remote}                        2>&1 | tee -a ${logfile}

        if [[ "${remote}" == "${remote_name}" ]]; then
            remote_present="true"
        fi
    done

    # Make sure $me can touch refs/heads/master.lock
    # Store previous permission to restore later
    prev_permissions_heads=`\ls refs/heads -dl | awk '{print ""$1""}'`
    chmod o+w refs/heads
    chmod g+w refs/heads
    prev_permissions_tags=`\ls refs/tags -dl | awk '{print ""$1""}'`
    chmod o+w refs/tags
    chmod g+w refs/tags
    chown ${me}:users -R refs/remotes

    if [[ "${remote_present}" == "false" ]]; then
        # Add remote
        #${sudo/USER/${local_user}} ${git} remote add --mirror ${remote_name} ssh://${ssh_server}${remote_location}/${local_user}/${local_repo} \
        ${sudo/USER/${local_user}} ${git} remote add --mirror=push ${remote_name} ssh://${ssh_server}${remote_location}/${local_user}/${local_repo} \
                                                                            2>&1 | tee -a ${logfile}
    else
        # Make sure the url of the remote is set correctly
        ${sudo/USER/${local_user}} ${git} remote set-url        ${remote_name} ssh://${ssh_server}${remote_location}/${local_user}/${local_repo} \
                                                                                2>&1 | tee -a ${logfile}
    fi
    ${sudo/USER/${local_user}} ${git} remote set-url --push ${remote_name} ssh://${ssh_server}${remote_location}/${local_user}/${local_repo} \
                                                                            2>&1 | tee -a ${logfile}
    cd - > /dev/null
}

list_local_branches()
{
    ${git} branch | grep -v master | sed "s|\* ||g"
}

push_branch()
{
    branch="${1}"
    remote="${2}"
    cmd1="${git} push ${remote} ${branch}:refs/heads/${branch}"
    cmd2="${git} config branch.${branch}.remote ${remote}"
    cmd3="${git} config branch.${branch}.merge refs/heads/${branch}"
    echo $cmd1                                                                  2>&1 | tee -a ${logfile}
    $cmd1                                                                       2>&1 | tee -a ${logfile}
    echo $cmd1                                                                  2>&1 | tee -a ${logfile}
    $cmd2                                                                       2>&1 | tee -a ${logfile}
    echo $cmd3                                                                  2>&1 | tee -a ${logfile}
    $cmd3                                                                       2>&1 | tee -a ${logfile}
}

push_to_backup_server()
{
    if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
        echo "Usage: push_to_backup_server <local_user> <local_repo> <ssh_server>"
        return
    fi
    local_user="$1"
    local_repo="$2"
    ssh_server="$3"

    log "${s}${s}${s}Pushing ${local_user}'s ${local_repo} to push to ${ssh_server}..." \
                                                                                2>&1 | tee -a ${logfile}

    cd ${repos_path}/${local_user}/${local_repo}
    cmd="${sudo/USER/${me}} ${git} push backup_${ssh_server}"
    #echo "${s}${s}${s}$cmd"                                                     2>&1 | tee -a ${logfile}
    $cmd                                                                        2>&1 | tee -a ${logfile}

    # No need to push branches. Setting up a mirror in setup_repo_for_pushing() is enough
    #branches=(`list_local_branches`)
    #log "Pushing branches: ${branches[*]}"                                      2>&1 | tee -a ${logfile}
    #for branch in ${branches[*]}; do
    #    push_branch ${branch} backup_${ssh_server}
    #done

    # Restore permission on "refs/heads" folder
    if [[ "${prev_permissions_heads:5:1}" == "-" ]]; then
        chmod g-w refs/heads
    else
        chmod g+w refs/heads
    fi
    if [[ "${prev_permissions_heads:8:1}" == "-" ]]; then
        chmod o-w refs/heads
    else
        chmod o+w refs/heads
    fi

    # Restore permission on "refs/tags" folder
    if [[ "${prev_permissions_tags:5:1}" == "-" ]]; then
        chmod g-w refs/heads
    else
        chmod g+w refs/heads
    fi
    if [[ "${prev_permissions_tags:8:1}" == "-" ]]; then
        chmod o-w refs/heads
    else
        chmod o+w refs/heads
    fi

    cd - > /dev/null
}

fix_permissions()
{
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: fix_permissions <local_user> <local_repo>"
        return
    fi
    local_user="$1"
    local_repo="$2"

    if [[ "$UID" != "0" ]]; then
        log "fix_permissions() will probably work better if run as root!"
        exit
    fi

    # http://stackoverflow.com/questions/4832346/how-to-use-group-file-permissions-correctly-on-a-git-repository
    pushd ${repos_path}/${local_user}/${local_repo} > /dev/null
    # Make the repository shared
    cmd="${git} config core.sharedRepository group"
    $cmd                                                                        2>&1 | tee -a ${logfile}
    # Fix the sticky bit
    cmd="find . -type d -execdir chmod g+s {} ;"
    $cmd                                                                        2>&1 | tee -a ${logfile}
    # Change ownership
    cmd="chgrp -R ${group} *"
    # Repair permissions
    cmd="chmod -R g+r *"
    $cmd                                                                        2>&1 | tee -a ${logfile}
    popd > /dev/null
}

repack_and_gc()
{
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: repack_and_gc <local_user> <local_repo>"
        return
    fi
    local_user="$1"
    local_repo="$2"

    cd ${repos_path}/${local_user}/${local_repo}
    cmd="${sudo/USER/${me}} ${git} repack -afd --window-memory=100M"
    $cmd                                                                        2>&1 | tee -a ${logfile}
    cmd="${sudo/USER/${me}} ${git} gc"
    $cmd                                                                        2>&1 | tee -a ${logfile}
    cd -
}

backup_repo()
{
    if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
        echo "Usage: backup_repo <local_user> <local_repo> <ssh_server> <remote_location>"
        return
    fi
    local_user="$1"
    local_repo="$2"
    ssh_server="$3"
    remote_location="$4"

    #repack_and_gc          ${local_user} ${local_repo}
    create_remote_repo     ${local_user} ${local_repo} ${ssh_server} ${remote_location}
    setup_repo_for_pushing ${local_user} ${local_repo} ${ssh_server} ${remote_location}
    push_to_backup_server  ${local_user} ${local_repo} ${ssh_server}
}

loop_over_all_repos()
{
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: loop_over_all_repos <action string> <command>"
        return
    fi
    local action_string="$1"
    local cmd="$2"

    local users=`list_users`
    for user in ${users[@]}; do
        echo "${stars}"                                                         2>&1 | tee -a ${logfile}
        log "${action_string} ${user}'s repos..."                               2>&1 | tee -a ${logfile}

        unset repos
        local repos=`list_user_repos ${user}`
        for repo in ${repos[@]}; do
            log "${s}${s}${action_string} ${user}'s ${repo}..." \
                                                                                2>&1 | tee -a ${logfile}
            eval `echo "$cmd"`
            sleep 1
        done

        log "Done packing ${user}'s repos..."                                   2>&1 | tee -a ${logfile}

    done
}

loop_over_all_repos_and_remotes()
{
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: loop_over_all_repos <action string> <command>"
        return
    fi
    local action_string="$1"
    local cmd="$2"

    local users=`list_users`
    for user in ${users[@]}; do
        echo "${stars}"                                                         2>&1 | tee -a ${logfile}
        log "${action_string} ${user}'s repos..."                               2>&1 | tee -a ${logfile}

        unset repos
        local repos=`list_user_repos ${user}`
        for (( i=0; i<${#backup_servers[@]}; i=i+2 )); do
            log  "${s}${action_string} ${user}'s repos to ${backup_servers[${i}]}..."    2>&1 | tee -a ${logfile}
            for repo in ${repos[@]}; do
                log "${s}${s}${action_string} ${user}'s ${repo}..." \
                                                                                    2>&1 | tee -a ${logfile}
                eval `echo "$cmd"`
                sleep 1
            done
        done

        log "Done packing ${user}'s repos..."                                   2>&1 | tee -a ${logfile}

    done
}

send_log_to_servers()
{
    log "Sending logs..."
    for (( i=0; i<${#backup_servers[@]}; i=i+2 )); do
        #ssh -F /home/${me}/.ssh/config ${backup_servers[${i}]} "mkdir -p ${backup_servers[$((${i}+1))]}/logs/"
        #scp ${logfile} ${backup_servers[${i}]}:${backup_servers[$((${i}+1))]}/logs/`basename ${logfile}`
        ${sudo/USER/${me}} ssh ${backup_servers[${i}]} "mkdir -p ${backup_servers[$((${i}+1))]}/logs/"
        ${sudo/USER/${me}} scp ${logfile} ${backup_servers[${i}]}:${backup_servers[$((${i}+1))]}/logs/`basename ${logfile}`
    done
}