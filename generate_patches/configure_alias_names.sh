#!/bin/bash

#   It MUST be run using source in order to configure alias
export local_patch_path="/Users/marion/dev/git_local/Code/customization"

alias reset_workspace="${local_patch_path}/generate_patches/reset_workspace.sh"
alias generate_main="${local_patch_path}/generate_patches/main.sh"
alias generate_dev="${local_patch_path}/generate_patches/dev.sh"

# method
#  start in directory with LoopWorkspace main branch
#  this command sets the workspace back to pristine main state:
#    reset_workspace main
#  this gets used a lot when initially configuring the components needed
#    Required components are listed at the beginning of main.sh

#  Once the required components are ready, issue this command to make the other patches
#    generate_main