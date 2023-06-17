#!/bin/bash
#set -x
set -e

branch="main"
local_patch_path="/Users/marion/dev/git_local/Code/patchrepo"

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
  git branch --format='%(refname:short)' | grep -v 'HEAD detached at' | grep -v "dev"  | xargs -r git branch -D
  cd ..
}

# Reset the LoopWorkspace repository
function reset_workspace() {
    local branch=$1
    git clean -fd
    git fetch origin
    git reset --hard origin/$branch
    git submodule update --init --recursive --force

    # Clean up the repositories
    git_cleanup_submodule Loop
    git_cleanup_submodule LoopKit
}


create_patch() {
    local patch_name="$1"
    git diff --submodule=diff | sed 's/[[:space:]]*$//' > "$patch_name"
}

apply_patch() {
    local patch_name="$1"
    git apply --whitespace=nowarn "${patch_name}"
}

reverse_patch() {
    local patch_name="$1"
    git apply --whitespace=nowarn "${patch_name}" --reverse
}

commit() {
    if [[ $# -eq 0 ]]; then
        # No arguments, commit in the current directory
        git add .
        git commit -m "commit"
    else
        # There are arguments, treat each one as a submodule
        for submodule in "$@"
        do
            cd "$submodule"
            git add .
            git switch -c tmp
            git commit -m "commit"
            cd ..
        done
    fi
}


#############################
echo "1988 based on 2008 = combined_1988_2008"
# current state is 2008, create patch to add 1988
#############################
reset_workspace ${branch}
apply_patch $patch_2008

# commit this so we can reverse patch
commit Loop

# now reverse that same patch
reverse_patch $patch_2008

# add in new patch
apply_patch $combined_1988_2008

# create the patch
cd Loop; git add .; cd ..
create_patch "$local_patch_path/1988/${branch}_1988_2008.patch"


#############################
echo "2008 based on 1988 -> combined_1988_2008"
# current state is 1988, create patch to add 2008
#############################
reset_workspace ${branch}
apply_patch $patch_1988

# commit this so we can reverse patch
commit Loop

# now reverse that same patch
reverse_patch $patch_1988

# add in new patch
apply_patch $combined_1988_2008

# create the patch
cd Loop; git add .; cd ..
create_patch "$local_patch_path/2008/${branch}_2008_1988.patch"


#############################
echo "1988 over original cto"
# current state is original cto, create patch to add 1988
#    with cto_no_switcher
#############################
reset_workspace ${branch}
#Set workspace cto original
apply_patch $cto_original
commit Loop LoopKit

#Remove original cto
git apply --reverse $cto_original

# add in 1988 and cto_no_switcher
apply_patch $patch_1988
apply_patch $cto_no_switcher

# create the patch
cd Loop; git add .; cd ..
cd LoopKit; git add .; cd ..
create_patch "$local_patch_path/1988/${branch}_1988_cto.patch"

#############################
echo "1988 over original cto + 2008"
# current state is original cto + 2008, 
#    create patch to add 1988 with cto_no_switcher
#############################
reset_workspace ${branch}

#Set workspace cto original with 2008
apply_patch $cto_original
apply_patch $patch_2008
commit Loop LoopKit

#Remove original cto and 2008
git apply --reverse $cto_original
git apply --reverse $patch_2008

# add 1988 and 2008 and cto_no_switcher
apply_patch $combined_1988_2008
apply_patch $cto_no_switcher

# create the patch
cd Loop; git add .; cd ..
cd LoopKit; git add .; cd ..
create_patch "$local_patch_path/1988/${branch}_1988_2008_cto.patch"