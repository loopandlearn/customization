# Profiles

Save the current therapy settings (correction range, carb ratios, basal rates and insulin sensitivities) as named profiles under Settings → Profiles, and load one later.

Loading a profile writes its basal schedule to the pump and then saves all four settings in one change, so stored and uploaded settings never mix two profiles.

## Editing saved profiles

Tap a profile to see its settings, then tap a setting to edit it with the same editors as Therapy Settings: the same guardrail warnings, confirmations and authentication. Edits change only the saved profile. Loop keeps dosing with its current settings and nothing is sent to the pump until the profile is loaded. When the edited profile is the active one, Loop offers to load it right away.

## Remote profile switch

A caregiver app (LoopFollow) can switch Loop to one of the saved profiles, through the same OTP-protected APNS remote command path as remote carbs and boluses.

Switching a profile changes the correction range, carb ratios, basal rates and insulin sensitivities Loop doses with. It runs the same steps as loading the profile on the phone: Loop checks the profile against the guardrails and the pump's supported basal rates, writes the basal schedule to the pump, and only then saves the new settings. If any step fails, nothing changes and the caregiver is told why. This is not medical advice; agree on the saved profiles and when to use them with your care team.

## What Loop uploads

- Every saved profile is added to the Nightscout profile document's `store`, keyed by its name, in the same format as the active profile. `Default` and the active profile's name still hold the live settings, and `defaultProfile` names the active profile. A saved profile named `Default`, or with a name starting with `$`, is not uploaded and cannot be switched to remotely.
- Saving, renaming or deleting a profile on the phone uploads the profile document again, so followers see the change.
- Every devicestatus upload lists `profile-switch` in `loop.testingDetails.remoteCommands`. LoopFollow shows the Profiles button only when it is there.

## The command

Payload keys, in addition to the usual `otp`, `sent-at`, `remote-address` and `entered-by`:

- `profile-switch`: the profile's name as it appears in the `store`.
- `profile-switch-fingerprint`: a fingerprint of the profile values the caregiver previewed.
- `expiration` is required; a command without it is rejected.

The fingerprint is the first 16 hex characters of the SHA-256 of `basal=<seconds>:<value>,...;carbratio=...;sens=...;target_low=...;target_high=...`, built from the `store` entry with each value formatted to three decimals. Loop computes it from the saved profile it is about to activate, in mg/dL and mmol/L, and rejects the command when neither matches, for example when the profile was edited on the phone after the caregiver loaded the preview. The caregiver and the phone both get a notice, and the caregiver can review the profile again once Loop has uploaded it.

Loop answers through the existing return push (`encrypted_return_notification`) with `command_type` `profile_switch` and `command_status` `success` or `failed`. The alert body names the profile (`Profile '<name>' activated`, or `Profile '<name>' not activated: <reason>`, for example a pump communication error), which is how LoopFollow matches the reply to the command. Failures also post the usual Nightscout Note, and Loop shows a local notification for both outcomes.

## Patches

Touches Loop, LoopKit, LoopOnboarding and NightscoutService. `dev_profiles.patch` is for LoopWorkspace `dev` and `main` (3.14.11), `nextdev_profiles.patch` for `next-dev`. `main380_*` and `main382_*` are for older main releases and do not include remote switching. Apply from the LoopWorkspace folder:

```
git apply --whitespace=nowarn dev_profiles.patch
```

On `dev`, `dev_profiles_basal_lock*.patch` apply on top of basal_lock; on `next-dev` the two coexist without a variant. Profiles coexists with negative_insulin. The profiles patches without remote switching are in `archive/*_noremote.patch`, so the selector reports an update for workspaces that have them applied.

## Combining with remote_carb_edit and remote_window

Both also change the remote command code, so each has variants for the others already being in the tree:

- `<branch>_profiles[_basal_lock]_remote_carb_edit.patch`, `..._remote_window.patch` and `..._remote_carb_edit_remote_window.patch`: profiles on top of the named customizations.
- `remote_carb_edit/<branch>_remote_carb_edit_profiles.patch` and `..._profiles_remote_window.patch`: remote_carb_edit on top of profiles (and remote_window).
- `remote_window/<branch>_remote_window_profiles.patch` and `..._profiles_remote_carb_edit.patch`: remote_window on top of profiles (and remote_carb_edit).

Every order produces the same tree, and each customization can be removed on its own. With remote_carb_edit, `remoteCommands` lists all three commands. With remote_window, `sent-at` is required, and on `dev` profile switches also appear in the remote command history.
