#!/bin/bash
#set -x
set -e

path_marion="/Users/marion/dev/git_local/Code/customization"
path_jonas="../.."

branch="dev"
# this requires that Loop already have remotes configures
# first arg goes with dosing-strategy-linear-ramp branch (i.e., marionbarker)
# second arg goes with prep_irc and combined_1988_2008 (i.e., loopandlearn)
repo1="marionbarker"
repo2="loopandlearn"

function git_cleanup_submodule() {
  local submodule_path=$1

  echo "Cleaning up $submodule_path..."
  cd $submodule_path
  # Delete branches, but preserve any branch named 'dev'
  git branch --format='%(refname:short)' | grep -v 'HEAD detached at' | grep -v "dev" | xargs -r git branch -D
  cd ..
}

function git_reset() {
    # Reset the main repository
    git clean -fd
    git fetch origin
    git reset --hard origin/$branch
    git submodule update --init --recursive --force

    # Clean up the repositories
    git_cleanup_submodule Loop
    git_cleanup_submodule LoopKit

    # Fetch the branches
    cd Loop
    git fetch $repo1
    git fetch $repo2
    cd ..
}

# marion starts in LoopWorkspace
thisFolder=$(pwd)
if [[ thisFolder -ne "LoopWorkspace" ]]; then
    cd Loop_dev/LoopWorkspace
    path_to_use="$path_jonas"
else
    path_to_use="$path_marion"
fi
git_reset

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
            git commit -m "commit"
            cd ..
        done
    fi
}

stage_workspace() {
    local current_dir=$(pwd)

    cd ..
    commit
    cd "$current_dir"
}

create_submodule_branch() {
    local submodule="$1"
    local branch_name="$2"
    
    cd "$submodule"
    git checkout -b "$branch_name" $(git -C .. ls-tree HEAD "${PWD##*/}" | awk '{print $3}')
    cd ..
}

create_patch() {
    local patch_path="$1"
    git diff --submodule=diff > "$patch_path"
}

apply_diff() {
    local remote_branch="$1"
    local repo="$2"
    local submodule="$3"

    if [[ -n "$submodule" ]]; then
        cd "$submodule"
    fi

    git diff origin/dev.."$repo/$remote_branch" | git apply --whitespace=nowarn -
    commit

    if [[ -n "$submodule" ]]; then
        cd ..
    fi
}

reverse_diff() {
    local remote_branch="$1"
    local repo="$2"
    local submodule="$3"

    if [[ -n "$submodule" ]]; then
        cd "$submodule"
    fi

    git diff origin/dev.."$repo/$remote_branch" | git apply --reverse --whitespace=nowarn -
    commit

    if [[ -n "$submodule" ]]; then
        cd ..
    fi
}


#############################
echo "1988"
#############################
create_submodule_branch Loop branch_1988
apply_diff "dosing-strategy-linear-ramp" "$repo1" Loop
create_patch "$path_to_use/1988/${branch}_1988.patch"


#############################
echo "2008"
#############################
create_submodule_branch Loop branch_2008
apply_diff "prep_irc" "$repo2" Loop
create_patch "$path_to_use/2008/${branch}_2008.patch"


#############################
echo "1988 based on 2008 = combined_1988_2008"
# current state is 2008, remove 2008 and apply combined
#############################
cd Loop
git checkout -b "branch_1988_2008" branch_2008
stage_workspace
reverse_diff "prep_irc" "$repo2"
apply_diff "combined_1988_2008" "$repo2"
cd ..
create_patch "$path_to_use/1988/${branch}_1988_2008.patch"


#############################
echo "2008 based on 1988 -> combined_1988_2008"
# current state is 1988, remove 1988 and apply combined
#############################
cd Loop
git checkout -b "branch_2008_1988" branch_1988
stage_workspace
reverse_diff "dosing-strategy-linear-ramp" "$repo1"
apply_diff "combined_1988_2008" "$repo2"
cd ..
create_patch "$path_to_use/2008/${branch}_2008_1988.patch"


#############################
echo "1988 over original cto"
#############################
git_reset

#Set workspace cto original
git apply "$path_to_use/customtypeone_looppatches/cto_original.patch"
commit Loop LoopKit
commit

#Remove original cto
git apply --reverse "$path_to_use/customtypeone_looppatches/cto_original.patch"
commit Loop LoopKit

# Apply 1988 changes
apply_diff "dosing-strategy-linear-ramp" "$repo1" Loop

#Add cto no switcher
git apply "$path_to_use/customtypeone_looppatches/cto_no_switcher.patch"
commit Loop LoopKit

# Do a workspace level patch
create_patch "$path_to_use/1988/${branch}_1988_cto.patch"


#############################
echo "1988 over original cto + 2008"
#############################
git_reset

# Stage workspace as 2008 + cto
apply_diff "prep_irc" "$repo2" Loop
git apply "$path_to_use/customtypeone_looppatches/cto_original.patch"
commit Loop LoopKit
commit

# Remove 2008 + cto
reverse_diff "prep_irc" "$repo2" Loop
git apply --reverse "$path_to_use/customtypeone_looppatches/cto_original.patch"
commit Loop LoopKit

# Apply combined_1988_2008 + cto no switch
apply_diff "combined_1988_2008" "$repo2" Loop
git apply "$path_to_use/customtypeone_looppatches/cto_no_switcher.patch"
commit Loop LoopKit

# Do a workspace level patch
create_patch "$path_to_use/1988/${branch}_1988_2008_cto.patch"
