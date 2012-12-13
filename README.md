repositories_backup
================================

Scripts to backup git and subversion repositories to remote sites.

Description
-------------------------

The script will go over all git repositories it finds and backup them (mirror).
It will list directories in $repos_path ("/git" by default, see git_repos.conf)
and will treat these entries as the different users. User directories can
then host as many different git repositories. For example:

    /git/user1/repo1.git
    /git/user2/repo1.git
    /git/user2/repo2.git
    /git/user3/project/repo1.git
    /git/user3/project/repo2.git
    /git/user3/repo3.git

etc.


Configuration
-------------------------

See git_repos.conf for the configuration. Settings are:

* repos_path: Main folder containing a folder per user, themselves
containing the users' git repositories.
* me: User admin. This account is used for any network transfer over ssh (scp, git push).
This user's ~/.ssh/config and keys will be honoured.
* group: Group owning the repositories' files and directories (used by git_fix_permissions.sh only)
* backup_servers: Flattened two dimensional array of remotes to push to. First element is
the address, the second is the directory on the server.
* logdir: Directory hosting logs created.
* git: git's executable.


Usage
-------------------------

Execute, as root, the different scripts.

To fix the permissions:

    # ./git_fix_permissions.sh

Note that the permissions are set for shared repositories!


To repack and garbage collect the repositories:

    # ./git_repack_and_gc.sh

Note that for big repositories, this can be slow.


To run the actual backup:

    # ./backup_git_repos.sh


License
-------------------------

This code is distributed under the terms of the GNU General Public License v3 (GPLv3) and is Copyright 2012 Nicolas Bigaouette.
