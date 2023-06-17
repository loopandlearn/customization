#!/bin/bash
#set -x
set -e

branch=$1
echo "branch selected = ${branch}"

function git_cleanup_submodule() {
  local submodule_path=$1
  local branch=$2

  echo "Cleaning up $submodule_path..."
  cd $submodule_path
  # Delete branches, but preserve ${branch}
  git branch --format='%(refname:short)' | grep -v 'HEAD detached at' | grep -v "${branch}" | xargs -r git branch -D
  git clean -fd
  cd ..
}

# Reset the LoopWorkspace repository
git clean -fd
git fetch origin
git reset --hard origin/$branch
git submodule update --init --recursive --force

# Clean up the repositories
git_cleanup_submodule Loop $branch
git_cleanup_submodule LoopKit $branch

