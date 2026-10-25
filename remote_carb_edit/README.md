# Remote carb delete and edit

Lets a caregiver app (LoopFollow) delete or edit a carb entry that Loop created within the last 24 hours, through the same OTP-protected APNS remote command path as remote carbs.

Payload keys:

- Delete: `carbs-delete` carrying the entry's `syncIdentifier` (Loop uploads it on every Carb Correction treatment).
- Edit: `carbs-edit` carrying the `syncIdentifier`, plus the required replacement values `carbs-edit-entry` (g), `carbs-edit-absorption-time` (hours) and `carbs-edit-start-time` (ISO 8601). `carbs-edit-food-type` is optional and keeps the existing food type when absent. An edit missing any required value is rejected before validation.
- Both: `otp`, `sent-at` and `expiration` are required, in addition to the usual `remote-address` and `entered-by`.

Edits keep the entry's `syncIdentifier`. Replacement values are validated with the same limits as remote carb entries (absorption time range, maximum carb amount, start time window).

Loop acknowledges each command through the existing return push (`encrypted_return_notification`): `command_status` `success` / `failed`, `command_type` `carbs_delete` / `carbs_edit`, and `sync_identifier` identifying the entry. Failures also post the usual Nightscout Note with the error text. Loop shows a local notification for both outcomes using the remote carbs notification categories.

## Capability signal

Every devicestatus upload carries `loop.testingDetails.remoteCommands`, a list of the remote command keys this build accepts (`["carbs-delete", "carbs-edit"]`). It is refreshed every loop cycle, so a follower sees it within minutes of the patched build going live. LoopFollow hides the delete and edit actions when the field is absent, which keeps an unpatched Loop from receiving commands it would reject.

Touches Loop, LoopKit and NightscoutService. Generated against LoopWorkspace `dev` (3.14.8). Apply from the LoopWorkspace folder:

```
git apply --whitespace=nowarn dev_remote_carb_edit.patch
```

`nextdev_remote_carb_edit.patch` is the same customization for LoopWorkspace `next-dev`. The selector picks whichever patch applies.

## Combining with remote_window

- `dev_remote_carb_edit_remote_window.patch`: this customization applied on top of `remote_window/remote_window.patch` (main) or `remote_window/dev_remote_window.patch` (dev).
- `remote_window/remote_window_remote_carb_edit.patch`: remote_window applied on top of `dev_remote_carb_edit.patch` on main.
- `remote_window/dev_remote_window_remote_carb_edit.patch`: the same on dev.

For `next-dev`:

- `nextdev_remote_carb_edit_remote_window.patch`: this customization applied on top of `remote_window/nextdev_remote_window.patch`.
- `remote_window/nextdev_remote_window_remote_carb_edit.patch`: remote_window applied on top of `nextdev_remote_carb_edit.patch`.

Both orders produce the same tree. The selector script tries each folder's patches in sorted order and uses the first one that applies, so choosing both customizations picks the right file whichever is applied first. Applying by hand, use the plain patch for the first customization and the combined one for the second.

With remote_window, `sent-at` is required on every remote command (the notification is rejected without it). On `dev`, delete and edit commands also appear in the remote command history with the entry's `syncIdentifier`; the `next-dev` remote_window has no command history.

## Combining with remote_profile

`remote_profile` also adds a remote command, so the two have variants for each other, also together with remote_window:

- `<branch>_remote_carb_edit_remote_profile.patch` and `<branch>_remote_carb_edit_remote_profile_remote_window.patch`: this customization on top of remote_profile (and remote_window).
- `remote_profile/<branch>_remote_profile_remote_carb_edit.patch` and `..._remote_carb_edit_remote_window.patch`: the reverse.

With both applied, `remoteCommands` lists `carbs-delete`, `carbs-edit` and `profile-switch`. See `remote_profile/README.md`.
