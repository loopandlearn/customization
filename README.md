# Customization

This repository provides patches to apply to LoopWorkspace for customizations.

## Repository for lnl-scripts

The scripts that assist in building and customizing Loop and related applications can be found in the `lnl-scripts` repository. These scripts simplify various tasks, including downloading, building, and applying custom patches to Loop and other DIY code. 
## Customization marker

Every active patch ends by creating an empty `<folder>.loopcustomization` file at the LoopWorkspace root, where `<folder>` is the customization's folder name in this repository. Loop records these identifiers in `BuildDetails.plist`, and they appear in the diagnostic report under Build Details. A patch carries only the marker for its own folder; combined variants such as `main382_basal_lock_profiles.patch` add `basal_lock.loopcustomization` only.

When generating a patch, include the marker in the diff:

```
touch <folder>.loopcustomization
git add -N <folder>.loopcustomization
git diff --submodule=diff > <folder>/<name>.patch
```

The marker always goes at the workspace root, even for a patch that only touches one submodule, and is never committed. Apply patches with `git apply`; `patch -p1` skips the empty marker file.
