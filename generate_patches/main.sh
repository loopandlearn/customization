#!/bin/bash
#set -x
set -e

branch="main"
local_patch_path="/Users/marion/dev/git_local/Code/patchrepo"
debug_flag="0"

# These are the required components to generate all the cases:
patch_1988="$local_patch_path/1988/${branch}_1988.patch"
patch_2008="$local_patch_path/2008/${branch}_2008.patch"
combined_1988_2008="$local_patch_path/generate_patches/components/${branch}_combined_1988_2008.patch"
cto_original="$local_patch_path/customtypeone_looppatches/cto_original.patch"
cto_no_switcher="$local_patch_path/customtypeone_looppatches/cto_no_switcher.patch"


# prior to running, go to LoopWorkspace folder for main
# make sure to source configure_alias_names so the sh script are run


# diff with respect to dev.sh
# cannot create patches automatically from the GitHub repositories
# but, can use exiting main patches to create the combinations required
# once each component is prepared
#   Components are:
#     1988/main_1988.patch
#     2008/main_2008.patch
#     generate_patches/main_components/main_combined_1988_2008.patch
#     customtypeone_looppatches/cto_original.patch
#     customtypeone_looppatches/cto_no_switcher.patch
#
# Final products are:
#   1988:
#     main_1988.patch
#     main_1988_2008.patch
#     main_1988_2008_cto.patch
#     main_1988_cto.patch
#   2008:
#     main_2008.patch
#     main_2008_1988.patch

# configure some stand alone sh scripts to use:
#   configure_alias_names
#   reset_workspace main

# must already be here: cd Loop_main/LoopWorkspace

function git_cleanup_submodule() {
    local submodule_path=$1

    echo "Cleaning up $submodule_path..."
    cd $submodule_path
    git clean -fd
    git branch --format='%(refname:short)' | grep -v 'HEAD detached at' | grep -v "${branch}"  | xargs -r git branch -D
    if [[ $debug_flag -eq "1" ]]; then
        echo " *** git_cleanup_submodule completed for $submodule_path"
        git status
    fi
    cd ..
}

# Restore the LoopWorkspace to original
function restore_workspace() {
    git checkout ${branch}
    git submodule update
    git clean -fd
    git fetch origin
    git reset --hard origin/$branch
    git submodule update --init --recursive --force
    git branch --format='%(refname:short)' | grep -v 'HEAD detached at' | grep -v "${branch}" | xargs -r git branch -D

    # Clean up the repositories
    git_cleanup_submodule Loop
    git_cleanup_submodule LoopKit
    if [[ "$debug_flag" -eq "1" ]]; then
        echo " *** restore_workspace completed"
        git status -v
    fi
}


create_patch() {
    local patch_name="$1"
    if [[ "$debug_flag" -eq "1" ]]; then
        echo " *** create_patch for $patch_name"
    fi
    git diff tmp1 tmp2 --submodule=diff | sed 's/[[:space:]]*$//' > "$patch_name"
}

apply_patch() {
    local patch_name="$1"
    git apply --whitespace=nowarn "${patch_name}"
}

reverse_patch() {
    local patch_name="$1"
    git apply --whitespace=nowarn "${patch_name}" --reverse
}

commit_tmp1() {
    if [[ $# -eq 0 ]]; then
        # No arguments, commit in the current directory
        git add .
        git switch -c tmp1
        git commit -m "commit"
    else
        # There are arguments, treat each one as a submodule
        for submodule in "$@"
        do
            cd "$submodule"
            git add .
            git switch -c tmp1
            git commit -m "commit"
            cd ..
        done
    fi
}

commit_tmp2() {
    if [[ $# -eq 0 ]]; then
        # No arguments, commit in the current directory
        git add .
        git switch -c tmp2
        git commit -m "commit"
    else
        # There are arguments, treat each one as a submodule
        for submodule in "$@"
        do
            cd "$submodule"
            git add .
            git switch -c tmp2
            git commit -m "commit"
            cd ..
        done
    fi
}

#############################
echo "1988 based on 2008 = combined_1988_2008"
# current state is 2008, create patch to add 1988
#############################
this_patch="$local_patch_path/1988/${branch}_1988_2008.patch"
restore_workspace
# configure initial state and commit
apply_patch "$patch_2008"
commit_tmp1 Loop
commit_tmp1
# reverse state
reverse_patch "$patch_2008"
# modify to desired configuration and commit
apply_patch "$combined_1988_2008"
commit_tmp2 Loop
commit_tmp2
# create the patch
create_patch "$this_patch"


#############################
echo "2008 based on 1988 -> combined_1988_2008"
# current state is 1988, create patch to add 2008
#############################
this_patch="$local_patch_path/2008/${branch}_2008_1988.patch"
restore_workspace 
# configure initial state and commit
apply_patch "$patch_1988"
commit_tmp1 Loop
commit_tmp1
# reverse state
reverse_patch "$patch_1988"
# modify to desired configuration and commit
apply_patch "$combined_1988_2008"
commit_tmp2 Loop
commit_tmp2
# create the patch
create_patch "$this_patch"


#############################
echo "1988 over original cto"
# current state is original cto, create patch to add 1988
#    with cto_no_switcher
#############################
this_patch="$local_patch_path/1988/${branch}_1988_cto.patch"
restore_workspace 
# configure initial state and commit
apply_patch "$cto_original"
commit_tmp1 Loop LoopKit
commit_tmp1
# reverse state
reverse_patch "$cto_original"
# modify to desired configuration and commit
apply_patch "$patch_1988"
apply_patch "$cto_no_switcher"
commit_tmp2 Loop
commit_tmp2
# create the patch
create_patch "$this_patch"

#############################
echo "1988 over original cto + 2008"
# current state is original cto + 2008, 
#    create patch to add 1988 with cto_no_switcher
#############################
this_patch="$local_patch_path/1988/${branch}_1988_2008_cto.patch"
restore_workspace 
# configure initial state and commit
apply_patch "$cto_original"
apply_patch "$patch_2008"
commit_tmp1 Loop LoopKit
commit_tmp1
# reverse state
reverse_patch "$patch_2008"
reverse_patch "$cto_original"
# modify to desired configuration and commit
apply_patch "$combined_1988_2008"
apply_patch "$cto_no_switcher"
commit_tmp2 Loop
commit_tmp2
# create the patch
create_patch "$this_patch"

########### restore before leaving #########
restore_workspace 
