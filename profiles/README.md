# Profiles

Named therapy profiles for Loop. A profile is a name plus the four scheduled therapy settings: correction range, carb ratios, basal rates and insulin sensitivities. Overrides, pre-meal and workout ranges are not part of a profile. You can switch profiles by hand, on a weekly schedule, or from a caregiver's phone with LoopFollow.

This customization works the same way as the profiles pull request to Loop (LoopKit/LoopWorkspace#583): profiles are stored in Loop's own settings, and the Nightscout profile document and the remote commands have the same format. If that pull request is merged, Loop reads the profiles this customization stored.

This is not medical advice. Switching a profile changes the settings Loop doses with. Agree on your profiles, and when to use them, with your care team.

## What it does

- Settings → Profiles lists the profiles. Default always exists. The active profile has a checkmark, and the status screen shows it once you have more than one profile.
- Use + to create a profile from the active profile's settings. Tap a profile to review it, edit its settings with the usual Therapy Settings editors, activate, rename or delete it. Press and hold to reorder.
- Editing Therapy Settings edits the active profile, and the editors say which profile that is.
- A switch first checks the profile against the guardrails and the pump's supported basal rates, then writes the basal schedule to the pump, and only then changes the settings. If any step fails, nothing changes. A switch is refused while insulin delivery is suspended.
- A profile can stop fitting after a change elsewhere, for example a lower maximum basal rate, a higher glucose safety limit or a pump with other basal rates. Values are never adjusted to fit. The Profiles screen marks such a profile "Cannot be activated" and gives the reason, and it cannot be activated, by hand, on a schedule or remotely, until its settings are edited. Each of its settings can be fixed on its own: a save checks only the settings that changed. The Delivery Limits and Glucose Safety Limit editors name the profiles a change would affect before saving, and after a pump change Loop alerts you to the profiles that do not fit the new pump. A scheduled switch to such a profile does not run and alerts you.
- Scheduled switches make a profile active at a time each week, for example Weekend on Saturday 07:00 and Default on Monday 06:00. A profile stays active until the next start. A scheduled switch waits for a running bolus, tries again while delivery is suspended, alerts you if it has not run 30 minutes after its time, and tells you when it has switched. Each start can be paused.
- Nightscout gets every profile in one profile document, with the active profile as `defaultProfile`, and each switch as a Profile Switch treatment.
- Caregivers using LoopFollow can switch, create, edit, rename and delete profiles and change the scheduled starts. Every remote command needs the one-time password (OTP) and an expiration. A save or delete carries a fingerprint of the profile the caregiver saw, so a change made on the phone in the meantime is not overwritten. The active profile and Default can never be deleted remotely. Loop shows a notification for every remote change.
- LoopFollow releases without profile editing, such as 8.0.0, can still switch profiles. As with the earlier customization, they do not offer a profile named Default.
- When you set up Loop again and import settings from Nightscout, every profile and the scheduled starts are offered for import, including from a document Trio wrote.

## Moving from the earlier Profiles customization

The earlier version saved profiles as files on the phone. The first time the new version runs, it moves those profiles into Loop's settings, and once settings that hold them are saved, it deletes the files. Nothing needs to be done by hand. Loop keeps at most 20 profiles, Default included; profiles beyond that are not moved, and Loop names them in an alert.

- Names that the new rules do not allow are adjusted: spaces at the start or end are removed, a `.` becomes `,`, a leading `$` is removed, and a profile named Default becomes "Saved Default". If two names end up the same, a number is added.
- The profile that was loaded last stays active only when its values equal the settings Loop doses with. Otherwise Default, holding the current settings, is active. No settings Loop doses with are changed by the move.
- Check the Profiles screen after the update.

If you remove this customization again, Loop keeps dosing with the settings of the profile that was active. The other profiles stay in the stored settings, but Loop without the customization does not show them, and the old files are gone.

## Patches

| file | LoopWorkspace branch |
|---|---|
| `dev_profiles.patch` | `dev` and `main` (3.14.x) |
| `nextdev_profiles.patch` | `next-dev` |
| `main380_*`, `main382_*` | older main releases, file-based profiles without remote commands |

Both patches touch Loop, LoopKit, LoopOnboarding, NightscoutService and TidepoolService. Apply from the LoopWorkspace folder:

```
git apply --whitespace=nowarn dev_profiles.patch
```

The earlier patches are in `archive/dev_profiles_20261120.patch` and `archive/nextdev_profiles_20261120.patch`, so the selector reports an update for workspaces that have them applied.

## Notes for maintainers

The patches are built from the pull request branches and arranged so they apply cleanly next to every other customization, in any order:

- The NightscoutKit changes of the pull request are not used: the workspace pins NightscoutKit through Swift Package Manager, so the profile document fields, the Profile Switch treatment and the import of a document without Loop's settings are written and read as JSON in `NightscoutService+TherapyProfiles.swift`.
- The remote profile commands are handled apart from the shared remote command code (`Action`, `RemoteNotification`, `RemoteNotificationResponseManager`, `RemoteActionDelegate`), which remote_carb_edit and remote_window change. `RemoteDataServicesManager` hands a profile command to `TherapyProfileRemoteCommandReceiver` before the shared path. The steps are the same: duplicates skipped, then expiration and OTP, then the action, the return push (with `command_type` `profile_switch`, `profile_save`, `profile_delete` or `profile_scheduled_switches_save` and a `result` code) and a Nightscout note on failure. remote_window's longer acceptance window does not apply to profile commands; they keep the expiration LoopFollow sends.
- The accepted commands are listed in the profile document's `remoteCommands`, as in the pull request, once Loop can receive remote notifications and has a pump and a maximum basal rate.
- `profile-switch` is also added to `loop.testingDetails.remoteCommands` of every uploaded device status, keeping commands other customizations list there. LoopFollow versions without profile editing look for it there; newer LoopFollow uses the profile document.
- Strings are English only and the tests of the pull request are not included.
- On `dev`, LoopDataManager holds the settings, so the profile code keeps the active profile in step with the live schedules before each read and change. SettingsView gets a Profiles row next to Therapy Settings that opens the profiles in the settings navigation, because basal_lock changes the settings sheets.

Checked on 2026-11-23: each patch applies before and after every other customization for its branch and reverses cleanly, and with all of them together (remote_carb_edit and remote_window, high_carb_limit and low_carb_limit, and meal_days and meal_week, do not apply together with each other, with or without this one; `nextdev_remote_window.patch` does not apply to the current next-dev on its own). Both branches build. Remote switching works from LoopFollow 8.0.0 and from LoopFollow dev with profile editing.
